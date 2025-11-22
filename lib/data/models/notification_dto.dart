import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notification.dart';

class NotificationDto {
  const NotificationDto({
    this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.readAt,
    this.metadata,
  });

  final String? id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  factory NotificationDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return NotificationDto(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      createdAt: _parseTimestamp(data['createdAt']),
      readAt: data['readAt'] != null ? _parseTimestamp(data['readAt']) : null,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  factory NotificationDto.fromDomain(NotificationEntity entity) {
    return NotificationDto(
      id: entity.id.isEmpty ? null : entity.id,
      userId: entity.userId,
      title: entity.title,
      body: entity.body,
      type: entity.type,
      createdAt: entity.createdAt,
      readAt: entity.readAt,
      metadata: entity.metadata,
    );
  }

  NotificationEntity toDomain() {
    return NotificationEntity(
      id: id ?? '',
      userId: userId,
      title: title,
      body: body,
      type: type,
      createdAt: createdAt,
      readAt: readAt,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      if (readAt != null) 'readAt': Timestamp.fromDate(readAt!),
      if (metadata != null) 'metadata': metadata,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
