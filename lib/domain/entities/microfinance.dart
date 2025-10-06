import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Microfinance.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Microfinance(
      id: doc.id,
      name: data['name'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt:
          data['updatedAt'] != null ? _parseTimestamp(data['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
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

  factory MicrofinanceRole.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return MicrofinanceRole(
      id: doc.id,
      name: data['name'] ?? '',
      isAssignable: data['isAssignable'] ?? true,
      createdAt: _parseTimestamp(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'isAssignable': isAssignable,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
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
  final GeoPoint? geo;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory Branch.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Branch(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      code: data['code'] ?? '',
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      geo: data['geo'] as GeoPoint?,
      isActive: data['isActive'] ?? true,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt:
          data['updatedAt'] != null ? _parseTimestamp(data['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mfId': mfId,
      'code': code,
      'name': name,
      'address': address,
      if (geo != null) 'geo': geo,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
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

  factory Worker.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Worker(
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
      updatedAt:
          data['updatedAt'] != null ? _parseTimestamp(data['updatedAt']) : null,
    );
  }

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

  factory PortalUserMetadata.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return PortalUserMetadata(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      userId: data['userId'] ?? '',
      email: data['email'],
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      linkedProviders: data['linkedProviders'] != null
          ? List<String>.from((data['linkedProviders'] as Iterable))
          : const <String>[],
      roles: data['roles'] != null
          ? List<String>.from((data['roles'] as Iterable))
          : const <String>['usuario'],
      status: data['status'] ?? 'active',
      createdAt: _parseTimestamp(data['createdAt']),
      lastLoginAt:
          data['lastLoginAt'] != null ? _parseTimestamp(data['lastLoginAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mfId': mfId,
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'linkedProviders': linkedProviders,
      'roles': roles,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastLoginAt != null) 'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
    };
  }
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

  factory FileMetadata.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return FileMetadata(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      ownerType: data['ownerType'] ?? '',
      ownerId: data['ownerId'] ?? '',
      kind: data['kind'] ?? '',
      storagePath: data['storagePath'] ?? '',
      size: data['size'] ?? 0,
      mime: data['mime'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedAt: _parseTimestamp(data['uploadedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mfId': mfId,
      'ownerType': ownerType,
      'ownerId': ownerId,
      'kind': kind,
      'storagePath': storagePath,
      'size': size,
      'mime': mime,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }
}

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.mfId,
    required this.actorUserId,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    required this.at,
    this.before,
    this.after,
  });

  final String id;
  final String mfId;
  final String actorUserId;
  final String action;
  final String resourceType;
  final String resourceId;
  final DateTime at;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;

  factory AuditLogEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return AuditLogEntry(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      actorUserId: data['actorUserId'] ?? '',
      action: data['action'] ?? '',
      resourceType: data['resourceType'] ?? '',
      resourceId: data['resourceId'] ?? '',
      at: _parseTimestamp(data['at']),
      before: data['before'] != null
          ? Map<String, dynamic>.from(data['before'] as Map)
          : null,
      after: data['after'] != null
          ? Map<String, dynamic>.from(data['after'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mfId': mfId,
      'actorUserId': actorUserId,
      'action': action,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'at': Timestamp.fromDate(at),
      if (before != null) 'before': before,
      if (after != null) 'after': after,
    };
  }
}

class RequestTicket {
  const RequestTicket({
    required this.id,
    required this.mfId,
    required this.type,
    required this.title,
    required this.description,
    required this.channel,
    required this.priority,
    required this.status,
    required this.requesterUserId,
    this.customerId,
    this.assignedUserId,
    this.assignedBranchId,
    this.acceptedAt,
    this.resolvedAt,
    this.slaDueAt,
    this.requesterDisplayName,
    this.customerName,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
  });

  final String id;
  final String mfId;
  final String type;
  final String title;
  final String description;
  final String channel;
  final String priority;
  final String status;
  final String requesterUserId;
  final String? customerId;
  final String? assignedUserId;
  final String? assignedBranchId;
  final DateTime? acceptedAt;
  final DateTime? resolvedAt;
  final DateTime? slaDueAt;
  final String? requesterDisplayName;
  final String? customerName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  factory RequestTicket.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return RequestTicket(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      channel: data['channel'] ?? 'web',
      priority: data['priority'] ?? 'normal',
      status: data['status'] ?? 'submitted',
      requesterUserId: data['requesterUserId'] ?? '',
      customerId: data['customerId'],
      assignedUserId: data['assignedUserId'],
      assignedBranchId: data['assignedBranchId'],
      acceptedAt:
          data['acceptedAt'] != null ? _parseTimestamp(data['acceptedAt']) : null,
      resolvedAt:
          data['resolvedAt'] != null ? _parseTimestamp(data['resolvedAt']) : null,
      slaDueAt:
          data['slaDueAt'] != null ? _parseTimestamp(data['slaDueAt']) : null,
      requesterDisplayName: data['requesterDisplayName'],
      customerName: data['customerName'],
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      tags: data['tags'] != null
          ? List<String>.from((data['tags'] as Iterable))
          : const <String>[],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mfId': mfId,
      'type': type,
      'title': title,
      'description': description,
      'channel': channel,
      'priority': priority,
      'status': status,
      'requesterUserId': requesterUserId,
      'customerId': customerId,
      'assignedUserId': assignedUserId,
      'assignedBranchId': assignedBranchId,
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
      if (slaDueAt != null) 'slaDueAt': Timestamp.fromDate(slaDueAt!),
      'requesterDisplayName': requesterDisplayName,
      'customerName': customerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
    };
  }
}

class RequestTimelineEvent {
  const RequestTimelineEvent({
    required this.id,
    required this.at,
    required this.actorUserId,
    required this.action,
    this.fromStatus,
    this.toStatus,
    this.note,
    this.attachments,
  });

  final String id;
  final DateTime at;
  final String actorUserId;
  final String action;
  final String? fromStatus;
  final String? toStatus;
  final String? note;
  final List<String>? attachments;

  factory RequestTimelineEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return RequestTimelineEvent(
      id: doc.id,
      at: _parseTimestamp(data['at']),
      actorUserId: data['actorUserId'] ?? '',
      action: data['action'] ?? '',
      fromStatus: data['fromStatus'],
      toStatus: data['toStatus'],
      note: data['note'],
      attachments: data['attachments'] != null
          ? List<String>.from((data['attachments'] as Iterable))
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'at': Timestamp.fromDate(at),
      'actorUserId': actorUserId,
      'action': action,
      'fromStatus': fromStatus,
      'toStatus': toStatus,
      'note': note,
      if (attachments != null) 'attachments': attachments,
    };
  }
}

class EmailLogEntry {
  const EmailLogEntry({
    required this.id,
    required this.mfId,
    required this.to,
    this.cc,
    required this.subject,
    this.template,
    this.payload,
    this.relatedType,
    this.relatedId,
    required this.status,
    this.providerMessageId,
    this.error,
    required this.createdAt,
    this.sentAt,
  });

  final String id;
  final String mfId;
  final String to;
  final List<String>? cc;
  final String subject;
  final String? template;
  final Map<String, dynamic>? payload;
  final String? relatedType;
  final String? relatedId;
  final String status; // "queued" | "sent" | "failed"
  final String? providerMessageId;
  final String? error;
  final DateTime createdAt;
  final DateTime? sentAt;

  factory EmailLogEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return EmailLogEntry(
      id: doc.id,
      mfId: data['mfId'] ?? '',
      to: data['to'] ?? '',
      cc: data['cc'] != null
          ? List<String>.from((data['cc'] as Iterable))
          : null,
      subject: data['subject'] ?? '',
      template: data['template'],
      payload: data['payload'] != null
          ? Map<String, dynamic>.from(data['payload'] as Map)
          : null,
      relatedType: data['relatedType'],
      relatedId: data['relatedId'],
      status: data['status'] ?? 'queued',
      providerMessageId: data['providerMessageId'],
      error: data['error'],
      createdAt: _parseTimestamp(data['createdAt']),
      sentAt: data['sentAt'] != null ? _parseTimestamp(data['sentAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mfId': mfId,
      'to': to,
      if (cc != null) 'cc': cc,
      'subject': subject,
      'template': template,
      'payload': payload,
      'relatedType': relatedType,
      'relatedId': relatedId,
      'status': status,
      'providerMessageId': providerMessageId,
      'error': error,
      'createdAt': Timestamp.fromDate(createdAt),
      if (sentAt != null) 'sentAt': Timestamp.fromDate(sentAt!),
    };
  }
}

class CounterShard {
  const CounterShard({
    required this.id,
    required this.value,
  });

  final String id;
  final int value;

  factory CounterShard.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CounterShard(
      id: doc.id,
      value: data['value'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'value': value,
    };
  }
}

DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.fromMillisecondsSinceEpoch(0);
}
