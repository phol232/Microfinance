import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notification.dart';

class AppNotificationDto {
  const AppNotificationDto({
    this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.isRead = false,
    this.userId,
    this.data,
    this.imageUrl,
    this.actionUrl,
  });

  final String? id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime createdAt;
  final bool isRead;
  final String? userId;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final String? actionUrl;

  factory AppNotificationDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppNotificationDto(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _parseNotificationType(data['type']),
      priority: _parseNotificationPriority(data['priority']),
      createdAt: _parseTimestamp(data['createdAt']),
      isRead: data['isRead'] ?? false,
      userId: data['userId'],
      data: data['data'] != null ? Map<String, dynamic>.from(data['data']) : null,
      imageUrl: data['imageUrl'],
      actionUrl: data['actionUrl'],
    );
  }

  factory AppNotificationDto.fromDomain(AppNotification notification) {
    return AppNotificationDto(
      id: notification.id.isEmpty ? null : notification.id,
      title: notification.title,
      message: notification.message,
      type: notification.type,
      priority: notification.priority,
      createdAt: notification.createdAt,
      isRead: notification.isRead,
      userId: notification.userId,
      data: notification.data,
      imageUrl: notification.imageUrl,
      actionUrl: notification.actionUrl,
    );
  }

  AppNotification toDomain() {
    return AppNotification(
      id: id ?? '',
      title: title,
      message: message,
      type: type,
      priority: priority,
      createdAt: createdAt,
      isRead: isRead,
      userId: userId,
      data: data,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      if (userId != null) 'userId': userId,
      if (data != null) 'data': data,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (actionUrl != null) 'actionUrl': actionUrl,
    };
  }
}

NotificationType _parseNotificationType(dynamic value) {
  switch (value?.toString()) {
    case 'accountActivated':
      return NotificationType.accountActivated;
    case 'cardActivated':
      return NotificationType.cardActivated;
    case 'loanApproved':
      return NotificationType.loanApproved;
    case 'loanRejected':
      return NotificationType.loanRejected;
    case 'paymentReminder':
      return NotificationType.paymentReminder;
    default:
      return NotificationType.general;
  }
}

NotificationPriority _parseNotificationPriority(dynamic value) {
  switch (value?.toString()) {
    case 'low':
      return NotificationPriority.low;
    case 'high':
      return NotificationPriority.high;
    case 'urgent':
      return NotificationPriority.urgent;
    default:
      return NotificationPriority.normal;
  }
}

DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
}
