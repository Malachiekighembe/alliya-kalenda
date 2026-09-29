import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/project_cover.dart';
import '../domain/models.dart';

/// Etat de l'application cote donnees.
enum SyncStatus { unauthenticated, loading, ready, error, unconfigured }

/// Source de donnees unique de l'application.
///
/// Le backend est la seule source de verite : aucune donnee de demonstration
/// n'est conservee en local. `SharedPreferences` ne sert plus qu'a memoriser les
/// tokens JWT, afin de ne pas se reconnecter a chaque lancement.
class LocalStore extends ChangeNotifier {
  LocalStore(this._preferences, {ApiClient? api}) : _api = api ?? ApiClient() {
    _api.onTokensChanged = _persistTokens;
    _restoreSession();
  }

  final SharedPreferences _preferences;
  final ApiClient _api;

  final List<Project> projects = [];
  final List<ChatMessage> messages = [];
  final List<Activity> activities = [];
  final List<Payment> payments = [];
  final List<Conversation> conversations = [];
  final List<Person> people = [];
  final List<Report> reports = [];

  SyncStatus status = SyncStatus.unauthenticated;
  String? errorMessage;
  String? userEmail;

  /// Synthese des finances, fournie par `GET /finances/summary`.
  FinanceSummary finances = const FinanceSummary(
    received: 0,
    spent: 0,
    balance: 0,
  );

  bool get isReady => status == SyncStatus.ready;

  /// Vrai quand une session est ouverte sur le backend.
  bool get isOnline => _api.hasTarget && _api.isAuthenticated;

  /// Vrai quand une URL d'API a ete fournie a la compilation.
  bool get isApiConfigured => ApiClient.isConfigured;

  double get totalReceived => finances.received;
  double get totalExpenses => finances.spent;
  int get activeProjects => projects
      .where((project) => project.status == ProjectStatus.active)
      .length;

  static const _accessKey = 'kalenda.accessToken';
  static const _refreshKey = 'kalenda.refreshToken';

  /// Les identifiants provisoires commencent par "p" ; ceux du serveur sont des
  /// UUID. Les ecritures locales ne partent jamais sur l'API.
  static bool _isServerId(String id) => !id.startsWith('p');

  // ---------------------------------------------------------------- Session

  void _persistTokens(String? access, String? refresh) {
    if (access == null || refresh == null) {
      _preferences.remove(_accessKey);
      _preferences.remove(_refreshKey);
    } else {
      _preferences.setString(_accessKey, access);
      _preferences.setString(_refreshKey, refresh);
    }
  }

  /// Reprend la session precedente, si des tokens ont ete memorises.
  Future<void> _restoreSession() async {
    if (!_api.hasTarget) {
      status = SyncStatus.unconfigured;
      notifyListeners();
      return;
    }
    final access = _preferences.getString(_accessKey);
    final refresh = _preferences.getString(_refreshKey);
    if (access == null || refresh == null) {
      status = SyncStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _api.restoreTokens(access: access, refresh: refresh);
    await refreshFromApi();
  }

  void _requireApi() {
    if (!_api.hasTarget) {
      throw ApiException(
        0,
        "Aucune API configuree. Lancez l'application avec "
        '--dart-define=KALENDA_API_URL=<url>.',
      );
    }
  }

  Future<void> login(String email, String password) async {
    errorMessage = null;
    _requireApi();
    await _api.login(email.trim(), password);
    await _adoptSession();
  }

  /// Ouvre une session a partir d'un jeton d'identite Google.
  Future<void> loginWithGoogle(String credential) async {
    errorMessage = null;
    _requireApi();
    await _api.loginWithGoogle(credential);
    await _adoptSession();
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String module,
    required String jobTitle,
    String companyName = '',
    String phone = '',
    String certifications = '',
  }) async {
    errorMessage = null;
    _requireApi();
    await _api.register(
      email: email,
      password: password,
      fullName: fullName,
      module: module,
      jobTitle: jobTitle,
      companyName: companyName,
      phone: phone,
      certifications: certifications,
    );
    await _adoptSession();
  }

  /// Catalogue des modules d'activite, lu depuis l'API.
  ///
  /// Aucune session requise : l'ecran de connexion s'en sert pour proposer le
  /// choix du module et la specialite associee.
  Future<List<KalendaModule>> modules() async {
    if (ApiClient.apiUrl.isEmpty) return const [];
    return _api.modules();
  }

  Future<void> _adoptSession() async {
    final profile = await _api.me();
    userEmail = profile['email'] as String?;
    await refreshFromApi();
  }

  void logout() {
    _api.clearTokens();
    userEmail = null;
    errorMessage = null;
    _clearData();
    status = SyncStatus.unauthenticated;
    notifyListeners();
  }

  void _clearData() {
    projects.clear();
    messages.clear();
    activities.clear();
    payments.clear();
    conversations.clear();
    people.clear();
    reports.clear();
    finances = const FinanceSummary(received: 0, spent: 0, balance: 0);
  }

