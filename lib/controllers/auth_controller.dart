import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../dao/company_dao.dart';
import '../errors/api_exception.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/error_middleware.dart';
import '../services/password_service.dart';
import '../services/token_service.dart';
import '../utils/validators.dart';

/// Registrazione, login e logout delle aziende (R1, R2, R3).
class AuthController {
  final CompanyDao companies;
  final TokenService tokens;

  AuthController(this.companies, this.tokens);

  Router get router {
    final r = Router();
    r.post('/api/auth/register', _register);
    r.post('/api/auth/login', _login);
    r.post('/api/auth/logout', guard(_logout));
    r.get('/api/auth/me', guard(_me));
    return r;
  }

  /// R1: crea l'account. Non restituisce un token: come da scenario S1,
  /// dopo la registrazione l'azienda esegue il login.
  Future<Response> _register(Request req) async {
    final input = validateRegister(await readJsonObject(req));
    final salt = PasswordService.generateSalt();
    final company = await companies.create(
      name: input.name,
      email: input.email,
      passwordHash: PasswordService.hash(input.password, salt),
      salt: salt,
    );
    return jsonResponse(company.toPublicJson(), status: 201);
  }

  /// R2: login con email e password; restituisce token e dati dell'azienda.
  Future<Response> _login(Request req) async {
    final body = await readJsonObject(req);
    final email = body['email'];
    final password = body['password'];
    if (email is! String || password is! String) {
      throw ApiException(422, 'Email e password obbligatorie');
    }
    final company = companies.findByEmail(email);
    final ok = company != null &&
        PasswordService.verify(password, company.salt, company.passwordHash);
    // Stesso messaggio se l'email non esiste o la password è sbagliata
    if (!ok) throw ApiException(401, 'Credenziali non valide');
    final token = tokens.issue(company.id);
    return jsonResponse({'token': token, 'company': company.toPublicJson()});
  }

  /// R3: logout, il token viene invalidato sul server.
  Response _logout(Request req) {
    final token = currentToken(req);
    if (token != null) tokens.revoke(token);
    return Response(204);
  }

  /// Dati dell'azienda autenticata (usato dal client per ripristinare la sessione).
  Response _me(Request req) =>
      jsonResponse(currentCompany(req)!.toPublicJson());
}
