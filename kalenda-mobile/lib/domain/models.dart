enum ProjectStatus { planned, active, paused, completed, cancelled }

class Project {
  Project({
    required this.id,
    required this.name,
    required this.reference,
    required this.client,
    required this.location,
    required this.progress,
    required this.status,
    required this.contractAmount,
    required this.plannedEnd,
    required this.imageUrl,
  });

  final String id;
  String name;
  String reference;
  String client;
  String location;
  double progress;
  ProjectStatus status;
  double contractAmount;
  DateTime plannedEnd;
  String imageUrl;

  /// Construit un projet depuis la charge utile de `GET /api/v1/projects`.
  ///
  /// La table `projects` ne stocke pas d'image : la couverture est fournie par
  /// l'appelant, qui la derive de l'identifiant. Les `Decimal` Prisma arrivent
  /// en JSON sous forme de chaine, d'ou [numOf].
  factory Project.fromApi(
    Map<String, dynamic> json, {
    required String imageUrl,
  }) {
    final id = json['id'] as String;
    return Project(
      id: id,
      name: (json['name'] as String?) ?? 'Sans nom',
      reference: (json['reference'] as String?)?.isNotEmpty == true
          ? json['reference'] as String
          : 'AK-${id.substring(0, id.length < 6 ? id.length : 6).toUpperCase()}',
      client: (json['clientName'] as String?)?.isNotEmpty == true
          ? json['clientName'] as String
          : 'Client non renseigné',
      location: (json['location'] as String?)?.isNotEmpty == true
          ? json['location'] as String
          : 'Kinshasa',
      progress: numOf(json['progress']),
      status: _statusFromApi(json['status'] as String?),
      contractAmount: numOf(json['contractAmount']),
      plannedEnd:
          DateTime.tryParse(json['plannedEndDate'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 90)),
      imageUrl: imageUrl,
    );
  }
}

/// Les `Decimal` Prisma sont serialises en chaine JSON.
double numOf(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

ProjectStatus _statusFromApi(String? value) => switch (value) {
  'active' => ProjectStatus.active,
  'paused' => ProjectStatus.paused,
  'completed' => ProjectStatus.completed,
  'cancelled' => ProjectStatus.cancelled,
  _ => ProjectStatus.planned,
};

const _statusLabels = {
  'in_progress': 'En cours',
  'completed': 'Terminée',
  'todo': 'À faire',
};

const _priorityLabels = {
  'urgent': 'Urgente',
  'high': 'Haute',
  'low': 'Basse',
  'normal': 'Normale',
};

String _hhmm(Object? iso) {
  final parsed = DateTime.tryParse('$iso');
  if (parsed == null) return '--:--';
  final local = parsed.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

class Activity {
  const Activity({
    required this.title,
    required this.project,
    required this.time,
    required this.priority,
    required this.status,
  });
  final String title;
  final String project;
  final String time;
  final String priority;
  final String status;

  /// `GET /api/v1/activities` inclut `{ id, name }` du projet lie.
  factory Activity.fromApi(Map<String, dynamic> json) => Activity(
    title: (json['title'] as String?) ?? 'Sans titre',
    project: ((json['project'] as Map?)?['name'] as String?) ?? 'Général',
    time: _hhmm(json['activityDate']),
    priority: _priorityLabels[json['priority']] ?? 'Normale',
    status: _statusLabels[json['status']] ?? 'À faire',
  );
}

class Payment {
  const Payment({
    required this.project,
    required this.amount,
    required this.date,
    required this.method,
  });
  final String project;
  final double amount;
  final String date;
  final String method;

  /// `projectName` vient de la table des projets : la route paiements renvoie
  /// seulement `projectId`.
  factory Payment.fromApi(
    Map<String, dynamic> json, {
    required String projectName,
  }) => Payment(
    project: projectName,
    amount: numOf(json['amount']),
    date: _shortDate(json['paymentDate']),
    method: (json['method'] as String?)?.isNotEmpty == true
        ? json['method'] as String
        : '—',
  );
}

String _shortDate(Object? iso) {
  final parsed = DateTime.tryParse('$iso');
  if (parsed == null) return '—';
  const months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', //
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];
  return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]}';
}

