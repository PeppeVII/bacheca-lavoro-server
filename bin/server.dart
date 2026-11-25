import 'dart:io';

import 'package:bacheca_lavoro_server/controllers/auth_controller.dart';
import 'package:bacheca_lavoro_server/controllers/company_controller.dart';
import 'package:bacheca_lavoro_server/controllers/job_controller.dart';
import 'package:bacheca_lavoro_server/dao/application_dao.dart';
import 'package:bacheca_lavoro_server/dao/company_dao.dart';
import 'package:bacheca_lavoro_server/dao/job_dao.dart';
import 'package:bacheca_lavoro_server/dao/json_store.dart';
import 'package:bacheca_lavoro_server/middleware/auth_middleware.dart';
import 'package:bacheca_lavoro_server/middleware/error_middleware.dart';
import 'package:bacheca_lavoro_server/services/cv_storage.dart';
import 'package:bacheca_lavoro_server/services/token_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

Future<void> main() async {
  final dataDir = Platform.environment['DATA_DIR'] ?? 'data';
  final uploadsDir = Platform.environment['UPLOADS_DIR'] ?? 'uploads';
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  await Directory(dataDir).create(recursive: true);

  // DAO con persistenza su file JSON
  final companyDao = CompanyDao(JsonCollection('$dataDir/companies.json'));
  final jobDao = JobDao(JsonCollection('$dataDir/jobs.json'));
  final applicationDao =
      ApplicationDao(JsonCollection('$dataDir/applications.json'));
  await companyDao.load();
  await jobDao.load();
  await applicationDao.load();

  // I file dei CV vengono salvati nella cartella uploads/
  final cvStorage = CvStorage(uploadsDir);
  await cvStorage.init();

  final tokens = TokenService();

  final health = Router()
    ..get('/api/health', (Request req) => jsonResponse({'status': 'ok'}));

  // Cascade: prova i router uno dopo l'altro; se nessuno risponde -> 404.
  final api = Cascade()
      .add(health.call)
      .add(AuthController(companyDao, tokens).router.call)
      .add(JobController(jobDao, applicationDao, cvStorage).router.call)
      .add(CompanyController(jobDao, applicationDao, cvStorage).router.call)
      .add((Request req) => jsonError(404, 'Risorsa non trovata'))
      .handler;

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(errorMiddleware())
      .addMiddleware(authMiddleware(tokens, companyDao))
      .addHandler(api);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Bacheca Lavoro backend in ascolto sulla porta ${server.port}');
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        print(
            'Usa questo URL nell\'app: http://${addr.address}:${server.port}');
      }
    }
  } catch (_) {
    print('Impossibile leggere gli indirizzi di rete locali.');
  }
}
