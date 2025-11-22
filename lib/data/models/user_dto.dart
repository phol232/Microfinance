import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user.dart';

/// DTO para aislar el mapeo de usuarios en Firestore.
class UserDto {
  const UserDto({
    this.id,
    required this.userId,
    required this.microfinancieraId,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.linkedProviders,
    required this.roles,
    required this.status,
    required this.createdAt,
    this.lastLoginAt,
  });

  final String? id;
  final String userId;
  final String microfinancieraId;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final List<String> linkedProviders;
  final List<String> roles;
  final String status;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  factory UserDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserDto(
      id: doc.id,
      userId: data['userId'] ?? '',
      microfinancieraId: data['mfId'] ?? '',
      email: data['email'],
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      linkedProviders: data['linkedProviders'] != null
          ? List<String>.from((data['linkedProviders'] as Iterable))
          : const <String>[],
      roles: data['roles'] != null
          ? List<String>.from((data['roles'] as Iterable))
          : const <String>[],
      status: data['status'] ?? 'pending',
      createdAt: _parseTimestamp(data['createdAt']),
      lastLoginAt: data['lastLoginAt'] != null
          ? _parseTimestamp(data['lastLoginAt'])
          : null,
    );
  }

  factory UserDto.fromDomain(User user) {
    return UserDto(
      id: user.id,
      userId: user.userId,
      microfinancieraId: user.microfinancieraId,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      linkedProviders: user.linkedProviders,
      roles: user.roles,
      status: user.status,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    );
  }

  User toDomain() {
    return User(
      id: id ?? '',
      userId: userId,
      microfinancieraId: microfinancieraId,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      linkedProviders: linkedProviders,
      roles: roles,
      status: status,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mfId': microfinancieraId,
      if (email != null) 'email': email,
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'linkedProviders': linkedProviders,
      'roles': roles,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastLoginAt != null) 'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
