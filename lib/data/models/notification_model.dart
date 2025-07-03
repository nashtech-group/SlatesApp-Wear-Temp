import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? payload;
  final String? siteName;
  final DateTime? dutyTime;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.payload,
    this.siteName,
    this.dutyTime,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        timestamp,
        isRead,
        payload,
        siteName,
        dutyTime,
      ];

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? payload,
    String? siteName,
    DateTime? dutyTime,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
      siteName: siteName ?? this.siteName,
      dutyTime: dutyTime ?? this.dutyTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'payload': payload,
      'siteName': siteName,
      'dutyTime': dutyTime?.toIso8601String(),
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NotificationType.system,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      payload: json['payload'],
      siteName: json['siteName'],
      dutyTime: json['dutyTime'] != null ? DateTime.parse(json['dutyTime']) : null,
    );
  }
}

enum NotificationType {
  dutyReminder,
  batteryAlert,
  checkpointComplete,
  emergency,
  syncReminder,
  system,
  positionAlert,
}