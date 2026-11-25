import '../models/job_application.dart';
import '../utils/validators.dart';
import 'json_store.dart';

/// Accesso ai dati delle candidature (file data/applications.json).
class ApplicationDao {
  final JsonCollection _col;

  ApplicationDao(this._col);

  Future<void> load() => _col.load();

  /// Candidature di un annuncio, dalla più recente.
  List<JobApplication> byJob(int jobId) {
    final list = _col
        .all()
        .map(JobApplication.fromJson)
        .where((a) => a.jobId == jobId)
        .toList();
    list.sort((a, b) => b.id.compareTo(a.id));
    return list;
  }

  JobApplication? findById(int id) {
    for (final m in _col.all()) {
      if (m['id'] == id) return JobApplication.fromJson(m);
    }
    return null;
  }

  Future<JobApplication> create({
    required int jobId,
    required String firstName,
    required String lastName,
    required String email,
    required String cvFileName,
    required String cvStoredName,
  }) async {
    final application = JobApplication(
      id: _col.nextId(),
      jobId: jobId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      cvFileName: cvFileName,
      cvStoredName: cvStoredName,
      createdAt: formatIsoUtc(DateTime.now()),
    );
    _col.add(application.toJson());
    await _col.save();
    return application;
  }
}
