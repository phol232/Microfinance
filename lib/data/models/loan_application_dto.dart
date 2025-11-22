import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/loan_application.dart';

class LoanApplicationDto {
  const LoanApplicationDto(this.application);

  final LoanApplication application;

  factory LoanApplicationDto.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return LoanApplicationDto(
      LoanApplication.fromMap(doc.id, data),
    );
  }

  LoanApplication toDomain() => application;

  Map<String, dynamic> toFirestore() {
    final map = application.toMap();
    return map.map((key, value) {
      if (value is DateTime) {
        return MapEntry(key, Timestamp.fromDate(value));
      }
      if (value is Map<String, dynamic>) {
        return MapEntry(key, _convertDates(value));
      }
      if (value is List) {
        return MapEntry(
          key,
          value.map((e) => e is Map<String, dynamic> ? _convertDates(e) : e).toList(),
        );
      }
      return MapEntry(key, value);
    });
  }

  Map<String, dynamic> _convertDates(Map<String, dynamic> source) {
    return source.map((key, value) {
      if (value is DateTime) {
        return MapEntry(key, Timestamp.fromDate(value));
      }
      if (value is Map<String, dynamic>) {
        return MapEntry(key, _convertDates(value));
      }
      if (value is List) {
        return MapEntry(
          key,
          value.map((e) => e is Map<String, dynamic> ? _convertDates(e) : e).toList(),
        );
      }
      return MapEntry(key, value);
    });
  }
}
