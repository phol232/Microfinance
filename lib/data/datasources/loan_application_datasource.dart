import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/loan_application.dart';

class LoanApplicationDataSource {
  final FirebaseFirestore _firestore;

  LoanApplicationDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Obtener todas las aplicaciones de una microfinanciera
  Future<List<LoanApplication>> getAllApplications(String microfinancieraId) async {
    try {
      final snapshot = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loanApplications')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LoanApplication.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo aplicaciones: $e');
    }
  }

  /// Obtener aplicaciones asignadas a un agente específico
  Future<List<LoanApplication>> getAssignedToAgent(
    String microfinancieraId,
    String agentId, {
    List<String>? statusFilter,
  }) async {
    try {
      Query query = _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loanApplications')
          .where('routing.agentId', isEqualTo: agentId)
          .orderBy('updatedAt', descending: true);

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.where('status', whereIn: statusFilter);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => LoanApplication.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo aplicaciones del agente: $e');
    }
  }

  /// Obtener aplicaciones por estado
  Future<List<LoanApplication>> getApplicationsByStatus(
    String microfinancieraId,
    List<String> statuses,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loanApplications')
          .where('status', whereIn: statuses)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => LoanApplication.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error obteniendo aplicaciones por estado: $e');
    }
  }

  /// Obtener aplicación específica por ID
  Future<LoanApplication?> getApplicationById(
    String microfinancieraId,
    String applicationId,
  ) async {
    try {
      final doc = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loanApplications')
          .doc(applicationId)
          .get();

      if (!doc.exists) return null;

      return LoanApplication.fromFirestore(doc);
    } catch (e) {
      throw Exception('Error obteniendo aplicación: $e');
    }
  }

  /// Tomar posesión de una aplicación
  Future<void> takeOwnership(
    String microfinancieraId,
    String applicationId,
    String agentId,
    String agentUserId,
  ) async {
    try {
      final batch = _firestore.batch();

      final appRef = _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loanApplications')
          .doc(applicationId);

      final transitionsRef = appRef.collection('transitions').doc();

      // Actualizar la aplicación
      batch.update(appRef, {
        'routing.agentId': agentId,
        'routing.assignedAt': FieldValue.serverTimestamp(),
        'status': 'in_review',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Registrar transición
      batch.set(transitionsRef, {
        'from': 'routed',
        'to': 'in_review',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': agentUserId,
        'reason': 'Agente tomó posesión del caso',
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Error tomando posesión: $e');
    }
  }

  /// Actualizar estado de aplicación
  Future<void> updateApplicationStatus(
    String microfinancieraId,
    String applicationId,
    String newStatus,
    String userId, {
    String? reason,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final batch = _firestore.batch();

      final appRef = _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loanApplications')
          .doc(applicationId);

      // Obtener estado actual
      final currentDoc = await appRef.get();
      if (!currentDoc.exists) {
        throw Exception('Aplicación no encontrada');
      }

      final currentStatus = currentDoc.data()?['status'] ?? '';

      // Actualizar aplicación
      final updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      batch.update(appRef, updateData);

      // Registrar transición
      if (currentStatus != newStatus) {
        final transitionsRef = appRef.collection('transitions').doc();
        batch.set(transitionsRef, {
          'from': currentStatus,
          'to': newStatus,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': userId,
          'reason': reason ?? 'Cambio de estado',
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error actualizando estado: $e');
    }
  }

  /// Stream de aplicaciones asignadas a un agente (tiempo real)
  Stream<List<LoanApplication>> watchAssignedApplications(
    String microfinancieraId,
    String agentId,
  ) {
    return _firestore
        .collection('microfinancieras')
        .doc(microfinancieraId)
        .collection('loanApplications')
        .where('routing.agentId', isEqualTo: agentId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LoanApplication.fromFirestore(doc))
            .toList());
  }

  /// Stream de aplicaciones por estado (tiempo real)
  Stream<List<LoanApplication>> watchApplicationsByStatus(
    String microfinancieraId,
    List<String> statuses,
  ) {
    return _firestore
        .collection('microfinancieras')
        .doc(microfinancieraId)
        .collection('loanApplications')
        .where('status', whereIn: statuses)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LoanApplication.fromFirestore(doc))
            .toList());
  }

  /// Obtener estadísticas básicas
  Future<Map<String, int>> getApplicationStats(String microfinancieraId) async {
    try {
      final statuses = ['received', 'routed', 'in_review', 'approved', 'rejected', 'disbursed'];
      final stats = <String, int>{};

      for (final status in statuses) {
        final snapshot = await _firestore
            .collection('microfinancieras')
            .doc(microfinancieraId)
            .collection('loanApplications')
            .where('status', isEqualTo: status)
            .get();

        stats[status] = snapshot.docs.length;
      }

      return stats;
    } catch (e) {
      throw Exception('Error obteniendo estadísticas: $e');
    }
  }

  /// Obtener estadísticas por agente
  Future<Map<String, int>> getAgentStats(
    String microfinancieraId,
    String agentId,
  ) async {
    try {
      final statuses = ['in_review', 'approved', 'rejected'];
      final stats = <String, int>{};

      for (final status in statuses) {
        final snapshot = await _firestore
            .collection('microfinancieras')
            .doc(microfinancieraId)
            .collection('loanApplications')
            .where('routing.agentId', isEqualTo: agentId)
            .where('status', isEqualTo: status)
            .get();

        stats[status] = snapshot.docs.length;
      }

      return stats;
    } catch (e) {
      throw Exception('Error obteniendo estadísticas del agente: $e');
    }
  }
}
