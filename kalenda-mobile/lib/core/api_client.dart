import 'dart:convert';

import 'package:http/http.dart' as http;

/// Un module d'activite, tel que renvoye par GET /api/v1/modules.
///
/// Le catalogue vit en base : ajouter un module cote API suffit, l'app lit la
/// liste et pilote l'ecran de connexion sans changement de code.
class KalendaModule {
  const KalendaModule({
    required this.id,
    required this.label,
    required this.status,
    required this.promise,
    required this.cover,
    required this.highlights,
    required this.fields,
  });

  factory KalendaModule.fromJson(Map<String, dynamic> json) => KalendaModule(
    id: json['id'] as String? ?? '',
    label: json['label'] as String? ?? '',
    status: json['status'] as String? ?? 'planned',
    promise: json['promise'] as String? ?? '',
    cover: json['cover'] as String? ?? '',
    highlights:
        (json['highlights'] as List?)?.map((e) => '$e').toList() ?? const [],
    fields: (json['fields'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => ModuleField.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );

  final String id;
  final String label;

  /// `available` = selectionnable, `planned` = annonce mais pas encore livre.
  final String status;
  final String promise;
  final String cover;
  final List<String> highlights;
  final List<ModuleField> fields;

  bool get isAvailable => status == 'available';
}

/// Champ de specialisation demande au compte, propre a un module.
class ModuleField {
  const ModuleField({
    required this.key,
    required this.label,
    required this.type,
    this.options = const [],
    this.optional = false,
  });

  factory ModuleField.fromJson(Map<String, dynamic> json) => ModuleField(
    key: json['key'] as String? ?? '',
    label: json['label'] as String? ?? '',
    type: json['type'] as String? ?? 'text',
    options: (json['options'] as List?)?.map((e) => '$e').toList() ?? const [],
    optional: json['optional'] as bool? ?? false,
  );

  final String key;
  final String label;

  /// `select` ou `text`.
  final String type;
  final List<String> options;
  final bool optional;

  bool get isSelect => type == 'select';

  /// Libelle affiche, les champs facultatifs etant marques.
  String get displayLabel => optional ? '$label (facultatif)' : label;
}

/// Un pays et son indicatif telephonique international.
class Country {
  const Country(this.code, this.dial, this.label);

  /// Code ISO 3166-1 alpha-2.
  final String code;

  /// Indicatif, sans « + ».
  final String dial;
  final String label;
}

/// Pays proposes pour la connexion par telephone.
///
/// Liste volontairement restreinte aux pays francophones et voisins, plus
/// quelques pays frequents. Un numero hors liste reste saisissable en
/// ecrivant l'indicatif complet dans le champ.
const List<Country> kCountries = [
  Country('CD', '243', 'République démocratique du Congo'),
  Country('CG', '242', 'Congo'),
  Country('CI', '225', "Côte d'Ivoire"),
  Country('CM', '237', 'Cameroun'),
  Country('CF', '236', 'République centrafricaine'),
  Country('GA', '241', 'Gabon'),
  Country('GQ', '240', 'Guinée équatoriale'),
  Country('TD', '235', 'Tchad'),
  Country('AO', '244', 'Angola'),
  Country('ZM', '260', 'Zambie'),
  Country('MA', '212', 'Maroc'),
  Country('DZ', '213', 'Algérie'),
  Country('TN', '216', 'Tunisie'),
  Country('SN', '221', 'Sénégal'),
  Country('ML', '223', 'Mali'),
  Country('BF', '226', 'Burkina Faso'),
  Country('NE', '227', 'Niger'),
  Country('BJ', '229', 'Bénin'),
  Country('GN', '224', 'Guinée'),
  Country('RW', '250', 'Rwanda'),
  Country('BI', '257', 'Burundi'),
  Country('UG', '256', 'Ouganda'),
  Country('KE', '254', 'Kenya'),
  Country('TZ', '255', 'Tanzanie'),
  Country('MG', '261', 'Madagascar'),
  Country('MU', '230', 'Maurice'),
  Country('FR', '33', 'France'),
  Country('BE', '32', 'Belgique'),
  Country('CH', '41', 'Suisse'),
  Country('CA', '1', 'Canada'),
];

const String kDefaultCountry = 'CD';

/// Indicatif du pays choisi, avec repli sur la RDC.
String dialFor(String code) => kCountries
    .firstWhere((c) => c.code == code, orElse: () => kCountries.first)
    .dial;

/// Compose l'identifiant transmis au backend.
///
/// Un e-mail passe tel quel ; un numero recoit l'indicatif choisi. Si
/// l'utilisateur a deja saisi un « + », on ne l'ajoute pas deux fois.
String toIdentifier(String value, String dial) {
  final trimmed = value.trim();
  if (trimmed.contains('@') || trimmed.startsWith('+')) return trimmed;
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? trimmed : '+$dial$digits';
}

/// Client HTTP de l'API Alliya Kalenda (kalenda-backend).
///
/// L'URL de base est injectee a la compilation :
///
/// ```sh
/// flutter run --dart-define=KALENDA_API_URL=https://api.exemple.com
/// ```
///
/// Sans URL ciblee, l'application ne peut pas se connecter et les pages restent vides.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? apiUrl).replaceAll(RegExp(r'/+$'), '');

  static const String apiUrl = String.fromEnvironment('KALENDA_API_URL');

  final http.Client _client;

  /// URL effective. Les tests injectent une cible pour piloter le client sans
  /// dependre du `--dart-define` de compilation.
  final String _baseUrl;

  /// Vrai quand l'URL de l'API a ete fournie a la compilation.
  static bool get isConfigured => apiUrl.trim().isNotEmpty;

  /// Vrai quand cette instance peut interroger un backend.
  bool get hasTarget => _baseUrl.isNotEmpty;

  String get baseUrl => _baseUrl;

  /// Appele a chaque changement de tokens pour les persister. Le client
  /// n'ecrit rien sur le disque : c'est l'appelant (LocalStore) qui decide.
  void Function(String? access, String? refresh)? onTokensChanged;

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => (_accessToken ?? '').isNotEmpty;

  // ---------------------------------------------------------------- Session

  void restoreTokens({String? access, String? refresh}) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    onTokensChanged?.call(null, null);
  }

