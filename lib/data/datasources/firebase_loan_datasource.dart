import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/loan.dart';
import '../models/loan_dto.dart';

class FirebaseLoanDataSource {
  FirebaseLoanDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<Loan>> getCustomerLoans({
    required String microfinancieraId,
    required String customerId,
    String? status,
  }) async {
    try {
      var query = _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loans')
          .where('customerId', isEqualTo: customerId);

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs
          .map((doc) => LoanDto.fromFirestore(doc).toDomain())
          .toList();
    } catch (error, stackTrace) {
      _logError('getCustomerLoans', error, stackTrace);
      rethrow;
    }
  }

  Future<Loan?> getLoan({
    required String microfinancieraId,
    required String loanId,
  }) async {
    try {
      final doc = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loans')
          .doc(loanId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return LoanDto.fromFirestore(doc).toDomain();
    } catch (error, stackTrace) {
      _logError('getLoan', error, stackTrace);
      rethrow;
    }
  }

  Stream<Loan?> watchLoan({
    required String microfinancieraId,
    required String loanId,
  }) {
    try {
      return _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loans')
          .doc(loanId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) {
              return null;
            }
            return LoanDto.fromFirestore(doc).toDomain();
          });
    } catch (error, stackTrace) {
      _logError('watchLoan', error, stackTrace);
      rethrow;
    }
  }

  Stream<List<Loan>> watchCustomerLoans({
    required String microfinancieraId,
    required String customerId,
    String? status,
  }) {
    try {
      var query = _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loans')
          .where('customerId', isEqualTo: customerId);

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      return query
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => LoanDto.fromFirestore(doc).toDomain())
                .toList(),
          );
    } catch (error, stackTrace) {
      _logError('watchCustomerLoans', error, stackTrace);
      rethrow;
    }
  }

  Future<List<LoanScheduleInstallment>> getLoanSchedule({
    required String microfinancieraId,
    required String loanId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loans')
          .doc(loanId)
          .collection('schedule')
          .orderBy('installmentNo')
          .get();

      return snapshot.docs
          .map(
            (doc) => LoanScheduleInstallmentDto.fromFirestore(doc).toDomain(),
          )
          .toList();
    } catch (error, stackTrace) {
      _logError('getLoanSchedule', error, stackTrace);
      rethrow;
    }
  }

  Stream<List<LoanScheduleInstallment>> watchLoanSchedule({
    required String microfinancieraId,
    required String loanId,
  }) {
    try {
      return _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loans')
          .doc(loanId)
          .collection('schedule')
          .orderBy('installmentNo')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) =>
                      LoanScheduleInstallmentDto.fromFirestore(doc).toDomain(),
                )
                .toList(),
          );
    } catch (error, stackTrace) {
      _logError('watchLoanSchedule', error, stackTrace);
      rethrow;
    }
  }

  Future<List<LoanRepayment>> getLoanRepayments({
    required String microfinancieraId,
    required String loanId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loans')
          .doc(loanId)
          .collection('repayments')
          .orderBy('paidAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LoanRepaymentDto.fromFirestore(doc).toDomain())
          .toList();
    } catch (error, stackTrace) {
      _logError('getLoanRepayments', error, stackTrace);
      rethrow;
    }
  }

  Stream<List<LoanRepayment>> watchLoanRepayments({
    required String microfinancieraId,
    required String loanId,
  }) {
    try {
      return _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loans')
          .doc(loanId)
          .collection('repayments')
          .orderBy('paidAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => LoanRepaymentDto.fromFirestore(doc).toDomain())
                .toList(),
          );
    } catch (error, stackTrace) {
      _logError('watchLoanRepayments', error, stackTrace);
      rethrow;
    }
  }

  Future<String> createLoan({
    required String microfinancieraId,
    required Loan loan,
  }) async {
    try {
      final dto = LoanDto.fromDomain(loan);
      final docRef = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loans')
          .add(dto.toFirestore());

      return docRef.id;
    } catch (error, stackTrace) {
      _logError('createLoan', error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateLoan({
    required String microfinancieraId,
    required String loanId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loans')
          .doc(loanId)
          .update({...updates, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (error, stackTrace) {
      _logError('updateLoan', error, stackTrace);
      rethrow;
    }
  }

  Future<String> createRepayment({
    required String microfinancieraId,
    required String loanId,
    required LoanRepayment repayment,
  }) async {
    try {
      final dto = LoanRepaymentDto.fromDomain(repayment);
      final docRef = await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loans')
          .doc(loanId)
          .collection('repayments')
          .add(dto.toFirestore());

      return docRef.id;
    } catch (error, stackTrace) {
      _logError('createRepayment', error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateLoanStatus({
    required String microfinancieraId,
    required String loanId,
    required String status,
  }) async {
    try {
      await _firestore
          .collection('microfinancieras')
          .doc(microfinancieraId)
          .collection('loans')
          .doc(loanId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (error, stackTrace) {
      _logError('updateLoanStatus', error, stackTrace);
      rethrow;
    }
  }

  void _logError(String method, Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'FirebaseLoanDataSource',
        context: ErrorDescription('Error en $method'),
      ),
    );
  }
}
