import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/dashboard_outbox_audit.dart';

class DashboardPublicDto {
  const DashboardPublicDto({
    this.id,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  final String? id;
  final String title;
  final String description;
  final DateTime createdAt;

  factory DashboardPublicDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return DashboardPublicDto(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  DashboardPublic toDomain() => DashboardPublic(
        id: id ?? '',
        title: title,
        description: description,
        createdAt: createdAt,
      );
}

class OutboxMessageDto {
  const OutboxMessageDto({
    this.id,
    required this.type,
    required this.payload,
    required this.status,
    required this.createdAt,
  });

  final String? id;
  final String type;
  final Map<String, dynamic> payload;
  final String status;
  final DateTime createdAt;

  factory OutboxMessageDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return OutboxMessageDto(
      id: doc.id,
      type: data['type'] ?? '',
      payload: Map<String, dynamic>.from(data['payload'] ?? <String, dynamic>{}),
      status: data['status'] ?? 'pending',
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  OutboxMessage toDomain() => OutboxMessage(
        id: id ?? '',
        type: type,
        payload: payload,
        status: status,
        createdAt: createdAt,
      );
}

class AuditLogDto {
  const AuditLogDto({
    this.id,
    required this.action,
    required this.userId,
    required this.details,
    required this.createdAt,
  });

  final String? id;
  final String action;
  final String userId;
  final Map<String, dynamic> details;
  final DateTime createdAt;

  factory AuditLogDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return AuditLogDto(
      id: doc.id,
      action: data['action'] ?? '',
      userId: data['userId'] ?? '',
      details: Map<String, dynamic>.from(data['details'] ?? <String, dynamic>{}),
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  AuditLog toDomain() => AuditLog(
        id: id ?? '',
        action: action,
        userId: userId,
        details: details,
        createdAt: createdAt,
      );
}

DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.fromMillisecondsSinceEpoch(0);
}