  void setTokensFromResponse(Map<String, dynamic> data) {
    final access = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    if (access != null) _accessToken = access;
    if (refresh != null) _refreshToken = refresh;
    onTokensChanged?.call(_accessToken, _refreshToken);
  }

  /// Connexion par e-mail OU par numero de telephone.
  Future<Map<String, dynamic>> login(String identifier, String password) {
    return _auth('/api/v1/auth/login', {
      'identifier': identifier,
      'password': password,
    });
  }

  /// Verifie une identite Google.
  ///
  /// Deux issues : le compte existe et la session est ouverte, ou le backend
  /// repond 409 pour dire qu'il faut completer l'inscription. On leve une
  /// [GoogleSignupRequired] dans ce second cas : ce n'est pas une panne.
  Future<Map<String, dynamic>> loginWithGoogle(String credential) async {
    final response = await _post('/api/v1/auth/google', {
      'credential': credential,
    });
    if (response.statusCode == 409) {
      throw GoogleSignupRequired.fromResponse(response);
    }
    return _readSession(response);
  }

  /// Acheve l'inscription d'une identite Google : module, metier, mot de passe.
  Future<Map<String, dynamic>> registerWithGoogle({
    required String credential,
    required String password,
    required String module,
    required String jobTitle,
    String companyName = '',
    String? phone,
    String certifications = '',
  }) {
    return _auth('/api/v1/auth/google/register', {
      'credential': credential,
      'password': password,
      'module': module,
      'jobTitle': jobTitle,
      'companyName': companyName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'certifications': certifications,
    });
  }

  /// Cree le compte avec le module et la specialite choisis a l'etape 2 et 3
  /// du parcours d'inscription. [email] et [phone] sont l'un ou l'autre.
  Future<Map<String, dynamic>> register({
    String? email,
    String? phone,
    required String password,
    required String fullName,
    required String module,
    required String jobTitle,
    String companyName = '',
    String certifications = '',
  }) {
    return _auth('/api/v1/auth/register', {
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'password': password,
      'fullName': fullName,
      'module': module,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'certifications': certifications,
    });
  }

  /// Verifie les identifiants puis memorise les tokens renvoyes.
  Future<Map<String, dynamic>> _auth(
    String path,
    Map<String, dynamic> body,
  ) async {
    final data = await _send('POST', path, body: body, authenticated: false);
    final session = Map<String, dynamic>.from(data as Map);
    setTokensFromResponse(session);
    return session;
  }

  Future<Map<String, dynamic>> me() async {
    final data = await _send('GET', '/api/v1/auth/me');
    return Map<String, dynamic>.from(data as Map);
  }

  // ---------------------------------------------------------------- Lecture

