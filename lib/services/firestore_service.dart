import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio base para manejar operaciones multi-tenant en Firestore
class FirestoreService {
  static const String _tenantsCollection = 'tenants';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String tenantId;

  FirestoreService({required this.tenantId});

  /// Referencia base del tenant
  DocumentReference get tenantRef =>
      _firestore.collection(_tenantsCollection).doc(tenantId);

  /// Colecciones del tenant
  CollectionReference get intakeRequests =>
      tenantRef.collection('intake_requests');
  CollectionReference get applications => tenantRef.collection('applications');
  CollectionReference get customers => tenantRef.collection('customers');
  CollectionReference get products => tenantRef.collection('products');
  CollectionReference get loans => tenantRef.collection('loans');
  CollectionReference get transactions => tenantRef.collection('transactions');
  CollectionReference get branches => tenantRef.collection('branches');
  CollectionReference get agents => tenantRef.collection('agents');
  CollectionReference get mlScores => tenantRef.collection('ml_scores');
  CollectionReference get mlMetrics => tenantRef.collection('ml_metrics');
  CollectionReference get dashboardsPublic =>
      tenantRef.collection('dashboards_public');
  CollectionReference get outbox => tenantRef.collection('outbox');
  CollectionReference get auditLogs => tenantRef.collection('auditLogs');

  /// Subcolecciones para loans
  CollectionReference loanSchedule(String loanId) =>
      loans.doc(loanId).collection('schedule');
  CollectionReference loanRepayments(String loanId) =>
      loans.doc(loanId).collection('repayments');

  /// Subcolección para transaction entries
  CollectionReference transactionEntries(String transactionId) =>
      transactions.doc(transactionId).collection('entries');

  /// Métodos de utilidad
  Future<DocumentSnapshot> getTenant() => tenantRef.get();

  /// Batch operations
  WriteBatch batch() => _firestore.batch();

  /// Transaction operations
  Future<T> runTransaction<T>(TransactionHandler<T> updateFunction) =>
      _firestore.runTransaction(updateFunction);
}
