import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreDataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> seedSampleData({String mfId = 'demo_mf'}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado. Inicia sesión primero.');
    }

    try {
      print('🌱 Iniciando poblado de datos para microfinanciera: $mfId');

      // Crear datos de ejemplo en lotes para mejor rendimiento
      await _seedBranches(mfId);
      await _seedProducts(mfId);
      await _seedAgents(mfId);
      await _seedCustomers(mfId);
      await _seedApplications(mfId);
      await _seedLoans(mfId);

      print('✅ Datos de ejemplo creados exitosamente');
    } catch (e, stackTrace) {
      print('❌ Error poblando datos: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Crear sucursales de ejemplo
  Future<void> _seedBranches(String mfId) async {
    final branches = [
      {
        'id': 'branch_001',
        'name': 'Sucursal Principal - Lima Centro',
        'address': 'Av. Abancay 123, Cercado de Lima',
        'status': 'active',
      },
      {
        'id': 'branch_002',
        'name': 'Sucursal Norte - Los Olivos',
        'address': 'Av. Carlos Izaguirre 456, Los Olivos',
        'status': 'active',
      },
      {
        'id': 'branch_003',
        'name': 'Sucursal Sur - Villa El Salvador',
        'address': 'Av. Pachacutec 789, Villa El Salvador',
        'status': 'active',
      },
    ];

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    for (final branchData in branches) {
      final ref = _firestore
          .collection('microfinancieras')
          .doc(mfId)
          .collection('branches')
          .doc(branchData['id'] as String);

      batch.set(ref, {
        'name': branchData['name'],
        'address': branchData['address'],
        'status': branchData['status'],
        'createdAt': now,
        'updatedAt': now,
      });
    }

    await batch.commit();
    print('✅ ${branches.length} sucursales creadas');
  }

  /// Crear productos financieros de ejemplo
  Future<void> _seedProducts(String mfId) async {
    final products = [
      {
        'id': 'product_micro',
        'mfId': mfId,
        'code': 'MICRO_001',
        'name': 'Microcrédito Personal',
        'interestType': 'flat',
        'rateNominal': 0.28, // 28% anual
        'termMin': 3,
        'termMax': 12,
        'amountMin': 50000, // S/. 500
        'amountMax': 500000, // S/. 5,000
      },
      {
        'id': 'product_pyme',
        'mfId': mfId,
        'code': 'PYME_001',
        'name': 'Crédito PYME',
        'interestType': 'declining',
        'rateNominal': 0.24, // 24% anual
        'termMin': 6,
        'termMax': 24,
        'amountMin': 500000, // S/. 5,000
        'amountMax': 2000000, // S/. 20,000
      },
      {
        'id': 'product_agro',
        'mfId': mfId,
        'code': 'AGRO_001',
        'name': 'Crédito Agrícola',
        'interestType': 'flat',
        'rateNominal': 0.20, // 20% anual
        'termMin': 3,
        'termMax': 18,
        'amountMin': 100000, // S/. 1,000
        'amountMax': 1000000, // S/. 10,000
      },
    ];

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    for (final productData in products) {
      final ref = _firestore
          .collection('microfinancieras')
          .doc(mfId)
          .collection('products')
          .doc(productData['id'] as String);

      batch.set(ref, {
        ...productData,
        'fees': {
          'origination': 2000, // S/. 20
          'administrative': 1500, // S/. 15
        },
        'penalties': {
          'late_payment': 5000, // S/. 50
        },
        'createdAt': now,
      });
    }

    await batch.commit();
    print('✅ ${products.length} productos creados');
  }

  /// Crear agentes de crédito de ejemplo
  Future<void> _seedAgents(String mfId) async {
    final agents = [
      {
        'id': 'agent_001',
        'fullName': 'Juan Carlos Pérez Sánchez',
        'phone': '+51987654321',
        'branchId': 'branch_001',
      },
      {
        'id': 'agent_002',
        'fullName': 'María Elena García López',
        'phone': '+51987654322',
        'branchId': 'branch_001',
      },
      {
        'id': 'agent_003',
        'fullName': 'Carlos Alberto Ruiz Díaz',
        'phone': '+51987654323',
        'branchId': 'branch_002',
      },
    ];

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    for (final agentData in agents) {
      final ref = _firestore
          .collection('microfinancieras')
          .doc(mfId)
          .collection('agents')
          .doc(agentData['id'] as String);

      batch.set(ref, {
        'fullName': agentData['fullName'],
        'phone': agentData['phone'],
        'branchId': agentData['branchId'],
        'status': 'active',
        'createdAt': now,
        'updatedAt': now,
      });
    }

    await batch.commit();
    print('✅ ${agents.length} agentes creados');
  }

  /// Crear clientes de ejemplo
  Future<void> _seedCustomers(String mfId) async {
    final customers = [
      {
        'id': 'customer_001',
        'mfId': mfId,
        'docType': 'DNI',
        'docNumber': '12345678',
        'fullName': 'María Rosa García López',
        'phone': '+51987111111',
        'email': 'maria.garcia@example.com',
        'address': 'Jr. Los Olivos 456, Lima',
        'personType': 'natural',
      },
      {
        'id': 'customer_002',
        'mfId': mfId,
        'docType': 'DNI',
        'docNumber': '87654321',
        'fullName': 'José Antonio Mendoza Ríos',
        'phone': '+51987222222',
        'email': 'jose.mendoza@example.com',
        'address': 'Av. Los Próceres 789, San Juan de Lurigancho',
        'personType': 'natural',
      },
      {
        'id': 'customer_003',
        'mfId': mfId,
        'docType': 'RUC',
        'docNumber': '20123456789',
        'fullName': 'Comercial Santa Rosa E.I.R.L.',
        'phone': '+51987333333',
        'email': 'contacto@santarosa.com',
        'address': 'Av. Industrial 234, Ate',
        'personType': 'juridica',
      },
    ];

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    final userId = _auth.currentUser?.uid ?? 'system';

    for (final customerData in customers) {
      final ref = _firestore
          .collection('microfinancieras')
          .doc(mfId)
          .collection('customers')
          .doc(customerData['id'] as String);

      final fullName = customerData['fullName'] as String;
      final searchKeys = _generateSearchKeys(
        fullName,
        customerData['docNumber'] as String,
      );

      batch.set(ref, {
        ...customerData,
        'searchKeys': searchKeys,
        'isActive': true,
        'createdAt': now,
        'createdBy': userId,
      });
    }

    await batch.commit();
    print('✅ ${customers.length} clientes creados');
  }

  /// Crear solicitudes de ejemplo
  Future<void> _seedApplications(String mfId) async {
    final applications = [
      {
        'id': 'app_001',
        'mfId': mfId,
        'customerId': 'customer_001',
        'productId': 'product_micro',
        'amount': 150000, // S/. 1,500
        'term': 6,
        'status': 'approved',
        'customerName': 'María Rosa García López',
        'productName': 'Microcrédito Personal',
      },
      {
        'id': 'app_002',
        'mfId': mfId,
        'customerId': 'customer_002',
        'productId': 'product_pyme',
        'amount': 800000, // S/. 8,000
        'term': 12,
        'status': 'under_review',
        'customerName': 'José Antonio Mendoza Ríos',
        'productName': 'Crédito PYME',
      },
      {
        'id': 'app_003',
        'mfId': mfId,
        'customerId': 'customer_003',
        'productId': 'product_agro',
        'amount': 500000, // S/. 5,000
        'term': 9,
        'status': 'draft',
        'customerName': 'Comercial Santa Rosa E.I.R.L.',
        'productName': 'Crédito Agrícola',
      },
    ];

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    for (final appData in applications) {
      final ref = _firestore
          .collection('microfinancieras')
          .doc(mfId)
          .collection('applications')
          .doc(appData['id'] as String);

      batch.set(ref, {...appData, 'createdAt': now, 'updatedAt': now});
    }

    await batch.commit();
    print('✅ ${applications.length} solicitudes creadas');
  }

  /// Crear préstamos de ejemplo
  Future<void> _seedLoans(String mfId) async {
    final loans = [
      {
        'id': 'loan_001',
        'mfId': mfId,
        'applicationId': 'app_001',
        'productId': 'product_micro',
        'customerId': 'customer_001',
        'principal': 150000.0, // S/. 1,500
        'rateNominal': 0.28,
        'term': 6,
        'status': 'disbursed',
        'branchId': 'branch_001',
        'outstandingPrincipal': 125000.0, // S/. 1,250
      },
    ];

    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    final startDate = DateTime.now().subtract(const Duration(days: 30));
    final nextDue = DateTime.now().add(const Duration(days: 30));

    for (final loanData in loans) {
      final ref = _firestore
          .collection('microfinancieras')
          .doc(mfId)
          .collection('loans')
          .doc(loanData['id'] as String);

      batch.set(ref, {
        ...loanData,
        'createdAt': now,
        'startDate': Timestamp.fromDate(startDate),
        'nextDueDate': Timestamp.fromDate(nextDue),
      });
    }

    await batch.commit();
    print('✅ ${loans.length} préstamos creados');
  }

  /// Generar claves de búsqueda para un cliente
  List<String> _generateSearchKeys(String fullName, String docNumber) {
    final keys = <String>{};

    // Agregar nombres individuales
    final nameParts = fullName.toLowerCase().split(' ');
    keys.addAll(nameParts);

    // Agregar número de documento
    keys.add(docNumber);

    // Agregar combinaciones de nombre
    if (nameParts.length >= 2) {
      keys.add('${nameParts[0]} ${nameParts[1]}');
    }

    return keys.toList();
  }

  /// Limpiar todos los datos de ejemplo (usar con cuidado)
  Future<void> clearSampleData({String mfId = 'demo_mf'}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    final collections = [
      'branches',
      'products',
      'agents',
      'customers',
      'applications',
      'loans',
      'intake_requests',
      'ml_scores',
      'dashboards_public',
      'auditLogs',
    ];

    for (final collection in collections) {
      final snapshot = await _firestore
          .collection('microfinancieras')
          .doc(mfId)
          .collection(collection)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
        print('✅ ${snapshot.docs.length} documentos eliminados de $collection');
      }
    }

    print('✅ Datos de ejemplo eliminados');
  }
}
