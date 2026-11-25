/// Azienda registrata: è l'unico tipo di utente con un account.
class Company {
  final int id;
  final String name;
  final String email;
  final String passwordHash;
  final String salt;
  final String createdAt; // data ISO-8601 UTC

  const Company({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  factory Company.fromJson(Map<String, dynamic> j) => Company(
        id: j['id'] as int,
        name: j['name'] as String,
        email: j['email'] as String,
        passwordHash: j['passwordHash'] as String,
        salt: j['salt'] as String,
        createdAt: j['createdAt'] as String,
      );

  /// Serializzazione completa (solo per il salvataggio su file).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'salt': salt,
        'createdAt': createdAt,
      };

  /// Serializzazione pubblica inviata al client: senza passwordHash e salt.
  Map<String, dynamic> toPublicJson() => {
        'id': id,
        'name': name,
        'email': email,
        'createdAt': createdAt,
      };
}
