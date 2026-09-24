import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/project_cover.dart';
import '../domain/models.dart';

class LocalStore extends ChangeNotifier {
  LocalStore(this._preferences) {
    _load();
  }

  final SharedPreferences _preferences;
  final List<Project> projects = [];
  final List<ChatMessage> messages = [];
  bool isReady = false;

  final conversations = const [
    Conversation(
      id: 'team-kasai',
      title: 'Équipe Résidence Kasaï',
      subtitle: 'Chef de chantier · 4 membres',
      initials: 'RK',
      projectName: 'Résidence Kasaï',
      unread: 2,
    ),
    Conversation(
      id: 'atelier',
      title: 'Atelier Kalenda',
      subtitle: 'Aline, Patrick et 2 autres',
      initials: 'AK',
      projectName: 'Atelier Kalenda',
      unread: 0,
    ),
    Conversation(
      id: 'direction',
      title: 'Direction travaux',
      subtitle: 'Groupe interne · 6 membres',
      initials: 'DT',
      projectName: 'Tous les projets',
      unread: 1,
    ),
  ];

  final List<Activity> activities = const [
    Activity(
      title: 'Contrôle ferraillage fondations',
      project: 'Résidence Kasaï',
      time: '08:00',
      priority: 'Urgente',
      status: 'En cours',
    ),
    Activity(
      title: 'Réception du ciment',
      project: 'Atelier Kalenda',
      time: '10:30',
      priority: 'Haute',
      status: 'À faire',
    ),
    Activity(
      title: 'Point équipe chantier',
      project: 'Résidence Kasaï',
      time: '16:00',
      priority: 'Normale',
      status: 'À faire',
    ),
  ];

  final List<Payment> payments = const [
    Payment(
      project: 'Résidence Kasaï',
      amount: 18500,
      date: '12 sept.',
      method: 'Virement',
    ),
    Payment(
      project: 'Atelier Kalenda',
      amount: 7200,
      date: '09 sept.',
      method: 'Espèces',
    ),
    Payment(
      project: 'Bureaux Lumumba',
      amount: 12000,
      date: '02 sept.',
      method: 'Virement',
    ),
  ];

  double get totalReceived =>
      payments.fold(0, (sum, payment) => sum + payment.amount);
  double get totalExpenses => 12450;
  int get activeProjects => projects
      .where((project) => project.status == ProjectStatus.active)
      .length;

  void _load() {
    final raw = _preferences.getString('projects');
    if (raw == null) {
      projects.addAll(_seedProjects());
      _persist();
    } else {
      projects.addAll(
        (jsonDecode(raw) as List).map(
          (item) => Project.fromJson(item as Map<String, dynamic>),
        ),
      );
    }
    for (var index = 0; index < projects.length; index++) {
      final project = projects[index];
      // Covers live inside the bundle: any legacy remote URL (or an empty
      // value) is remapped so the card always renders a real photo offline.
      if (project.imageUrl.isEmpty || project.imageUrl.startsWith('http')) {
        project.imageUrl = coverForSeed(project.id);
      }
    }
    _persist();
    final rawMessages = _preferences.getString('messages');
    messages.addAll(
      rawMessages == null
          ? _seedMessages()
          : (jsonDecode(rawMessages) as List).map(
              (item) => ChatMessage.fromJson(item as Map<String, dynamic>),
            ),
    );
    isReady = true;
    notifyListeners();
  }

