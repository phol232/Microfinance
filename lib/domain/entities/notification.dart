// TODO: Implementar entidad de notificaciones más adelante
// Archivo completo comentado para implementación futura

/*
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  accountActivated,
  cardActivated,
  loanApproved,
  loanRejected,
  paymentReminder,
  general,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class AppNotification {
  final String id;
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

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    required this.createdAt,
    this.isRead = false,
    this.userId,
    this.data,
    this.imageUrl,
    this.actionUrl,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: _parseNotificationType(map['type']),
      priority: _parseNotificationPriority(map['priority']),
      createdAt: _parseTimestamp(map['createdAt']),
      isRead: map['isRead'] ?? false,
      userId: map['userId'],
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      imageUrl: map['imageUrl'],
      actionUrl: map['actionUrl'],
    );
  }

  static NotificationType _parseNotificationType(dynamic value) {
    if (value == null) return NotificationType.general;
    
    switch (value.toString()) {
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

  static NotificationPriority _parseNotificationPriority(dynamic value) {
    if (value == null) return NotificationPriority.normal;
    
    switch (value.toString()) {
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

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'userId': userId,
      'data': data,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? createdAt,
    bool? isRead,
    String? userId,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      userId: userId ?? this.userId,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case NotificationType.accountActivated:
        return 'Cuenta Activada';
      case NotificationType.cardActivated:
        return 'Tarjeta Activada';
      case NotificationType.loanApproved:
        return 'Préstamo Aprobado';
      case NotificationType.loanRejected:
        return 'Préstamo Rechazado';
      case NotificationType.paymentReminder:
        return 'Recordatorio de Pago';
      case NotificationType.general:
        return 'General';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case NotificationPriority.low:
        return 'Baja';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'Alta';
      case NotificationPriority.urgent:
        return 'Urgente';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
}
*/