/// Representa un usuario en la nueva estructura de la base de datos
/// Este usuario está asociado a una microfinanciera específica
class User {
  const User({
    required this.id,
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

  final String id; // Document ID
  final String userId; // ID del usuario global (Firebase Auth UID)
  final String microfinancieraId; // ID de la microfinanciera
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final List<String> linkedProviders; // ['password', 'google', 'facebook']
  final List<String> roles; // ['admin', 'worker', 'customer']
  final String status; // 'active', 'pending', 'disabled'
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  User copyWith({
    String? id,
    String? userId,
    String? microfinancieraId,
    String? email,
    String? displayName,
    String? photoUrl,
    List<String>? linkedProviders,
    List<String>? roles,
    String? status,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      microfinancieraId: microfinancieraId ?? this.microfinancieraId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      linkedProviders: linkedProviders ?? this.linkedProviders,
      roles: roles ?? this.roles,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  factory User.fromMap(String id, Map<String, dynamic> data) {
    return User(
      id: id,
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
      createdAt: _parseDate(data['createdAt']),
      lastLoginAt:
          data['lastLoginAt'] != null ? _parseDate(data['lastLoginAt']) : null,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
