import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../dao/application_dao.dart';
import '../dao/job_dao.dart';
import '../errors/api_exception.dart';
import '../middleware/error_middleware.dart';
import '../models/job.dart';
import '../services/cv_storage.dart';
import '../utils/validators.dart';

/// Parte pubblica, usata dai candidati senza login:
/// bacheca, dettaglio annuncio (R5) e invio candidatura (R6).
class JobController {
  final JobDao jobs;
  final ApplicationDao applications;
  final CvStorage cvStorage;

  JobController(this.jobs, this.applications, this.cvStorage);

  Router get router {
    final r = Router();
    r.get('/api/jobs', _list);
    r.get('/api/jobs/<id|[0-9]+>', _get);
    r.post('/api/jobs/<id|[0-9]+>/applications', _apply);
    return r;
  }

  /// Cerca l'annuncio o lancia 404.
  Job _findJob(String id) {
    final jobId = int.tryParse(id);
    final job = jobId == null ? null : jobs.findById(jobId);
    if (job == null) throw ApiException(404, 'Annuncio non trovato');
    return job;
  }

  Response _list(Request req) =>
      jsonResponse(jobs.all().map((j) => j.toJson()).toList());

  Response _get(Request req, String id) => jsonResponse(_findJob(id).toJson());

  Future<Response> _apply(Request req, String id) async {
    final job = _findJob(id);
    final input = validateApplication(await readJsonObject(req));

    // Prima si salva il file del CV, poi la candidatura che lo riferisce
    final storedName = await cvStorage.save(input.cvBytes);
    final application = await applications.create(
      jobId: job.id,
      firstName: input.firstName,
      lastName: input.lastName,
      email: input.email,
      cvFileName: input.cvFileName,
      cvStoredName: storedName,
    );
    return jsonResponse(application.toPublicJson(), status: 201);
  }
}
