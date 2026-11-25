import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import '../errors/api_exception.dart';

const Map<String, String> _jsonHeaders = {
  'content-type': 'application/json; charset=utf-8',
};

/// Risposta JSON standard.
Response jsonResponse(Object? body, {int status = 200}) =>
    Response(status, body: jsonEncode(body), headers: _jsonHeaders);

/// Risposta di errore: {"error": "messaggio"}.
Response jsonError(int status, String message) =>
    jsonResponse({'error': message}, status: status);

/// Intercetta le eccezioni dei controller e le converte in risposte JSON.
Middleware errorMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      try {
        return await inner(request);
      } on ApiException catch (e) {
        return jsonError(e.status, e.message);
      } on FormatException {
        return jsonError(400, 'JSON non valido');
      } catch (e, st) {
        // Si registra solo il tipo e lo stack, mai il corpo della richiesta
        // (potrebbe contenere password o dati personali dei candidati).
        stderr.writeln('Errore interno (${e.runtimeType}): $st');
        return jsonError(500, 'Errore interno del server');
      }
    };
  };
}
