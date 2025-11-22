import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/microfinance.dart';

class MicrofinanceDto {
  const MicrofinanceDto({
    this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String name;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory MicrofinanceDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return MicrofinanceDto(
      id: doc.id,
      name: data['name'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: data['updatedAt'] != null
          ? _parseTimestamp(data['updatedAt'])
          : null,
    );
  }

  factory MicrofinanceDto.fromDomain(Microfinance mf) {
    return MicrofinanceDto(
      id: mf.id.isEmpty ? null : mf.id,
      name: mf.name,
      status: mf.status,
      createdAt: mf.createdAt,
      updatedAt: mf.updatedAt,
    );
  }

  Microfinance toDomain() => Microfinance(
    id: id ?? '',
    name: name,
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

class MicrofinanceRoleDto {
  const MicrofinanceRoleDto({
    this.id,
    required this.name,
    required this.isAssignable,
    required this.createdAt,
  });

  final String? id;
  final String name;
  final bool isAssignable;
  final DateTime createdAt;

  factory MicrofinanceRoleDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return MicrofinanceRoleDto(
      id: doc.id,
      name: data['name'] ?? '',
      isAssignable: data['isAssignable'] ?? true,
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  MicrofinanceRole toDomain() => MicrofinanceRole(
    id: id ?? '',
    name: name,
    isAssignable: isAssignable,
    createdAt: createdAt,
  );
}

class BranchDto {
  const BranchDto({
    this.id,
    required this.mfId,
    required this.code,
    required this.name,
    required this.address,
    this.geo,
    required this.isActive,
    required this.createdAt,
  });

  final String? id;
  final String mfId;
  final String code;
  final String name;
  final String address;
  final Map<String, dynamic>? geo;
  final bool isActive;
  final DateTime createdAt;

  factory BranchDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BranchDto(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      geo: data['geo'] != null ? Map<String, dynamic>.from(data['geo']) : null,
      isActive: data['isActive'] ?? true,
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  Branch toDomain() => Branch(
    id: id ?? '',
    mfId: mfId,
    code: code,
    name: name,
    address: address,
    geo: geo,
    isActive: isActive,
    createdAt: createdAt,
  );
}

class WorkerDto {
  const WorkerDto({
    this.id,
    required this.mfId,
    required this.userId,
    required this.branchId,
    required this.displayName,
    required this.phone,
    required this.roleIds,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String mfId;
  final String userId;
  final String branchId;
  final String displayName;
  final String phone;
  final List<String> roleIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory WorkerDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return WorkerDto(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      userId: data['userId'] ?? '',
      branchId: data['branchId'] ?? '',
      displayName: data['displayName'] ?? '',
      phone: data['phone'] ?? '',
      roleIds: data['roleIds'] != null
          ? List<String>.from((data['roleIds'] as Iterable))
          : const <String>[],
      isActive: data['isActive'] ?? true,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: data['updatedAt'] != null
          ? _parseTimestamp(data['updatedAt'])
          : null,
    );
  }

  Worker toDomain() => Worker(
    id: id ?? '',
    mfId: mfId,
    userId: userId,
    branchId: branchId,
    displayName: displayName,
    phone: phone,
    roleIds: roleIds,
    isActive: isActive,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  Map<String, dynamic> toFirestore() {
    return {
      'mfId': mfId,
      'userId': userId,
      'branchId': branchId,
      'displayName': displayName,
      'phone': phone,
      'roleIds': roleIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.fromMillisecondsSinceEpoch(0);
}
