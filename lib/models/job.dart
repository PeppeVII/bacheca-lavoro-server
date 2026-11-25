/// Annuncio di lavoro pubblicato da un'azienda.
class Job {
  final int id;
  final int companyId;
  final String companyName; // copia del nome, per mostrarlo nella bacheca
  final String title;
  final String description;
  final String createdAt; // data ISO-8601 UTC

  const Job({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  factory Job.fromJson(Map<String, dynamic> j) => Job(
        id: j['id'] as int,
        companyId: j['companyId'] as int,
        companyName: j['companyName'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        createdAt: j['createdAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyId': companyId,
        'companyName': companyName,
        'title': title,
        'description': description,
        'createdAt': createdAt,
      };
}
