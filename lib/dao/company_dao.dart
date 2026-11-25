import '../errors/api_exception.dart';
import '../models/company.dart';
import '../utils/validators.dart';
import 'json_store.dart';

/// Accesso ai dati delle aziende (file data/companies.json).
class CompanyDao {
  final JsonCollection _col;

  CompanyDao(this._col);

  Future<void> load() => _col.load();

  Company? findById(int id) {
    for (final m in _col.all()) {
      if (m['id'] == id) return Company.fromJson(m);
    }
    return null;
  }

  /// Ricerca per email senza distinguere maiuscole e minuscole.
  Company? findByEmail(String email) {
    final lower = email.trim().toLowerCase();
    for (final m in _col.all()) {
      if ((m['email'] as String).toLowerCase() == lower) {
        return Company.fromJson(m);
      }
    }
    return null;
  }

  /// Crea una nuova azienda. Il controllo dell'email duplicata e l'inserimento
  /// avvengono senza "await" in mezzo, quindi non si sovrappongono.
  Future<Company> create({
    required String name,
    required String email,
    required String passwordHash,
    required String salt,
  }) async {
    if (findByEmail(email) != null) {
      throw ApiException(409, 'Email già registrata');
    }
    final company = Company(
      id: _col.nextId(),
      name: name,
      email: email,
      passwordHash: passwordHash,
      salt: salt,
      createdAt: formatIsoUtc(DateTime.now()),
    );
    _col.add(company.toJson());
    await _col.save();
    return company;
  }
}
