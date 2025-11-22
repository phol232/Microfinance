class UserAccount {
  const UserAccount({
    required this.id,
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

  final String id;
  final String email;
  final String? displayName;
  final String? phone;
  final String? passwordHash;
  final String? passwordSalt;
  final List<String> enabledProviders; // e.g. ['password', 'google']
  final String status; // 'active' | 'pending' | 'disabled'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final String? primaryMfId;
}