  List<Project> _seedProjects() {
    final now = DateTime.now();
    return [
      Project(
        id: 'p1',
        name: 'Résidence Kasaï',
        reference: 'AK-2026-001',
        client: 'M. Kabeya',
        location: 'Limete, Kinshasa',
        progress: 68,
        status: ProjectStatus.active,
        contractAmount: 85000,
        plannedEnd: now.add(const Duration(days: 48)),
        imageUrl: 'assets/images/covers/cover-01.jpg',
      ),
      Project(
        id: 'p2',
        name: 'Atelier Kalenda',
        reference: 'AK-2026-002',
        client: 'Kalenda Industries',
        location: 'Gombe, Kinshasa',
        progress: 42,
        status: ProjectStatus.active,
        contractAmount: 42000,
        plannedEnd: now.add(const Duration(days: 25)),
        imageUrl: 'assets/images/covers/cover-02.jpg',
      ),
      Project(
        id: 'p3',
        name: 'Bureaux Lumumba',
        reference: 'AK-2025-014',
        client: 'Lumumba Conseil',
        location: 'Ngaliema, Kinshasa',
        progress: 100,
        status: ProjectStatus.completed,
        contractAmount: 64000,
        plannedEnd: now.subtract(const Duration(days: 12)),
        imageUrl: 'assets/images/covers/cover-03.jpg',
      ),
      Project(
        id: 'p4',
        name: 'Extension école Matonge',
        reference: 'AK-2026-003',
        client: 'Fondation Matonge',
        location: 'Matonge, Kinshasa',
        progress: 12,
        status: ProjectStatus.planned,
        contractAmount: 28000,
        plannedEnd: now.add(const Duration(days: 92)),
        imageUrl: 'assets/images/covers/cover-04.jpg',
      ),
    ];
  }

  void addProject({
    required String name,
    required String client,
    String location = 'À préciser',
    double contractAmount = 0,
    double progress = 0,
    ProjectStatus status = ProjectStatus.planned,
    DateTime? plannedEnd,
    String? imageUrl,
  }) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    projects.insert(
      0,
      Project(
        id: id,
        name: name,
        reference: 'AK-${DateTime.now().year}-${(projects.length + 4).toString().padLeft(3, '0')}',
        client: client,
        location: location.isEmpty ? 'À préciser' : location,
        progress: progress.clamp(0, 100),
        status: status,
        contractAmount: contractAmount,
        plannedEnd: plannedEnd ?? DateTime.now().add(const Duration(days: 90)),
        imageUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : coverForSeed(id),
      ),
    );
    _persist();
    notifyListeners();
  }

  void updateProject(Project project) {
    final index = projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      projects[index] = project;
      _persist();
      notifyListeners();
    }
  }

  void deleteProject(Project project) {
    projects.removeWhere((item) => item.id == project.id);
    _persist();
    notifyListeners();
  }

  List<ChatMessage> _seedMessages() {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: 'm1',
        conversationId: 'team-kasai',
        body:
            'Le ferraillage des fondations est terminé sur la zone B. Je vous envoie les photos du contrôle.',
        projectName: 'Résidence Kasaï',
        sentAt: now.subtract(const Duration(minutes: 18)),
        isMine: false,
        attachmentNames: const ['controle-zone-b.jpg', 'ferraillage-b.jpg'],
      ),
      ChatMessage(
        id: 'm2',
        conversationId: 'team-kasai',
        body: 'Bien reçu. On garde le coulage à 16 h si la météo reste stable.',
        projectName: 'Résidence Kasaï',
        sentAt: now.subtract(const Duration(minutes: 11)),
        isMine: true,
      ),
      ChatMessage(
        id: 'm3',
        conversationId: 'direction',
        body:
            'Le brief quotidien est prêt : trois activités terminées, une livraison reçue et aucun blocage critique.',
        projectName: 'Tous les projets',
        sentAt: now.subtract(const Duration(hours: 2)),
        isMine: false,
      ),
    ];
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
    messages.add(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        conversationId: conversationId,
        body: body,
        projectName: projectName,
        sentAt: DateTime.now(),
        isMine: true,
        attachmentNames: attachmentNames,
      ),
    );
    _preferences.setString(
      'messages',
      jsonEncode(messages.map((message) => message.toJson()).toList()),
    );
    notifyListeners();
  }

  void _persist() => _preferences.setString(
    'projects',
    jsonEncode(projects.map((project) => project.toJson()).toList()),
  );
}
