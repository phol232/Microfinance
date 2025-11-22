/// Modelos de dominio para microfinancieras y artefactos relacionados.
/// Notar que el mapeo a Firestore se realiza en los DTOs de data/models.

class Microfinance {
  const Microfinance({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String status; // "active" | "suspended"
  final DateTime createdAt;
  final DateTime? updatedAt;
}

class MicrofinanceRole {
  const MicrofinanceRole({
    required this.id,
    required this.name,
    required this.isAssignable,
    required this.createdAt,
  });

  final String id;
  final String name;
  final bool isAssignable;
  final DateTime createdAt;
}

class Branch {
  const Branch({
    required this.id,
    required this.mfId,
    required this.code,
    required this.name,
    required this.address,
    this.geo,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String mfId;
  final String code;
  final String name;
  final String address;
  final Map<String, dynamic>? geo;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
}

class Worker {
  const Worker({
    required this.id,
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

  final String id;
  final String mfId;
  final String userId;
  final String branchId;
  final String displayName;
  final String phone;
  final List<String> roleIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
}

class PortalUserMetadata {
  const PortalUserMetadata({
    required this.id,
    required this.mfId,
    required this.userId,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.linkedProviders,
    required this.roles,
    required this.status,
    required this.createdAt,
    this.lastLoginAt,
  });

  final String id;
  final String mfId;
  final String userId;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final List<String> linkedProviders;
  final List<String> roles;
  final String status; // "active" | "disabled"
  final DateTime createdAt;
  final DateTime? lastLoginAt;
}

class FileMetadata {
  const FileMetadata({
    required this.id,
    required this.mfId,
    required this.ownerType,
    required this.ownerId,
    required this.kind,
    required this.storagePath,
    required this.size,
    required this.mime,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  final String id;
  final String mfId;
  final String ownerType;
  final String ownerId;
  final String kind;
  final String storagePath;
  final int size;
  final String mime;
  final String uploadedBy;
  final DateTime uploadedAt;
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.userId,
    required this.action,
    required this.details,
    required this.at,
  });

  final String id;
  final String userId;
  final String action;
  final Map<String, dynamic> details;
  final DateTime at;
}

class RequestTicket {
  const RequestTicket({
    required this.id,
    required this.type,
    required this.status,
    required this.requesterId,
    required this.createdAt,
    this.assignedTo,
    this.updatedAt,
    this.resolvedAt,
    this.acceptedAt,
    this.slaDueAt,
    this.payload,
  });

  final String id;
  final String type;
  final String status;
  final String requesterId;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final DateTime? acceptedAt;
  final DateTime? slaDueAt;
  final Map<String, dynamic>? payload;
}

class RequestTimelineEvent {
  const RequestTimelineEvent({
    required this.id,
    required this.requestId,
    required this.event,
    required this.createdAt,
    this.createdBy,
    this.metadata,
  });

  final String id;
  final String requestId;
  final String event;
  final DateTime createdAt;
  final String? createdBy;
  final Map<String, dynamic>? metadata;
}

class EmailLogEntry {
  const EmailLogEntry({
    required this.id,
    required this.templateId,
    required this.to,
    this.subject,
    this.payload,
    required this.status,
    required this.createdAt,
    this.sentAt,
  });

  final String id;
  final String templateId;
  final String to;
  final String? subject;
  final Map<String, dynamic>? payload;
  final String status;
  final DateTime createdAt;
  final DateTime? sentAt;
}
