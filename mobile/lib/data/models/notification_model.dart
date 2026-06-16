class NotificationModel {
  final String _id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? referenceId;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  NotificationModel({
    required String id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.referenceId,
    required this.data,
    required this.createdAt,
  }) : _id = id;

  String get id => _id;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['isRead'] ?? json['read'] ?? false,
      referenceId: json['referenceId'] ?? json['payload']?['referenceId'],
      data: json['data'] ?? json['payload'] ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': _id,
        'title': title,
        'body': body,
        'type': type,
        'isRead': isRead,
        'referenceId': referenceId,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
      };

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: _id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      referenceId: referenceId,
      data: data,
      createdAt: createdAt,
    );
  }
}
