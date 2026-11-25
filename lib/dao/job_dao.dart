import '../models/job.dart';
import '../utils/validators.dart';
import 'json_store.dart';

/// Accesso ai dati degli annunci (file data/jobs.json).
class JobDao {
  final JsonCollection _col;

  JobDao(this._col);

  Future<void> load() => _col.load();

  /// Ordina dal più recente al più vecchio (a parità di data, id più alto prima).
  List<Job> _newestFirst(Iterable<Job> jobs) {
    final list = jobs.toList();
    list.sort((a, b) {
      final c = b.createdAt.compareTo(a.createdAt);
      return c != 0 ? c : b.id.compareTo(a.id);
    });
    return list;
  }

  /// Tutti gli annunci: è la bacheca pubblica.
  List<Job> all() => _newestFirst(_col.all().map(Job.fromJson));

  /// Solo gli annunci di un'azienda (area riservata).
  List<Job> byCompany(int companyId) => _newestFirst(
      _col.all().map(Job.fromJson).where((j) => j.companyId == companyId));

  Job? findById(int id) {
    for (final m in _col.all()) {
      if (m['id'] == id) return Job.fromJson(m);
    }
    return null;
  }

  Future<Job> create({
    required int companyId,
    required String companyName,
    required String title,
    required String description,
  }) async {
    final job = Job(
      id: _col.nextId(),
      companyId: companyId,
      companyName: companyName,
      title: title,
      description: description,
      createdAt: formatIsoUtc(DateTime.now()),
    );
    _col.add(job.toJson());
    await _col.save();
    return job;
  }
}