  /// Catalogue des modules d'activite, servi par l'API.
  ///
  /// Public : l'ecran de connexion en a besoin avant toute session. Aucun
  /// module n'est code en dur dans l'app.
  Future<List<KalendaModule>> modules() async {
    final data = await _send('GET', '/api/v1/modules', authenticated: false);
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((row) => KalendaModule.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<bool> health() async {
    try {
      final data = await _send('GET', '/api/v1/health', authenticated: false);
      return (data as Map)['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? query,
  }) async {
    final data = await _send('GET', _withQuery(path, query));
    if (data is List) return data;
    return const [];
  }

  Future<Map<String, dynamic>> getObject(String path) async {
    final data = await _send('GET', path);
    return Map<String, dynamic>.from(data as Map);
  }

  // ---------------------------------------------------------------- Ecriture

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final data = await _send('POST', path, body: body);
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final data = await _send('PATCH', path, body: body);
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  Future<void> delete(String path) => _send('DELETE', path);

  // ---------------------------------------------------------------- Interne

  String _withQuery(String path, Map<String, String>? query) {
    if (query == null || query.isEmpty) return path;
    final parts = query.entries
        .where((entry) => entry.value.isNotEmpty)
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}='
              '${Uri.encodeQueryComponent(entry.value)}',
        )
        .toList();
    if (parts.isEmpty) return path;
    return '$path?${parts.join('&')}';
  }

  /// POST public qui rend la reponse brute, sans lever sur un 409.
  ///
  /// Le flux Google s'en sert : un 409 ne signifie pas une panne, mais
  /// « ce compte n'existe pas encore ». Il faut pouvoir le lire.
  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    if (!_baseUrl.isNotEmpty) {
      throw const ApiException(0, 'API non configuree (KALENDA_API_URL)');
    }
    final request = http.Request('POST', Uri.parse('$baseUrl$path'));
    request.headers.addAll(const {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    });
    request.body = jsonEncode(body);
    final streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 20));
    return http.Response.fromStream(streamed);
  }

  /// Memorise les jetons d'une reponse de session.
  Map<String, dynamic> _readSession(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        _errorMessage(jsonDecode(utf8.decode(response.bodyBytes)), response),
      );
    }
    final session = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map,
    );
    setTokensFromResponse(session);
    return session;
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
    bool retry = true,
  }) async {
    if (!_baseUrl.isNotEmpty) {
      throw const ApiException(0, 'API non configuree (KALENDA_API_URL)');
    }

    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers.addAll(const {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    });
    if (authenticated && (_accessToken ?? '').isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }
    if (body != null) request.body = jsonEncode(body);

    final streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 204 || response.body.isEmpty) {
      return const <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 401 && authenticated && retry) {
      final renewed = await _refreshAccessToken();
      if (renewed) {
        return _send(
          method,
          path,
          body: body,
          authenticated: authenticated,
          retry: false,
        );
      }
      clearTokens();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, _errorMessage(decoded, response));
    }

    return decoded;
  }

  /// Extrait un message lisible de l'enveloppe d'erreur du backend
  /// (`{ "error": { "message": ..., "details": ... } }`). Les formes plates
  /// restent acceptees pour les erreurs emises par un proxy ou une passerelle.
  String _errorMessage(dynamic decoded, http.Response response) {
    if (decoded is Map) {
      final error = decoded['error'];
      final nested = error is Map ? error['message'] : null;
      for (final candidate in <dynamic>[nested, decoded['message'], error]) {
        if (candidate is String && candidate.isNotEmpty) return candidate;
      }
    }
    return 'Erreur ${response.statusCode}';
  }

  Future<bool> _refreshAccessToken() async {
    final refresh = _refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final data = await _send(
        'POST',
        '/api/v1/auth/refresh',
        body: {'refreshToken': refresh},
        authenticated: false,
        retry: false,
      );
      if (data is Map) {
        setTokensFromResponse(Map<String, dynamic>.from(data));
        return (_accessToken ?? '').isNotEmpty;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  void close() => _client.close();
}

/// Erreur HTTP renvoyee par l'API.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Le backend ne connait pas encore cette identite Google.
///
/// Ce n'est pas une erreur : l'ecran doit derouler le parcours d'inscription
/// (module, metier, mot de passe) avant d'obtenir une session. On transporte
/// l'adresse Google pour la proposer, et [requiresLink] indique qu'un compte
/// existe deja avec cette adresse : il sera relie plutot que duplique.
class GoogleSignupRequired implements Exception {
  const GoogleSignupRequired({
    required this.email,
    required this.name,
    required this.requiresLink,
    required this.message,
  });

  factory GoogleSignupRequired.fromResponse(http.Response response) {
    var email = '';
    var name = '';
    var requiresLink = false;
    var message = "Completez votre inscription pour continuer.";
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final error = (decoded is Map ? decoded['error'] : null);
      if (error is Map) {
        email = error['email'] as String? ?? '';
        name = error['name'] as String? ?? '';
        requiresLink = error['requiresLink'] as bool? ?? false;
        final text = error['message'];
        if (text is String && text.isNotEmpty) message = text;
      }
    } catch (_) {
      // Envelope inattendue : on garde le message par defaut plutot que
      // de faire echouer la connexion sur une erreur de forme.
    }
    return GoogleSignupRequired(
      email: email,
      name: name,
      requiresLink: requiresLink,
      message: message,
    );
  }

  final String email;
  final String name;
  final bool requiresLink;
  final String message;

  @override
  String toString() => 'GoogleSignupRequired: $message';
}
