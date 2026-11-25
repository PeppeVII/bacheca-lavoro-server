import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Collezione generica salvata su file JSON (un array di oggetti con "id" intero).
/// - all'avvio il file viene letto e tenuto in memoria;
/// - ogni save() riscrive il file in modo atomico (file .tmp + rename);
/// - le scritture vengono messe in coda una dopo l'altra.
class JsonCollection {
  final String path;
  final List<Map<String, dynamic>> _items = [];
  int _lastId = 0;
  Future<void> _queue = Future<void>.value();

  JsonCollection(this.path);

  Future<void> load() async {
    final file = File(path);
    _items.clear();
    if (await file.exists()) {
      final text = await file.readAsString();
      if (text.trim().isNotEmpty) {
        final data = jsonDecode(text) as List<dynamic>;
        for (final e in data) {
          _items.add(Map<String, dynamic>.from(e as Map));
        }
      }
    }
    // L'ultimo id usato serve per generare i successivi
    _lastId = 0;
    for (final e in _items) {
      final id = e['id'] as int;
      if (id > _lastId) _lastId = id;
    }
  }

  List<Map<String, dynamic>> all() => List.unmodifiable(_items);

  /// Prossimo id autoincrementale.
  int nextId() => ++_lastId;

  void add(Map<String, dynamic> item) => _items.add(item);

  /// Salva lo stato corrente: la copia viene presa subito, la scrittura va in coda.
  Future<void> save() {
    final snapshot = const JsonEncoder.withIndent('  ').convert(_items);
    final op = _queue.then((_) => _write(snapshot));
    _queue = op.catchError((_) {});
    return op;
  }

  Future<void> _write(String content) async {
    final tmp = File('$path.tmp');
    await tmp.parent.create(recursive: true);
    await tmp.writeAsString(content, flush: true);
    await tmp.rename(path);
  }
}
