import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../core/config/firebase_config.dart';

/// Script para crear microfinancieras de ejemplo en Firestore
/// Esto debe ejecutarse una sola vez para tener datos de prueba
Future<void> createSampleMicrofinancieras() async {
  // Inicializar Firebase
  await Firebase.initializeApp(options: FirebaseConfig.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  debugPrint('🏢 [SCRIPT] Creando microfinancieras de ejemplo...');

  try {
    // Microfinanciera 1: MicroFinanzas del Perú
    await firestore.collection('microfinancieras').doc('mf_demo_001').set({
      'name': 'MicroFinanzas del Perú',
      'legalName': 'MicroFinanzas del Perú S.A.',
      'ruc': '20123456789',
      'address': 'Av. El Sol 123, Cusco, Perú',
      'phone': '+51 84 123456',
      'email': 'contacto@microfinanzasperu.com',
      'website': 'https://microfinanzasperu.com',
      'isActive': true,
      'createdAt': Timestamp.now(),
      'settings': {
        'currency': 'PEN',
        'timeZone': 'America/Lima',
        'language': 'es',
        'allowRegistration': true,
        'maxLoanAmount': 50000.0,
        'minLoanAmount': 500.0,
      },
    });

    // Microfinanciera 2: Crédito Express
    await firestore.collection('microfinancieras').doc('mf_demo_002').set({
      'name': 'Crédito Express',
      'legalName': 'Crédito Express Microfinanciera S.A.C.',
      'ruc': '20987654321',
      'address': 'Jr. Comercio 456, Lima, Perú',
      'phone': '+51 1 234567',
      'email': 'info@creditoexpress.pe',
      'website': 'https://creditoexpress.pe',
      'isActive': true,
      'createdAt': Timestamp.now(),
      'settings': {
        'currency': 'PEN',
        'timeZone': 'America/Lima',
        'language': 'es',
        'allowRegistration': true,
        'maxLoanAmount': 30000.0,
        'minLoanAmount': 300.0,
      },
    });

    // Microfinanciera 3: FinanSur (Inactiva para probar filtrado)
    await firestore.collection('microfinancieras').doc('mf_demo_003').set({
      'name': 'FinanSur',
      'legalName': 'Financiera del Sur S.A.',
      'ruc': '20555666777',
      'address': 'Av. Arequipa 789, Arequipa, Perú',
      'phone': '+51 54 345678',
      'email': 'contacto@finansur.pe',
      'isActive': false, // Inactiva
      'createdAt': Timestamp.now(),
      'settings': {
        'currency': 'PEN',
        'timeZone': 'America/Lima',
        'language': 'es',
        'allowRegistration': false,
      },
    });

    debugPrint('✅ [SCRIPT] Microfinancieras creadas exitosamente:');
    debugPrint('   - MicroFinanzas del Perú (mf_demo_001)');
    debugPrint('   - Crédito Express (mf_demo_002)');
    debugPrint('   - FinanSur (mf_demo_003) [Inactiva]');
    debugPrint('');
    debugPrint('💡 [SCRIPT] Ahora puedes usar el login/register con estas microfinancieras');
  } catch (e) {
    debugPrint('❌ [SCRIPT] Error al crear microfinancieras: $e');
  }
}

/// Función main para ejecutar el script
void main() async {
  await createSampleMicrofinancieras();
}
