import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mobile/core/tenant/tenant_resolver.dart';
import '../../domain/entities/loan_application.dart';

class IntakeRequestDataSource {
  final FirebaseFirestore _firestore;
  final TenantResolver _tenantResolver;

  IntakeRequestDataSource({
    required TenantResolver tenantResolver,
    FirebaseFirestore? firestore,
  })  : _tenantResolver = tenantResolver,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('microfinancieras').doc(_requireTenantId()).collection(
            'loanApplications',
          );

  String _requireTenantId() {
    final tenantId = _tenantResolver.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw StateError(
        'Tenant not configured. Selecciona una microfinanciera antes de continuar.',
      );
    }
    return tenantId;
  }

  Future<List<LoanApplication>> getAll() async {
    try {
      final snapshot = await _collection.orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map((doc) {
            try {
              return LoanApplication.fromFirestore(doc);
            } catch (error, stackTrace) {
              developer.log(
                'Error al parsear documento ${doc.id}',
                name: 'IntakeRequestDataSource',
                error: error,
                stackTrace: stackTrace,
                level: 900,
              );
              return null;
            }
          })
          .whereType<LoanApplication>()
          .toList();
    } catch (error, stackTrace) {
      developer.log(
        'Error obteniendo solicitudes',
        name: 'IntakeRequestDataSource',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  Future<List<LoanApplication>> getByStatus(String status) async {
    final snapshot = await _collection
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => LoanApplication.fromFirestore(doc))
        .toList();
  }

  Future<List<LoanApplication>> getRecent({int limit = 10}) async {
    try {
      final snapshot = await _collection.orderBy('createdAt', descending: true).limit(limit).get();
      return snapshot.docs
          .map((doc) {
            try {
              return LoanApplication.fromFirestore(doc);
            } catch (error, stackTrace) {
              developer.log(
                'Error al parsear documento ${doc.id}',
                name: 'IntakeRequestDataSource',
                error: error,
                stackTrace: stackTrace,
                level: 900,
              );
              return null;
            }
          })
          .whereType<LoanApplication>()
          .toList();
    } catch (error, stackTrace) {
      developer.log(
        'Error obteniendo solicitudes recientes',
        name: 'IntakeRequestDataSource',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }

  Future<LoanApplication?> getById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return null;
      return LoanApplication.fromFirestore(doc);
    } catch (error, stackTrace) {
      developer.log(
        'Error obteniendo solicitud $id',
        name: 'IntakeRequestDataSource',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      return null;
    }
  }

  Stream<List<LoanApplication>> watchAll() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LoanApplication.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<LoanApplication>> watchByStatus(String status) {
    return _collection
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LoanApplication.fromFirestore(doc))
              .toList(),
        );
  }

  Future<Map<String, int>> getStatusCounts() async {
    final snapshot = await _collection.get();
    final counts = <String, int>{};

    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] as String? ?? 'unknown';
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }

  Future<void> updateStatus(String applicationId, String newStatus) async {
    try {
      await _collection.doc(applicationId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      developer.log(
        'Estado actualizado: $applicationId -> $newStatus',
        name: 'IntakeRequestDataSource',
        level: 800,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Error actualizando estado de $applicationId',
        name: 'IntakeRequestDataSource',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      rethrow;
    }
  }
}