  // ---------------------------------------------------------------- Chargement

  /// Recharge l'integralite des donnees depuis le backend.
  Future<void> refreshFromApi() async {
    if (!isOnline) {
      status = ApiClient.isConfigured
          ? SyncStatus.unauthenticated
          : SyncStatus.unconfigured;
      notifyListeners();
      return;
    }

    status = SyncStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<dynamic>([
        _api.getList('/api/v1/projects'),
        _api.getList('/api/v1/activities'),
        _api.getList('/api/v1/finances/payments'),
        _api.getList('/api/v1/conversations'),
        _api.getList('/api/v1/people'),
        _api.getList('/api/v1/reports'),
        _api.getObject('/api/v1/finances/summary'),
      ]);

      final rawProjects = (results[0] as List).cast<Map<String, dynamic>>();
      final names = <String, String>{
        for (final item in rawProjects)
          '${item['id']}': '${item['name'] ?? ''}',
      };

      projects
        ..clear()
        ..addAll(
          rawProjects.map(
            (item) =>
                Project.fromApi(item, imageUrl: coverForSeed('${item['id']}')),
          ),
        );

      activities
        ..clear()
        ..addAll(
          (results[1] as List).map(
            (item) => Activity.fromApi(item as Map<String, dynamic>),
          ),
        );

      payments
        ..clear()
        ..addAll(
          (results[2] as List).map((item) {
            final map = item as Map<String, dynamic>;
            return Payment.fromApi(
              map,
              projectName: names['${map['projectId']}'] ?? 'Général',
            );
          }),
        );

      conversations
        ..clear()
        ..addAll(
          (results[3] as List).map(
            (item) => Conversation.fromApi(item as Map<String, dynamic>),
          ),
        );

      people
        ..clear()
        ..addAll(
          (results[4] as List).map(
            (item) => Person.fromApi(item as Map<String, dynamic>),
          ),
        );

      reports
        ..clear()
        ..addAll(
          (results[5] as List).map((item) {
            final map = item as Map<String, dynamic>;
            return Report.fromApi(
              map,
              projectName: names['${map['projectId']}'] ?? 'Général',
            );
          }),
        );

      finances = FinanceSummary.fromApi(results[6] as Map<String, dynamic>);
      _seedLastMessages(results[3] as List);
      status = SyncStatus.ready;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        _api.clearTokens();
        userEmail = null;
        _clearData();
        status = SyncStatus.unauthenticated;
        errorMessage = 'Session expirée, reconnectez-vous.';
      } else {
        status = SyncStatus.error;
        errorMessage = error.message;
      }
    } catch (error) {
      status = SyncStatus.error;
      errorMessage = '$error';
    }
    notifyListeners();
  }

  /// Les fils complets sont charges a l'ouverture : on conserve le dernier
  /// message de chaque discussion pour alimenter la liste.
  void _seedLastMessages(List talks) {
    messages
      ..clear()
      ..addAll(
        talks.where((item) => item['lastMessage'] != null).map((item) {
          final map = item as Map<String, dynamic>;
          final last = map['lastMessage'] as Map<String, dynamic>;
          return ChatMessage.fromApi(
            {
              'id': last['id'],
              'conversationId': map['id'],
              'projectId': map['projectId'],
              'body': last['body'],
              'sentAt': last['sentAt'],
              'mine': last['mine'],
              'attachments': const <dynamic>[],
            },
            projectName:
                (map['project'] as Map?)?['name'] as String? ??
                'Tous les projets',
          );
        }),
      );
  }

  /// Charge le fil complet d'une discussion.
  Future<void> openConversation(String conversationId) async {
    if (!isOnline) return;
    final talk = conversations.where((c) => c.id == conversationId).firstOrNull;
    final projectName = talk?.projectName ?? 'Tous les projets';

    try {
      final raw = await _api.getList(
        '/api/v1/conversations/$conversationId/messages',
      );
      final loaded = raw
          .map(
            (item) => ChatMessage.fromApi(
              item as Map<String, dynamic>,
              projectName: projectName,
            ),
          )
          .toList();

      messages
        ..removeWhere((m) => m.conversationId == conversationId)
        ..addAll(loaded);
      notifyListeners();
    } catch (error) {
      errorMessage = '$error';
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- Ecritures

  /// Execute une ecriture distante sans faire echouer l'appel local : l'ecran
  /// reste fluide et l'erreur est exposee via [errorMessage].
  Future<void> _push(Future<dynamic> Function() action) async {
    try {
      await action();
      await refreshFromApi();
    } catch (error) {
      errorMessage = '$error';
      notifyListeners();
    }
  }

  void addProject({
    required String name,
    String client = '',
    String location = '',
    double contractAmount = 0,
    double progress = 0,
    ProjectStatus status = ProjectStatus.planned,
    DateTime? plannedEnd,
    String? imageUrl,
  }) {
    final id = 'p_${DateTime.now().microsecondsSinceEpoch}';
    final draft = Project(
      id: id,
      name: name,
      reference: '—',
      client: client.isEmpty ? 'Client non renseigné' : client,
      location: location.isEmpty ? 'Kinshasa' : location,
      progress: progress.clamp(0, 100),
      status: status,
      contractAmount: contractAmount,
      plannedEnd: plannedEnd ?? DateTime.now().add(const Duration(days: 90)),
      imageUrl: (imageUrl != null && imageUrl.isNotEmpty)
          ? imageUrl
          : coverForSeed(id),
    );
    projects.insert(0, draft);
    notifyListeners();

    if (isOnline) {
      unawaited(
        _push(
          () => _api.post('/api/v1/projects', {
            'name': name,
            'clientName': draft.client,
            'location': draft.location,
            'contractAmount': contractAmount,
            'status': status.name,
            'progress': draft.progress,
            'plannedEndDate': draft.plannedEnd.toIso8601String(),
          }),
        ),
      );
    }
  }

  void updateProject(Project project) {
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      projects[index] = project;
      notifyListeners();
    }
    if (isOnline && _isServerId(project.id)) {
      unawaited(
        _push(
          () => _api.patch('/api/v1/projects/${project.id}', {
            'name': project.name,
            'clientName': project.client,
            'location': project.location,
            'contractAmount': project.contractAmount,
            'status': project.status.name,
            'progress': project.progress,
            'plannedEndDate': project.plannedEnd.toIso8601String(),
          }),
        ),
      );
    }
  }

  void deleteProject(Project project) {
    projects.removeWhere((item) => item.id == project.id);
    notifyListeners();
    if (isOnline && _isServerId(project.id)) {
      unawaited(_push(() => _api.delete('/api/v1/projects/${project.id}')));
    }
  }

  /// Ajoute une activite a l'agenda.
  void addActivity({
    required String title,
    String project = 'Général',
    String priority = 'Normale',
  }) {
    final now = DateTime.now();
    activities.insert(
      0,
      Activity(
        title: title,
        project: project,
        time:
            '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}',
        priority: priority,
        status: 'À faire',
      ),
    );
    notifyListeners();

    final target = projects.where((p) => p.name == project).firstOrNull;
    if (isOnline && target != null && _isServerId(target.id)) {
      const priorityApi = {
        'Urgente': 'urgent',
        'Haute': 'high',
        'Basse': 'low',
        'Normale': 'normal',
      };
      unawaited(
        _push(
          () => _api.post('/api/v1/activities', {
            'title': title,
            'projectId': target.id,
            'status': 'todo',
            'priority': priorityApi[priority] ?? 'normal',
          }),
        ),
      );
    }
  }

  /// Ajoute une personne au repertoire.
  void addPerson({
    required String name,
    required String role,
    String phone = '',
    String project = 'Non affecté',
  }) {
    people.insert(
      0,
      Person(
        id: 'p_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        role: role,
        phone: phone,
        project: project,
      ),
    );
    notifyListeners();

    if (isOnline) {
      unawaited(
        _push(
          () => _api.post('/api/v1/people', {
            'fullName': name,
            'jobTitle': role,
            'phone': phone,
          }),
        ),
      );
    }
  }

  /// Publie un rapport journalier pour un chantier.
  void addReport({
    required String title,
    required String summary,
    required String project,
  }) {
    reports.insert(
      0,
      Report(
        id: 'p_${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        summary: summary,
        project: project,
        date: DateTime.now(),
      ),
    );
    notifyListeners();

    final target = projects.where((p) => p.name == project).firstOrNull;
    if (isOnline && target != null && _isServerId(target.id)) {
      unawaited(
        _push(
          () => _api.post('/api/v1/reports', {
            'projectId': target.id,
            'title': title,
            'body': summary,
            'reportDate': DateTime.now().toIso8601String().substring(0, 10),
          }),
        ),
      );
    }
  }

  List<ChatMessage> messagesFor(String conversationId) =>
      messages
          .where((message) => message.conversationId == conversationId)
          .toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

  void sendMessage({
    required String conversationId,
    required String body,
    required String projectName,
    List<String> attachmentNames = const [],
  }) {
    final localId = 'p_${DateTime.now().microsecondsSinceEpoch}';
    messages.add(
      ChatMessage(
        id: localId,
        conversationId: conversationId,
        body: body,
        projectName: projectName,
        sentAt: DateTime.now(),
        isMine: true,
        attachmentNames: attachmentNames,
      ),
    );
    notifyListeners();

    if (isOnline) {
      unawaited(
        _push(() async {
          final sent = await _api.post(
            '/api/v1/conversations/$conversationId/messages',
            {'body': body},
          );
          final index = messages.indexWhere((m) => m.id == localId);
          if (index != -1) {
            messages[index] = ChatMessage.fromApi(
              sent,
              projectName: projectName,
            );
            notifyListeners();
          }
        }),
      );
    }
  }
}
