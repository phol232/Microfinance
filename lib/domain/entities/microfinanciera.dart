/// Representa una microfinanciera en el sistema
class Microfinanciera {
  const Microfinanciera({
    required this.id,
    required this.name,
    required this.legalName,
    this.ruc,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.logoUrl,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.settings,
  });

  final String id;
  final String name;
  final String legalName;
  final String? ruc;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? logoUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? settings;
}
