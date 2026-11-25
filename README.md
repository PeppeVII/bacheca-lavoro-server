# Bacheca Lavoro – Server (back-end)

Back-end REST dell'app **Bacheca Lavoro**, progetto del corso *Enterprise Mobile Application Development*
(Laurea Magistrale in Informatica, a.a. 2026-2027).

Le **aziende** si registrano, pubblicano annunci di lavoro e consultano le candidature ricevute.
I **candidati**, senza account, consultano la bacheca e si candidano inviando i propri dati e il curriculum (PDF).

Il client Flutter si trova nel repository **bacheca-lavoro-client**.

## Tecnologie

- **Dart** con [shelf](https://pub.dev/packages/shelf) e [shelf_router](https://pub.dev/packages/shelf_router)
- [crypto](https://pub.dev/packages/crypto) per l'hash delle password (SHA-256 con salt)
- Persistenza su **file JSON** (cartella `data/`) e sul disco per i CV (cartella `uploads/`)
- Nessun servizio esterno (niente Firebase, Supabase o simili)

## Struttura

```
bin/server.dart            avvio del server, middleware e registrazione dei controller
lib/
├── controllers/
│   ├── auth_controller.dart      registrazione, login, logout (R1, R2, R3)
│   ├── job_controller.dart       bacheca pubblica e invio candidature (R5, R6)
│   └── company_controller.dart   area riservata dell'azienda (R4, R7)
├── dao/                   accesso ai dati su file JSON (json_store, company, job, application)
├── models/                Company, Job, JobApplication
├── middleware/            gestione errori e autenticazione con token Bearer
├── services/              hash password, token di sessione, salvataggio dei CV
├── utils/validators.dart  controllo dei dati ricevuti
└── errors/api_exception.dart
```

## Avvio

Requisiti: [Dart SDK](https://dart.dev/get-dart) 3.x.

```bash
dart pub get
dart run bin/server.dart
```

Il server è in ascolto sulla porta **8080** e all'avvio stampa l'indirizzo da usare nell'app, ad esempio:

```
Bacheca Lavoro backend in ascolto sulla porta 8080
Usa questo URL nell'app: http://192.168.1.57:8080
```

Il telefono deve essere sulla **stessa rete Wi-Fi** del computer.

Variabili d'ambiente opzionali: `PORT` (porta, default 8080), `DATA_DIR` (default `data`),
`UPLOADS_DIR` (default `uploads`).

## Dati

Al primo avvio vengono create le cartelle:

- `data/companies.json`, `data/jobs.json`, `data/applications.json`: aziende, annunci e candidature;
- `uploads/`: i file PDF dei curriculum.

I dati restano disponibili anche dopo il riavvio del server. Le password non sono mai salvate in chiaro.
I token di sessione sono tenuti in memoria: dopo un riavvio del server occorre rifare il login.

## API

Tutte le risposte sono in JSON; in caso di errore: `{"error": "messaggio"}`.
Le rotte dell'area azienda richiedono l'header `Authorization: Bearer <token>`.

| Metodo | Endpoint | Accesso | Descrizione |
|---|---|---|---|
| POST | `/api/auth/register` | pubblico | R1 – crea l'account dell'azienda (`name`, `email`, `password`) |
| POST | `/api/auth/login` | pubblico | R2 – login con `email` e `password`, restituisce il token |
| POST | `/api/auth/logout` | azienda | R3 – invalida il token |
| GET | `/api/auth/me` | azienda | dati dell'azienda autenticata |
| GET | `/api/jobs` | pubblico | R5 – elenco degli annunci |
| GET | `/api/jobs/<id>` | pubblico | R5 – dettaglio di un annuncio |
| POST | `/api/jobs/<id>/applications` | pubblico | R6 – candidatura (`firstName`, `lastName`, `email`, `cvFileName`, `cvBase64`) |
| POST | `/api/company/jobs` | azienda | R4 – pubblica un annuncio (`title`, `description`) |
| GET | `/api/company/jobs` | azienda | annunci dell'azienda |
| GET | `/api/company/jobs/<id>/applications` | azienda proprietaria | R7 – candidature ricevute |
| GET | `/api/company/applications/<id>/cv` | azienda proprietaria | R7 – scarica il PDF del curriculum |

Il curriculum viene inviato dal client come testo **base64** dentro il JSON e salvato dal server
nella cartella `uploads/` con un nome generato dal server.

### Esempio con curl

```bash
# Registrazione e login
curl -H "Content-Type: application/json" \
  -d '{"name":"Acme Srl","email":"hr@acme.it","password":"Password1"}' \
  http://localhost:8080/api/auth/register

curl -H "Content-Type: application/json" \
  -d '{"email":"hr@acme.it","password":"Password1"}' \
  http://localhost:8080/api/auth/login

# Bacheca pubblica
curl http://localhost:8080/api/jobs
```
