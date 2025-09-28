import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPublic {
  final String id;
  final String loanId;
  final String customerName;
  final DateTime nextDueAt;
  final int nextDueAmountCents;
  final int arrearsDays;
  final String status;
  final DateTime updatedAt;

  DashboardPublic({
    required this.id,
    required this.loanId,
    required this.customerName,
    required this.nextDueAt,
    required this.nextDueAmountCents,
    required this.arrearsDays,
    required this.status,
    required this.updatedAt,
  });

  factory DashboardPublic.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return DashboardPublic(
      id: doc.id,
      loanId: data['loanId'] ?? '',
      customerName: data['customerName'] ?? '',
      nextDueAt: (data['nextDueAt'] as Timestamp).toDate(),
      nextDueAmountCents: data['nextDueAmountCents'] ?? 0,
      arrearsDays: data['arrearsDays'] ?? 0,
      status: data['status'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'loanId': loanId,
      'customerName': customerName,
      'nextDueAt': Timestamp.fromDate(nextDueAt),
      'nextDueAmountCents': nextDueAmountCents,
      'arrearsDays': arrearsDays,
      'status': status,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class OutboxMessage {
  final String id;
  final String channel; // "sms"|"email"
  final String to;
  final String template; // "APPROVED"|"REJECTED"|"PENDING"|...
  final Map<String, dynamic> params;
  final String status; // "queued"|"sent"|"error"
  final DateTime createdAt;
  final DateTime? sentAt;
  final String? error;

  OutboxMessage({
    required this.id,
    required this.channel,
    required this.to,
    required this.template,
    required this.params,
    required this.status,
    required this.createdAt,
    this.sentAt,
    this.error,
  });

  factory OutboxMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return OutboxMessage(
      id: doc.id,
      channel: data['channel'] ?? '',
      to: data['to'] ?? '',
      template: data['template'] ?? '',
      params: Map<String, dynamic>.from(data['params'] ?? {}),
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      sentAt: data['sentAt'] != null
          ? (data['sentAt'] as Timestamp).toDate()
          : null,
      error: data['error'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'channel': channel,
      'to': to,
      'template': template,
      'params': params,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (sentAt != null) 'sentAt': Timestamp.fromDate(sentAt!),
      if (error != null) 'error': error,
    };
  }
}

class AuditLog {
  final String id;
  final ActorInfo actor;
  final String action;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final DateTime at;
  final String? ip;
  final String? device;

  AuditLog({
    required this.id,
    required this.actor,
    required this.action,
    this.before,
    this.after,
    required this.at,
    this.ip,
    this.device,
  });

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return AuditLog(
      id: doc.id,
      actor: ActorInfo.fromMap(data['actor'] ?? {}),
      action: data['action'] ?? '',
      before: data['before'] != null
          ? Map<String, dynamic>.from(data['before'])
          : null,
      after: data['after'] != null
          ? Map<String, dynamic>.from(data['after'])
          : null,
      at: (data['at'] as Timestamp).toDate(),
      ip: data['ip'],
      device: data['device'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'actor': actor.toMap(),
      'action': action,
      if (before != null) 'before': before,
      if (after != null) 'after': after,
      'at': Timestamp.fromDate(at),
      if (ip != null) 'ip': ip,
      if (device != null) 'device': device,
    };
  }
}

class ActorInfo {
  final String uid;
  final String role;

  ActorInfo({required this.uid, required this.role});

  factory ActorInfo.fromMap(Map<String, dynamic> map) {
    return ActorInfo(uid: map['uid'] ?? '', role: map['role'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'role': role};
  }
}
