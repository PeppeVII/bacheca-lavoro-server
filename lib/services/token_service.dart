import 'dart:convert';
import 'dart:math';

/// Token di sessione casuali tenuti in memoria: token -> id dell'azienda.
/// Se il server viene riavviato i token decadono e bisogna rifare il login.
class TokenService {
  final Map<String, int> _tokens = {};
  final Random _rng = Random.secure();

  String issue(int companyId) {
    final bytes = List<int>.generate(32, (_) => _rng.nextInt(256));
    final token = base64Url.encode(bytes).replaceAll('=', '');
    _tokens[token] = companyId;
    return token;
  }

  int? companyIdFor(String token) => _tokens[token];

  /// Usato dal logout: il token non sarà più accettato.
  void revoke(String token) => _tokens.remove(token);
}
