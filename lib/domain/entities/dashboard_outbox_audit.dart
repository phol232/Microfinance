/// Modelos de dominio para dashboard/outbox/audit sin dependencias externas.

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
}

class ActorInfo {
  final String uid;
  final String role;

  ActorInfo({required this.uid, required this.role});
}
