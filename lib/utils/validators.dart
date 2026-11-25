import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../errors/api_exception.dart';

final RegExp _passwordRe = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,64}$');
final RegExp _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

/// Data ISO-8601 UTC senza frazioni di secondo, es. 2026-11-25T10:00:00Z.
String formatIsoUtc(DateTime d) {
  final u = d.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${u.year.toString().padLeft(4, '0')}-${two(u.month)}-${two(u.day)}'
      'T${two(u.hour)}:${two(u.minute)}:${two(u.second)}Z';
}

/// Legge il corpo della richiesta come oggetto JSON.
/// JSON non valido o non oggetto -> FormatException (risposta 400).
Future<Map<String, dynamic>> readJsonObject(Request request) async {
  final text = await request.readAsString();
  final decoded = jsonDecode(text);
  if (decoded is! Map) {
    throw const FormatException('Il corpo deve essere un oggetto JSON');
  }
  return Map<String, dynamic>.from(decoded);
}

/// Testo obbligatorio (dopo trim) con lunghezza tra min e max.
String requiredText(Map<String, dynamic> m, String key, String label, int max,
    {int min = 1}) {
  final v = m[key];
  if (v is! String) throw ApiException(422, '$label obbligatorio');
  final s = v.trim();
  if (s.isEmpty) throw ApiException(422, '$label obbligatorio');
  if (s.length < min) {
    throw ApiException(422, '$label troppo corto (minimo $min caratteri)');
  }
  if (s.length > max) {
    throw ApiException(422, '$label troppo lungo (massimo $max caratteri)');
  }
  return s;
}

/// Email obbligatoria e con formato valido.
String requiredEmail(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v is! String || !_emailRe.hasMatch(v.trim())) {
    throw ApiException(422, 'Email non valida');
  }
  return v.trim();
}

// ---------------------------------------------------------------- Auth

/// Dati di registrazione di un'azienda (record con campi nominati).
({String name, String email, String password}) validateRegister(
    Map<String, dynamic> b) {
  final name = requiredText(b, 'name', 'Nome azienda', 60, min: 2);
  final email = requiredEmail(b, 'email');
  final password = b['password'];
  if (password is! String || !_passwordRe.hasMatch(password)) {
    throw ApiException(422,
        'Password non valida: 8-64 caratteri con almeno una lettera e un numero');
  }
  return (name: name, email: email, password: password);
}

// ---------------------------------------------------------------- Annunci

({String title, String description}) validateJob(Map<String, dynamic> b) {
  final title = requiredText(b, 'title', 'Titolo', 80, min: 3);
  final description =
      requiredText(b, 'description', 'Descrizione', 3000, min: 10);
  return (title: title, description: description);
}

// ---------------------------------------------------------------- Candidature

/// Dati di una candidatura: generalità + CV (PDF inviato in base64).
({
  String firstName,
  String lastName,
  String email,
  String cvFileName,
  List<int> cvBytes,
}) validateApplication(Map<String, dynamic> b) {
  final firstName = requiredText(b, 'firstName', 'Nome', 50);
  final lastName = requiredText(b, 'lastName', 'Cognome', 50);
  final email = requiredEmail(b, 'email');

  // Nome del file scelto dal candidato (serve solo da mostrare)
  final cvFileName = requiredText(b, 'cvFileName', 'Curriculum', 120);

  // Contenuto del file, inviato come testo base64
  final raw = b['cvBase64'];
  if (raw is! String || raw.isEmpty) {
    throw ApiException(422, 'Curriculum obbligatorio');
  }
  List<int> bytes;
  try {
    bytes = base64Decode(raw);
  } on FormatException {
    throw ApiException(422, 'Curriculum non valido');
  }

  return (
    firstName: firstName,
    lastName: lastName,
    email: email,
    cvFileName: cvFileName,
    cvBytes: bytes,
  );
}
