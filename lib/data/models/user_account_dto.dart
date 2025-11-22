import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_account.dart';

class UserAccountDto {
  const UserAccountDto({
    this.id,
    required this.email,
    this.displayName,
    this.phone,
    this.passwordHash,
    this.passwordSalt,
    required this.enabledProviders,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.primaryMfId,
  });

  final String? id;
  final String email;
  final String? displayName;
  final String? phone;
  final String? passwordHash;
  final String? passwordSalt;
  final List<String> enabledProviders;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final String? primaryMfId;

  factory UserAccountDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserAccountDto(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      phone: data['phone'],
      passwordHash: data['passwordHash'],
      passwordSalt: data['passwordSalt'],
      enabledProviders: data['enabledProviders'] != null
          ? List<String>.from((data['enabledProviders'] as Iterable))
          : const <String>['password'],
      status: data['status'] ?? 'pending',
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt:
          data['updatedAt'] != null ? _parseTimestamp(data['updatedAt']) : null,
      lastLoginAt: data['lastLoginAt'] != null
          ? _parseTimestamp(data['lastLoginAt'])
          : null,
      primaryMfId: data['primaryMfId'],
    );
  }

  factory UserAccountDto.fromDomain(UserAccount account) {
    return UserAccountDto(
      id: account.id.isEmpty ? null : account.id,
      email: account.email,
      displayName: account.displayName,
      phone: account.phone,
      passwordHash: account.passwordHash,
      passwordSalt: account.passwordSalt,
      enabledProviders: account.enabledProviders,
      status: account.status,
      createdAt: account.createdAt,
      updatedAt: account.updatedAt,
      lastLoginAt: account.lastLoginAt,
      primaryMfId: account.primaryMfId,
    );
  }

  UserAccount toDomain() {
    return UserAccount(
      id: id ?? '',
      email: email,
      displayName: displayName,
      phone: phone,
      passwordHash: passwordHash,
      passwordSalt: passwordSalt,
      enabledProviders: enabledProviders,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
      primaryMfId: primaryMfId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      if (displayName != null) 'displayName': displayName,
      if (phone != null) 'phone': phone,
      if (passwordHash != null) 'passwordHash': passwordHash,
      if (passwordSalt != null) 'passwordSalt': passwordSalt,
      'enabledProviders': enabledProviders,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (lastLoginAt != null) 'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
      if (primaryMfId != null) 'primaryMfId': primaryMfId,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
