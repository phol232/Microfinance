import 'package:flutter/material.dart';

class ProductColors {
  static Color getColorByCode(String? code) {
    if (code == null) return Colors.grey;

    switch (code) {
      case 'CRED_IND':
        return const Color(0xFF2563EB); // Azul
      case 'CRED_GRUP':
        return const Color(0xFF16A34A); // Verde
      case 'MIC_PROD':
        return const Color(0xFFEA580C); // Naranja
      case 'CRED_RESP':
        return const Color(0xFF9333EA); // Púrpura
      case 'MICROEMP':
        return const Color(0xFF0D9488); // Teal
      case 'CRED_VERDE':
        return const Color(0xFF65A30D); // Verde claro
      default:
        return Colors.grey;
    }
  }

  static String getNameByCode(String? code) {
    if (code == null) return 'Sin producto';

    switch (code) {
      case 'CRED_IND':
        return 'Crédito Individual';
      case 'CRED_GRUP':
        return 'Crédito Grupal';
      case 'MIC_PROD':
        return 'Microcrédito Productivo';
      case 'CRED_RESP':
        return 'Crédito Responsable';
      case 'MICROEMP':
        return 'Microempresa';
      case 'CRED_VERDE':
        return 'Crédito Verde';
      default:
        return code;
    }
  }

  static IconData getIconByCode(String? code) {
    if (code == null) return Icons.credit_card;

    switch (code) {
      case 'CRED_IND':
        return Icons.person;
      case 'CRED_GRUP':
        return Icons.groups;
      case 'MIC_PROD':
        return Icons.factory;
      case 'CRED_RESP':
        return Icons.verified_user;
      case 'MICROEMP':
        return Icons.business;
      case 'CRED_VERDE':
        return Icons.eco;
      default:
        return Icons.credit_card;
    }
  }
}