class Person {
  const Person({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    this.project = 'Non affecté',
  });

  final String id;
  final String name;
  final String role;
  final String phone;

  /// La table `people` n'est pas liee a un projet : le backend renvoie donc
  /// « Non affecté » : l'affectation n'est pas modelisee par l'API.
  final String project;

  /// Vrai quand la personne est rattachee a un chantier (statut « sur site »).
  bool get onSite => project != 'Non affecté';

  /// `GET /api/v1/people` renvoie `fullName` / `jobTitle`.
  factory Person.fromApi(Map<String, dynamic> json) => Person(
    id: json['id'] as String,
    name: (json['fullName'] as String?)?.isNotEmpty == true
        ? json['fullName'] as String
        : 'Sans nom',
    role: (json['jobTitle'] as String?)?.isNotEmpty == true
        ? json['jobTitle'] as String
        : 'Collaborateur',
    phone: (json['phone'] as String?) ?? '',
  );
}

class Report {
  const Report({
    required this.id,
    required this.title,
    required this.summary,
    required this.project,
    required this.date,
  });

  final String id;
  final String title;
  final String summary;
  final String project;
  final DateTime date;

  /// `GET /api/v1/reports` inclut `{ id, name }` du projet lie.
  factory Report.fromApi(
    Map<String, dynamic> json, {
    required String projectName,
  }) => Report(
    id: json['id'] as String,
    title: (json['title'] as String?) ?? 'Rapport',
    summary: (json['body'] as String?)?.isNotEmpty == true
        ? json['body'] as String
        : '—',
    project: ((json['project'] as Map?)?['name'] as String?) ?? projectName,
    date: DateTime.tryParse('${json['reportDate']}') ?? DateTime.now(),
  );
}

/// Reponse de `GET /api/v1/finances/summary`.
class FinanceSummary {
  const FinanceSummary({
    required this.received,
    required this.spent,
    required this.balance,
  });

  final double received;
  final double spent;
  final double balance;

  factory FinanceSummary.fromApi(Map<String, dynamic> json) => FinanceSummary(
    received: numOf(json['received']),
    spent: numOf(json['spent']),
    balance: numOf(json['balance']),
  );
}

class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.initials,
    required this.projectName,
    required this.unread,
  });
  final String id;
  final String title;
  final String subtitle;
  final String initials;
  final String projectName;
  final int unread;

  /// `GET /api/v1/conversations` renvoie `unread` en nombre et `lastMessage`.
  factory Conversation.fromApi(Map<String, dynamic> json) {
    final title = (json['title'] as String?) ?? 'Discussion';
    final rawUnread = json['unread'];
    return Conversation(
      id: json['id'] as String,
      title: title,
      subtitle: (json['recipientLabel'] as String?)?.isNotEmpty == true
          ? json['recipientLabel'] as String
          : ((json['project'] as Map?)?['name'] as String?) ?? 'Discussion',
      initials: title
          .substring(0, title.length < 2 ? title.length : 2)
          .toUpperCase(),
      projectName:
          ((json['project'] as Map?)?['name'] as String?) ?? 'Tous les projets',
      unread: rawUnread is int ? rawUnread : (rawUnread == true ? 1 : 0),
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.body,
    required this.projectName,
    required this.sentAt,
    required this.isMine,
    this.attachmentNames = const [],
  });

  final String id;
  final String conversationId;
  final String body;
  final String projectName;
  final DateTime sentAt;
  final bool isMine;
  final List<String> attachmentNames;

  /// `GET /api/v1/conversations/:id/messages` ajoute `mine` et `attachments`.
  factory ChatMessage.fromApi(
    Map<String, dynamic> json, {
    required String projectName,
  }) => ChatMessage(
    id: json['id'] as String,
    conversationId: json['conversationId'] as String,
    body: (json['body'] as String?) ?? '',
    projectName: projectName,
    sentAt: DateTime.tryParse('${json['sentAt']}') ?? DateTime.now(),
    isMine: json['mine'] == true,
    attachmentNames: (json['attachments'] as List<dynamic>? ?? const [])
        .map((item) => '${(item as Map)['filename'] ?? ''}')
        .where((name) => name.isNotEmpty)
        .toList(),
  );
}
