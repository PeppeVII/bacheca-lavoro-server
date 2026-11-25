import 'package:shelf/shelf.dart';

import '../dao/company_dao.dart';
import '../models/company.dart';
import '../services/token_service.dart';
import 'error_middleware.dart';

const String _companyKey = 'bacheca.company';
const String _tokenKey = 'bacheca.token';

/// Azienda autenticata della richiesta (null se la richiesta è anonima).
Company? currentCompany(Request request) =>
    request.context[_companyKey] as Company?;

/// Token Bearer valido della richiesta (null se assente o non valido).
String? currentToken(Request request) => request.context[_tokenKey] as String?;

/// Legge l'header `Authorization: Bearer <token>` e, se il token è valido,
/// mette azienda e token nel context della richiesta.
Middleware authMiddleware(TokenService tokens, CompanyDao companies) {
  return (Handler inner) {
    return (Request request) {
      var req = request;
      final header = request.headers['authorization'];
      if (header != null && header.toLowerCase().startsWith('bearer ')) {
        final token = header.substring(7).trim();
        final companyId = tokens.companyIdFor(token);
        if (companyId != null) {
          final company = companies.findById(companyId);
          if (company != null) {
            req = request
                .change(context: {_companyKey: company, _tokenKey: token});
          }
        }
      }
      return inner(req);
    };
  };
}

/// Protegge un handler dell'area riservata: 401 se manca un token valido.
Handler guard(Handler handler) {
  return (Request request) {
    if (currentCompany(request) == null) {
      return jsonError(401, 'Autenticazione richiesta');
    }
    return handler(request);
  };
}
