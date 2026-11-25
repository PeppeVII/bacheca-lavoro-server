/// Eccezione applicativa: il middleware degli errori la trasforma
/// nella risposta JSON {"error": message} con lo status indicato.
class ApiException implements Exception {
  final int status;
  final String message;

  ApiException(this.status, this.message);

  @override
  String toString() => 'ApiException($status): $message';
}
