import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreditProduct {
  final String id;
  final String name;
  final String code;
  final String mfId;
  final double rateNominal;
  final String interestType;
  final double amountMin;
  final double amountMax;
  final int termMin;
  final int termMax;
  final Map<String, dynamic> fees;
  final Map<String, dynamic> penalties;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreditProduct({
    required this.id,
    required this.name,
    required this.code,
    required this.mfId,
    required this.rateNominal,
    required this.interestType,
    required this.amountMin,
    required this.amountMax,
    required this.termMin,
    required this.termMax,
    required this.fees,
    required this.penalties,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor para crear desde Firestore
  factory CreditProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CreditProduct(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      mfId: data['mfId'] ?? '',
      rateNominal: (data['rateNominal'] ?? 0).toDouble(),
      interestType: data['interestType'] ?? 'flat',
      amountMin: (data['amountMin'] ?? 0).toDouble(),
      amountMax: (data['amountMax'] ?? 0).toDouble(),
      termMin: data['termMin'] ?? 0,
      termMax: data['termMax'] ?? 0,
      fees: data['fees'] ?? {},
      penalties: data['penalties'] ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Método para convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'code': code,
      'mfId': mfId,
      'rateNominal': rateNominal,
      'interestType': interestType,
      'amountMin': amountMin,
      'amountMax': amountMax,
      'termMin': termMin,
      'termMax': termMax,
      'fees': fees,
      'penalties': penalties,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Getters para mantener compatibilidad con el código existente
  String get formattedAmountRange => 
      'S/ ${amountMin.toStringAsFixed(0)} - S/ ${amountMax.toStringAsFixed(0)}';

  String get formattedTermRange => 
      '$termMin - $termMax meses';

  String get formattedInterestRate => 
      '${rateNominal.toStringAsFixed(1)}%';

  String get interestTypeLabel {
    switch (interestType) {
      case 'flat':
        return 'Tasa Plana';
      case 'efectivo':
        return 'Tasa Efectiva';
      case 'nominal':
        return 'Tasa Nominal';
      default:
        return 'Tasa de interés';
    }
  }

  // Propiedades de UI basadas en el código del producto
  Color get primaryColor {
    switch (code) {
      case 'CRED_GRUP':
        return const Color(0xFF10B981); // Verde
      case 'MICROEMP':
        return const Color(0xFF06B6D4); // Cyan
      case 'CRED_RESP':
        return const Color(0xFF8B5CF6); // Púrpura
      case 'CRED_VERDE':
        return const Color(0xFF10B981); // Verde
      case 'MIC_PROD':
        return const Color(0xFFF97316); // Naranja
      case 'CRED_IND':
        return const Color(0xFF3B82F6); // Azul
      default:
        return const Color(0xFF6B7280); // Gris por defecto
    }
  }

  Color get backgroundColor {
    switch (code) {
      case 'CRED_GRUP':
        return const Color(0xFFECFDF5);
      case 'MICROEMP':
        return const Color(0xFFECFEFF);
      case 'CRED_RESP':
        return const Color(0xFFF3F4F6);
      case 'CRED_VERDE':
        return const Color(0xFFECFDF5);
      case 'MIC_PROD':
        return const Color(0xFFFFF7ED);
      case 'CRED_IND':
        return const Color(0xFFEFF6FF);
      default:
        return const Color(0xFFF9FAFB);
    }
  }

  IconData get icon {
    switch (code) {
      case 'CRED_GRUP':
        return Icons.group;
      case 'MICROEMP':
        return Icons.business;
      case 'CRED_RESP':
        return Icons.shopping_cart;
      case 'CRED_VERDE':
        return Icons.eco;
      case 'MIC_PROD':
        return Icons.factory;
      case 'CRED_IND':
        return Icons.person;
      default:
        return Icons.credit_card;
    }
  }

  String get description {
    switch (code) {
      case 'CRED_GRUP':
        return 'Para pequeños negocios y emprendimientos';
      case 'MICROEMP':
        return 'Para financiar operaciones comerciales';
      case 'CRED_RESP':
        return 'Para gastos personales y familiares';
      case 'CRED_VERDE':
        return 'Para proyectos ecológicos y sostenibles';
      case 'MIC_PROD':
        return 'Para emprendimientos productivos';
      case 'CRED_IND':
        return 'Para necesidades personales específicas';
      default:
        return 'Producto de crédito';
    }
  }

  List<String> get features {
    switch (code) {
      case 'CRED_GRUP':
        return ['Garantía solidaria', 'Proceso rápido', 'Sin garantías físicas'];
      case 'MICROEMP':
        return ['Capital de trabajo', 'Evaluación personalizada', 'Seguimiento especializado'];
      case 'CRED_RESP':
        return ['Aprobación rápida', 'Montos accesibles', 'Pagos flexibles'];
      case 'CRED_VERDE':
        return ['Tasa preferencial', 'Impacto ambiental positivo', 'Evaluación especializada'];
      case 'MIC_PROD':
        return ['Orientado a producción', 'Asesoría técnica', 'Plazos extendidos'];
      case 'CRED_IND':
        return ['Evaluación individual', 'Proceso personalizado', 'Flexibilidad de uso'];
      default:
        return ['Producto de crédito'];
    }
  }

  // Compatibilidad con nombres anteriores
  double get minAmount => amountMin;
  double get maxAmount => amountMax;
  int get minTermMonths => termMin;
  int get maxTermMonths => termMax;
  double get interestRate => rateNominal;
}