import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? dni;
  final String? phone;
  final String? photoUrl;
  final String? photoBase64;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? microfinancieraId;
  final String? membershipId;
  final String? customerId;
  final DateTime? lastLoginAt;
  final String? status;
  final String? primaryRoleId;
  final List<String> roles;

  UserProfile({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.dni,
    this.phone,
    this.photoUrl,
    this.photoBase64,
    this.createdAt,
    this.updatedAt,
    this.microfinancieraId,
    this.membershipId,
    this.customerId,
    this.lastLoginAt,
    this.status = 'pending',
    this.primaryRoleId,
    this.roles = const [],
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String documentId) {
    var firstName = _parseStringField(map['firstName']);
    var lastName = _parseStringField(map['lastName']);
    final fullName = _parseStringField(map['fullName']);

    if (firstName.isEmpty && lastName.isEmpty && fullName.isNotEmpty) {
      final parts = fullName.trim().split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        firstName = parts.first;
      }
      if (parts.length > 1) {
        lastName = parts.sublist(1).join(' ');
      }
    }

    return UserProfile(
      uid: documentId,
      email: _parseStringField(map['email']),
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      dni:
          _parseOptionalStringField(map['dni']) ??
          _parseOptionalStringField(map['docNumber']),
      phone: _parseOptionalStringField(map['phone']),
      photoUrl: _parseOptionalStringField(map['photoUrl']),
      photoBase64: _parseOptionalStringField(map['photoBase64']) ??
          _parseOptionalStringField(map['fotoBase64']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      microfinancieraId: _parseOptionalStringField(map['microfinancieraId']),
      membershipId: _parseOptionalStringField(map['membershipId']),
      customerId: _parseOptionalStringField(map['customerId']),
      lastLoginAt: _parseTimestamp(map['lastLoginAt']),
      status: _parseOptionalStringField(map['status']) ?? 'pending',
      primaryRoleId: _parseOptionalStringField(map['primaryRoleId']),
      roles: _parseRolesList(map['roles']),
    );
  }

  static String _parseStringField(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return '';
  }

  static String? _parseOptionalStringField(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return null;
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    try {

      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      if (timestamp is DateTime) {
        return timestamp;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static List<String> _parseRolesList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .where((item) => item is String)
          .map((item) => item as String)
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'dni': dni,
      'phone': phone,
      'photoUrl': photoUrl,
      'photoBase64': photoBase64,
      'fotoBase64': photoBase64,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'microfinancieraId': microfinancieraId,
      'membershipId': membershipId,
      'customerId': customerId,
      'lastLoginAt': lastLoginAt,
      'status': status,
      'primaryRoleId': primaryRoleId,
      'roles': roles,
    };
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? fullName,
    String? dni,
    String? phone,
    String? photoUrl,
    String? photoBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? microfinancieraId,
    String? membershipId,
    String? customerId,
    DateTime? lastLoginAt,
    String? status,
    String? primaryRoleId,
    List<String>? roles,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      dni: dni ?? this.dni,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      photoBase64: photoBase64 ?? this.photoBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      microfinancieraId: microfinancieraId ?? this.microfinancieraId,
      membershipId: membershipId ?? this.membershipId,
      customerId: customerId ?? this.customerId,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      status: status ?? this.status,
      primaryRoleId: primaryRoleId ?? this.primaryRoleId,
      roles: roles ?? this.roles,
    );
  }
}
