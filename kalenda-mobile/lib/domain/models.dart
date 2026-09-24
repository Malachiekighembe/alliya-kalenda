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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'reference': reference,
    'client': client,
    'location': location,
    'progress': progress,
    'status': status.name,
    'contractAmount': contractAmount,
    'plannedEnd': plannedEnd.toIso8601String(),
    'imageUrl': imageUrl,
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String,
    name: json['name'] as String,
    reference: json['reference'] as String,
    client: json['client'] as String,
    location: json['location'] as String,
    progress: (json['progress'] as num).toDouble(),
    status: ProjectStatus.values.byName(json['status'] as String),
    contractAmount: (json['contractAmount'] as num).toDouble(),
    plannedEnd: DateTime.parse(json['plannedEnd'] as String),
    imageUrl: json['imageUrl'] as String? ?? '',
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'body': body,
    'projectName': projectName,
    'sentAt': sentAt.toIso8601String(),
    'isMine': isMine,
    'attachmentNames': attachmentNames,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    conversationId: json['conversationId'] as String,
    body: json['body'] as String,
    projectName: json['projectName'] as String,
    sentAt: DateTime.parse(json['sentAt'] as String),
    isMine: json['isMine'] as bool,
    attachmentNames: List<String>.from(
      json['attachmentNames'] as List<dynamic>,
    ),
  );
}
