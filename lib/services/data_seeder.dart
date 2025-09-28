import '../services/firestore_service.dart';
import '../models/models.dart';

/// Script para poblar datos de ejemplo en Firestore
class DataSeeder {
  final FirestoreService _firestoreService;

  DataSeeder({required String tenantId})
    : _firestoreService = FirestoreService(tenantId: tenantId);

  /// Poblar todos los datos de ejemplo
  Future<void> seedAll() async {
    print('🌱 Iniciando población de datos para tenant...');

    try {
      await _createBranches();
      await _createAgents();
      await _createProducts();
      await _createCustomers();
      await _createIntakeRequests();
      await _createApplications();
      await _createLoans();
      await _createTransactions();

      print('✅ Población de datos completada exitosamente!');
    } catch (e) {
      print('❌ Error poblando datos: $e');
      rethrow;
    }
  }

  Future<void> _createBranches() async {
    print('📍 Creando sucursales...');

    final branches = [
      Branch(
        id: 'branch_001',
        name: 'Sucursal Lima Centro',
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Branch(
        id: 'branch_002',
        name: 'Sucursal San Juan de Lurigancho',
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (var branch in branches) {
      await _firestoreService.branches.doc(branch.id).set(branch.toFirestore());
    }
  }

  Future<void> _createAgents() async {
    print('👥 Creando agentes...');

    final agents = [
      Agent(
        id: 'agent_001',
        fullName: 'María García López',
        phone: '+51987654321',
        branchId: 'branch_001',
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Agent(
        id: 'agent_002',
        fullName: 'Carlos Mendoza Silva',
        phone: '+51987654322',
        branchId: 'branch_002',
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (var agent in agents) {
      await _firestoreService.agents.doc(agent.id).set(agent.toFirestore());
    }
  }

  Future<void> _createProducts() async {
    print('💼 Creando productos...');

    final products = [
      Product(
        id: 'product_microempresa',
        name: 'Crédito Microempresa',
        rateNominal: 0.24, // 24% anual
        termMonths: 12,
        minAmountCents: 100000, // S/1,000
        maxAmountCents: 5000000, // S/50,000
        fees: FeesInfo(originationPct: 0.02, flatFeeCents: 5000),
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: 'product_consumo',
        name: 'Crédito Personal',
        rateNominal: 0.36, // 36% anual
        termMonths: 6,
        minAmountCents: 50000, // S/500
        maxAmountCents: 1000000, // S/10,000
        fees: FeesInfo(originationPct: 0.03),
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (var product in products) {
      await _firestoreService.products
          .doc(product.id)
          .set(product.toFirestore());
    }
  }

  Future<void> _createCustomers() async {
    print('👤 Creando clientes...');

    final customers = [
      Customer(
        id: 'customer_001',
        fullName: 'Ana Lucía Rodríguez Vargas',
        dni: '12345678',
        phone: '+51912345678',
        email: 'ana.rodriguez@email.com',
        address: 'Jr. Lima 123, La Victoria',
        district: 'La Victoria',
        branchId: 'branch_001',
        status: 'active',
        riskScore: 0.75,
        custNo: 'C-2025-000001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Customer(
        id: 'customer_002',
        fullName: 'Roberto Carlos Pérez Mamani',
        dni: '87654321',
        phone: '+51987654321',
        address: 'Av. Próceres 456, SJL',
        district: 'San Juan de Lurigancho',
        branchId: 'branch_002',
        status: 'active',
        riskScore: 0.68,
        custNo: 'C-2025-000002',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    for (var customer in customers) {
      await _firestoreService.customers
          .doc(customer.id)
          .set(customer.toFirestore());
    }
  }

  Future<void> _createIntakeRequests() async {
    print('📝 Creando solicitudes iniciales...');

    final intakeRequests = [
      IntakeRequest(
        id: 'intake_001',
        status: 'converted',
        contact: ContactInfo(
          phone: '+51912345678',
          email: 'ana.rodriguez@email.com',
          verified: true,
        ),
        applicant: ApplicantInfo(
          dni: '12345678',
          fullName: 'Ana Lucía Rodríguez Vargas',
          district: 'La Victoria',
          activity: 'Bodega',
        ),
        requested: RequestedInfo(
          amountCents: 300000, // S/3,000
          termMonths: 12,
          productId: 'product_microempresa',
        ),
        consent: ConsentInfo(
          accepted: true,
          version: '1.0',
          at: DateTime.now().subtract(const Duration(days: 7)),
        ),
        routing: RoutingInfo(
          branchId: 'branch_001',
          assignedAgentId: 'agent_001',
        ),
        riskFlags: RiskFlags(spamScore: 0.1),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    for (var request in intakeRequests) {
      await _firestoreService.intakeRequests
          .doc(request.id)
          .set(request.toFirestore());
    }
  }

  Future<void> _createApplications() async {
    print('📋 Creando aplicaciones...');

    final applications = [
      Application(
        id: 'app_001',
        intakeId: 'intake_001',
        customerId: 'customer_001',
        kyc: KycInfo(
          address: 'Jr. Lima 123, La Victoria, Lima',
          references: [
            'Roberto Pérez - 987654321',
            'María González - 987654322',
          ],
          businessType: 'Retail',
        ),
        productId: 'product_microempresa',
        requested: RequestedInfo(amountCents: 300000, termMonths: 12),
        status: 'approved',
        bureau: BureauInfo(
          reportRef: 'BR-2025-001',
          fetchedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        score: ScoreInfo(
          value: 750.0,
          band: 'A',
          reasonCodes: ['LOW_RISK', 'GOOD_PAYMENT_HISTORY'],
          modelVersion: 'v2.1',
        ),
        submittedAt: DateTime.now().subtract(const Duration(days: 4)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    for (var app in applications) {
      await _firestoreService.applications.doc(app.id).set(app.toFirestore());
    }
  }

  Future<void> _createLoans() async {
    print('💰 Creando préstamos...');

    final loans = [
      Loan(
        id: 'loan_001',
        customerId: 'customer_001',
        applicationId: 'app_001',
        productId: 'product_microempresa',
        branchId: 'branch_001',
        agentId: 'agent_001',
        principalCents: 300000,
        currency: 'PEN',
        rateNominal: 0.24,
        termMonths: 12,
        graceDays: 5,
        disbursementAt: DateTime.now().subtract(const Duration(days: 30)),
        status: 'disbursed',
        arrearsDays: 0,
        balances: BalancesInfo(
          principalDueCents: 275000,
          interestDueCents: 6000,
          feesDueCents: 0,
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 32)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    for (var loan in loans) {
      await _firestoreService.loans.doc(loan.id).set(loan.toFirestore());

      // Crear cronograma de pagos
      await _createLoanSchedule(loan.id);
    }
  }

  Future<void> _createLoanSchedule(String loanId) async {
    print('📅 Creando cronograma para préstamo $loanId...');

    final installments = List.generate(12, (index) {
      final dueDate = DateTime.now().add(Duration(days: 30 * (index + 1)));

      return Installment(
        id: 'installment_${index + 1}',
        idx: index + 1,
        dueAt: dueDate,
        principalCents: 25000, // S/250 capital
        interestCents: 6000, // S/60 interés
        feeCents: 0,
        totalCents: 31000, // S/310 total
        paidCents: index == 0 ? 31000 : 0, // Primera cuota pagada
        status: index == 0 ? 'paid' : 'pending',
      );
    });

    for (var installment in installments) {
      await _firestoreService
          .loanSchedule(loanId)
          .doc(installment.id)
          .set(installment.toFirestore());
    }
  }

  Future<void> _createTransactions() async {
    print('💳 Creando transacciones...');

    final transaction = FinancialTransaction(
      id: 'tx_001',
      postedAt: DateTime.now().subtract(const Duration(days: 30)),
      type: 'disbursement',
      ref: TransactionRef(loanId: 'loan_001'),
      memo: 'Desembolso préstamo microempresa',
      totalCents: 300000,
    );

    await _firestoreService.transactions
        .doc(transaction.id)
        .set(transaction.toFirestore());

    // Crear entradas contables
    final entries = [
      Entry(
        id: 'entry_001',
        account: 'LOANS_RECEIVABLE',
        debitCents: 300000,
        creditCents: 0,
      ),
      Entry(
        id: 'entry_002',
        account: 'CASH',
        debitCents: 0,
        creditCents: 300000,
      ),
    ];

    for (var entry in entries) {
      await _firestoreService
          .transactionEntries(transaction.id)
          .doc(entry.id)
          .set(entry.toFirestore());
    }
  }
}

/// Función utilitaria para ejecutar el seeder
Future<void> runSeeder({String tenantId = 'tenant_demo'}) async {
  final seeder = DataSeeder(tenantId: tenantId);
  await seeder.seedAll();
}
