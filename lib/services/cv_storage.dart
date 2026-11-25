import 'dart:io';

/// Salva e legge i file dei CV nella cartella uploads/.
/// Il nome del file su disco lo decide il server (`cv_<istante>.pdf`):
/// il nome scelto dal candidato non viene mai usato come percorso.
class CvStorage {
  final String dir;

  CvStorage(this.dir);

  /// Crea la cartella se non esiste.
  Future<void> init() => Directory(dir).create(recursive: true);

  /// Scrive i byte del PDF e restituisce il nome con cui è stato salvato.
  Future<String> save(List<int> bytes) async {
    final storedName = 'cv_${DateTime.now().microsecondsSinceEpoch}.pdf';
    await File('$dir/$storedName').writeAsBytes(bytes, flush: true);
    return storedName;
  }

  /// Legge un CV salvato (null se il file non esiste).
  Future<List<int>?> read(String storedName) async {
    final file = File('$dir/$storedName');
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }
}
