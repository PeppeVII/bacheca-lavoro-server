/// Candidatura inviata da un candidato (senza account) a un annuncio.
class JobApplication {
  final int id;
  final int jobId;
  final String firstName;
  final String lastName;
  final String email;
  final String cvFileName; // nome originale del file scelto dal candidato
  // nome del file salvato in uploads/ (generato dal server)
  final String cvStoredName;
  final String createdAt; // data ISO-8601 UTC

  const JobApplication({
    required this.id,
    required this.jobId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.cvFileName,
    required this.cvStoredName,
    required this.createdAt,
  });

  factory JobApplication.fromJson(Map<String, dynamic> j) => JobApplication(
        id: j['id'] as int,
        jobId: j['jobId'] as int,
        firstName: j['firstName'] as String,
        lastName: j['lastName'] as String,
        email: j['email'] as String,
        cvFileName: j['cvFileName'] as String,
        cvStoredName: j['cvStoredName'] as String,
        createdAt: j['createdAt'] as String,
      );

  /// Serializzazione completa (solo per il salvataggio su file).
  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'cvFileName': cvFileName,
        'cvStoredName': cvStoredName,
        'createdAt': createdAt,
      };

  /// Serializzazione inviata al client: il nome interno del file non serve,
  /// il CV si scarica con l'endpoint dedicato.
  Map<String, dynamic> toPublicJson() => {
        'id': id,
        'jobId': jobId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'cvFileName': cvFileName,
        'createdAt': createdAt,
      };
}
