import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../dao/application_dao.dart';
import '../dao/job_dao.dart';
import '../errors/api_exception.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/error_middleware.dart';
import '../models/job.dart';
import '../services/cv_storage.dart';
import '../utils/validators.dart';

/// Area riservata dell'azienda (tutte le rotte richiedono il login):
/// pubblicazione annunci (R4) e consultazione candidature e CV (R7).
class CompanyController {
  final JobDao jobs;
  final ApplicationDao applications;
  final CvStorage cvStorage;

  CompanyController(this.jobs, this.applications, this.cvStorage);

  Router get router {
    final r = Router();
    r.get('/api/company/jobs', guard(_myJobs));
    r.post('/api/company/jobs', guard(_createJob));
    // Rotte con parametro: il guard avvolge l'handler che riceve anche l'id
    r.get(
      '/api/company/jobs/<id|[0-9]+>/applications',
      (Request req, String id) =>
          guard((inner) => _jobApplications(inner, id))(req),
    );
    r.get(
      '/api/company/applications/<id|[0-9]+>/cv',
      (Request req, String id) => guard((inner) => _downloadCv(inner, id))(req),
    );
    return r;
  }

  /// Annuncio dell'azienda autenticata: 404 se non esiste, 403 se è di un'altra azienda.
  Job _ownJob(Request req, int? jobId) {
    final job = jobId == null ? null : jobs.findById(jobId);
    if (job == null) throw ApiException(404, 'Annuncio non trovato');
    if (job.companyId != currentCompany(req)!.id) {
      throw ApiException(
          403, 'Questo annuncio non appartiene alla tua azienda');
    }
    return job;
  }

  /// Gli annunci pubblicati dall'azienda autenticata.
  Response _myJobs(Request req) {
    final company = currentCompany(req)!;
    return jsonResponse(
        jobs.byCompany(company.id).map((j) => j.toJson()).toList());
  }

  /// R4: pubblica un nuovo annuncio, che compare subito nella bacheca.
  Future<Response> _createJob(Request req) async {
    final company = currentCompany(req)!;
    final input = validateJob(await readJsonObject(req));
    final job = await jobs.create(
      companyId: company.id,
      companyName: company.name,
      title: input.title,
      description: input.description,
    );
    return jsonResponse(job.toJson(), status: 201);
  }

  /// R7: candidature ricevute per un proprio annuncio.
  Response _jobApplications(Request req, String id) {
    final job = _ownJob(req, int.tryParse(id));
    return jsonResponse(
        applications.byJob(job.id).map((a) => a.toPublicJson()).toList());
  }

  /// R7: scarica il PDF del curriculum di una candidatura ricevuta.
  Future<Response> _downloadCv(Request req, String id) async {
    final appId = int.tryParse(id);
    final application = appId == null ? null : applications.findById(appId);
    if (application == null) {
      throw ApiException(404, 'Candidatura non trovata');
    }
    // Controlla che l'annuncio della candidatura sia dell'azienda
    _ownJob(req, application.jobId);
    final bytes = await cvStorage.read(application.cvStoredName);
    if (bytes == null) {
      throw ApiException(404, 'File del curriculum non trovato');
    }
    return Response.ok(bytes, headers: {
      'content-type': 'application/pdf',
      'content-disposition': 'inline; filename="cv_${application.id}.pdf"',
    });
  }
}
