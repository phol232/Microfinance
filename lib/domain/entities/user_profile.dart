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

  // Helper method to safely parse string fields
  static String _parseStringField(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    // Si es un FieldValue u otro tipo, devolver string vacío
    return '';
  }

  // Helper method to safely parse optional string fields
  static String? _parseOptionalStringField(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    // Si es un FieldValue u otro tipo, devolver null
    return null;
  }

  // Helper method to safely parse Firestore timestamps
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    try {
      // Si es un Timestamp de Firestore, convertirlo a DateTime
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      // Si ya es un DateTime, devolverlo tal como está
      if (timestamp is DateTime) {
        return timestamp;
      }
      // Si es un FieldValue (durante escritura), devolver null temporalmente
      return null;
    } catch (e) {
      // En caso de cualquier error, devolver null
      return null;
    }
  }

  // Helper method to safely parse roles list
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
