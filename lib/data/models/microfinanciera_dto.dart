import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/microfinanciera.dart';

class MicrofinancieraDto {
  const MicrofinancieraDto({
    this.id,
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

  final String? id;
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

  factory MicrofinancieraDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return MicrofinancieraDto(
      id: doc.id,
      name: data['name'] ?? '',
      legalName: data['legalName'] ?? '',
      ruc: data['ruc'],
      address: data['address'],
      phone: data['phone'],
      email: data['email'],
      website: data['website'],
      logoUrl: data['logoUrl'],
      isActive: data['isActive'] ?? true,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt:
          data['updatedAt'] != null ? _parseTimestamp(data['updatedAt']) : null,
      settings: data['settings'] != null
          ? Map<String, dynamic>.from(data['settings'])
          : null,
    );
  }

  factory MicrofinancieraDto.fromDomain(Microfinanciera entity) {
    return MicrofinancieraDto(
      id: entity.id.isEmpty ? null : entity.id,
      name: entity.name,
      legalName: entity.legalName,
      ruc: entity.ruc,
      address: entity.address,
      phone: entity.phone,
      email: entity.email,
      website: entity.website,
      logoUrl: entity.logoUrl,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      settings: entity.settings,
    );
  }

  Microfinanciera toDomain() {
    return Microfinanciera(
      id: id ?? '',
      name: name,
      legalName: legalName,
      ruc: ruc,
      address: address,
      phone: phone,
      email: email,
      website: website,
      logoUrl: logoUrl,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      settings: settings,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'legalName': legalName,
      if (ruc != null) 'ruc': ruc,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (website != null) 'website': website,
      if (logoUrl != null) 'logoUrl': logoUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (settings != null) 'settings': settings,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
