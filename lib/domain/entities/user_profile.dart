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
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String documentId) {
    return UserProfile(
      uid: documentId,
      email: _parseStringField(map['email']),
      firstName: _parseStringField(map['firstName']),
      lastName: _parseStringField(map['lastName']),
      fullName: _parseStringField(map['fullName']),
      dni: _parseOptionalStringField(map['dni']),
      phone: _parseOptionalStringField(map['phone']),
      photoUrl: _parseOptionalStringField(map['photoUrl']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
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
    );
  }
}
