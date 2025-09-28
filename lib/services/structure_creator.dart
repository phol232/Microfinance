import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';

/// Script para crear la estructura de documentos en Firestore sin datos de ejemplo
class StructureCreator {
  final FirestoreService _firestoreService;

  StructureCreator({required String tenantId})
    : _firestoreService = FirestoreService(tenantId: tenantId);

  /// Crear toda la estructura de documentos vacía
  Future<void> createStructure() async {
    print('🏗️ Creando estructura de documentos en Firestore...');

    try {
      await _createBranchesStructure();
      await _createAgentsStructure();
      await _createProductsStructure();
      await _createCustomersStructure();
      await _createIntakeRequestsStructure();
      await _createApplicationsStructure();
      await _createLoansStructure();
      await _createTransactionsStructure();
      await _createMlStructure();
      await _createDashboardStructure();
      await _createOutboxStructure();
      await _createAuditLogStructure();

      print('✅ Estructura de documentos creada exitosamente!');
      print('📋 Todos los campos están disponibles en Firestore Console');
    } catch (e) {
      print('❌ Error creando estructura: $e');
      rethrow;
    }
  }

  Future<void> _createBranchesStructure() async {
    print('📍 Creando estructura: branches');

    final branch = Branch(
      id: 'template_branch',
      name: '',
      status: 'inactive',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.branches
        .doc('template_branch')
        .set(branch.toFirestore());
  }

  Future<void> _createAgentsStructure() async {
    print('👥 Creando estructura: agents');

    final agent = Agent(
      id: 'template_agent',
      fullName: '',
      phone: '',
      branchId: '',
      status: 'inactive',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.agents
        .doc('template_agent')
        .set(agent.toFirestore());
  }

  Future<void> _createProductsStructure() async {
    print('💼 Creando estructura: products');

    final product = Product(
      id: 'template_product',
      name: '',
      rateNominal: 0.0,
      termMonths: 0,
      minAmountCents: 0,
      maxAmountCents: 0,
      fees: FeesInfo(originationPct: 0.0, flatFeeCents: 0),
      status: 'inactive',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.products
        .doc('template_product')
        .set(product.toFirestore());
  }

  Future<void> _createCustomersStructure() async {
    print('👤 Creando estructura: customers');

    final customer = Customer(
      id: 'template_customer',
      fullName: '',
      dni: '',
      phone: '',
      email: '',
      address: '',
      district: '',
      branchId: '',
      status: 'blocked',
      riskScore: 0.0,
      custNo: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.customers
        .doc('template_customer')
        .set(customer.toFirestore());
  }

  Future<void> _createIntakeRequestsStructure() async {
    print('📝 Creando estructura: intake_requests');

    final intakeRequest = IntakeRequest(
      id: 'template_intake',
      status: 'received',
      contact: ContactInfo(phone: '', email: '', verified: false),
      applicant: ApplicantInfo(
        dni: '',
        fullName: '',
        district: '',
        activity: '',
      ),
      requested: RequestedInfo(amountCents: 0, termMonths: 0, productId: ''),
      consent: ConsentInfo(accepted: false, version: '', at: DateTime.now()),
      routing: RoutingInfo(branchId: '', assignedAgentId: ''),
      riskFlags: RiskFlags(spamScore: 0.0, reason: ''),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.intakeRequests
        .doc('template_intake')
        .set(intakeRequest.toFirestore());
  }

  Future<void> _createApplicationsStructure() async {
    print('📋 Creando estructura: applications');

    final application = Application(
      id: 'template_application',
      intakeId: '',
      customerId: '',
      kyc: KycInfo(address: '', references: [''], businessType: ''),
      productId: '',
      requested: RequestedInfo(amountCents: 0, termMonths: 0),
      status: 'draft',
      bureau: BureauInfo(reportRef: '', fetchedAt: DateTime.now()),
      score: ScoreInfo(
        value: 0.0,
        band: '',
        reasonCodes: [''],
        modelVersion: '',
      ),
      submittedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.applications
        .doc('template_application')
        .set(application.toFirestore());
  }

  Future<void> _createLoansStructure() async {
    print('💰 Creando estructura: loans + subcolecciones');

    final loan = Loan(
      id: 'template_loan',
      customerId: '',
      applicationId: '',
      productId: '',
      branchId: '',
      agentId: '',
      principalCents: 0,
      currency: 'PEN',
      rateNominal: 0.0,
      termMonths: 0,
      graceDays: 0,
      disbursementAt: DateTime.now(),
      status: 'approved',
      arrearsDays: 0,
      balances: BalancesInfo(
        principalDueCents: 0,
        interestDueCents: 0,
        feesDueCents: 0,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.loans.doc('template_loan').set(loan.toFirestore());

    // Crear estructura de schedule
    final installment = Installment(
      id: 'template_installment',
      idx: 0,
      dueAt: DateTime.now(),
      principalCents: 0,
      interestCents: 0,
      feeCents: 0,
      totalCents: 0,
      paidCents: 0,
      status: 'pending',
    );

    await _firestoreService
        .loanSchedule('template_loan')
        .doc('template_installment')
        .set(installment.toFirestore());

    // Crear estructura de repayments
    final repayment = Repayment(
      id: 'template_repayment',
      receivedAt: DateTime.now(),
      amountCents: 0,
      method: 'cash',
      cashierId: '',
      receiptNo: '',
      applied: [
        AppliedPayment(
          installmentId: '',
          principalCents: 0,
          interestCents: 0,
          feeCents: 0,
        ),
      ],
    );

    await _firestoreService
        .loanRepayments('template_loan')
        .doc('template_repayment')
        .set(repayment.toFirestore());
  }

  Future<void> _createTransactionsStructure() async {
    print('💳 Creando estructura: transactions + entries');

    final transaction = FinancialTransaction(
      id: 'template_transaction',
      postedAt: DateTime.now(),
      type: 'disbursement',
      ref: TransactionRef(loanId: '', repaymentId: ''),
      memo: '',
      totalCents: 0,
    );

    await _firestoreService.transactions
        .doc('template_transaction')
        .set(transaction.toFirestore());

    // Crear estructura de entries
    final entry = Entry(
      id: 'template_entry',
      account: '',
      debitCents: 0,
      creditCents: 0,
    );

    await _firestoreService
        .transactionEntries('template_transaction')
        .doc('template_entry')
        .set(entry.toFirestore());
  }

  Future<void> _createMlStructure() async {
    print('🤖 Creando estructura: ml_scores y ml_metrics');

    final mlScore = MlScore(
      id: 'template_ml_score',
      applicationId: '',
      value: 0.0,
      band: '',
      reasonCodes: [''],
      modelVersion: '',
      createdAt: DateTime.now(),
    );

    await _firestoreService.mlScores
        .doc('template_ml_score')
        .set(mlScore.toFirestore());

    final mlMetrics = MlMetrics(
      id: 'template_ml_metrics',
      customerId: '',
      loanId: '',
      f1TxClass: 0.0,
      mapeForecast: 0.0,
      explainabilityPct: 0.0,
      latencyP95Ms: 0,
      adoptionRatePct: 0.0,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.mlMetrics
        .doc('template_ml_metrics')
        .set(mlMetrics.toFirestore());
  }

  Future<void> _createDashboardStructure() async {
    print('📊 Creando estructura: dashboards_public');

    final dashboard = DashboardPublic(
      id: 'template_dashboard',
      loanId: '',
      customerName: '',
      nextDueAt: DateTime.now(),
      nextDueAmountCents: 0,
      arrearsDays: 0,
      status: '',
      updatedAt: DateTime.now(),
    );

    await _firestoreService.dashboardsPublic
        .doc('template_dashboard')
        .set(dashboard.toFirestore());
  }

  Future<void> _createOutboxStructure() async {
    print('📤 Creando estructura: outbox');

    final outboxMessage = OutboxMessage(
      id: 'template_outbox',
      channel: 'email',
      to: '',
      template: 'TEMPLATE',
      params: {'key': 'value'},
      status: 'queued',
      createdAt: DateTime.now(),
      sentAt: DateTime.now(),
      error: '',
    );

    await _firestoreService.outbox
        .doc('template_outbox')
        .set(outboxMessage.toFirestore());
  }

  Future<void> _createAuditLogStructure() async {
    print('📋 Creando estructura: auditLogs');

    final auditLog = AuditLog(
      id: 'template_audit',
      actor: ActorInfo(uid: '', role: ''),
      action: '',
      before: {'field': 'oldValue'},
      after: {'field': 'newValue'},
      at: DateTime.now(),
      ip: '',
      device: '',
    );

    await _firestoreService.auditLogs
        .doc('template_audit')
        .set(auditLog.toFirestore());
  }
}

/// Función utilitaria para ejecutar el creador de estructura
Future<void> createFirestoreStructure({String tenantId = 'tenant_demo'}) async {
  final creator = StructureCreator(tenantId: tenantId);
  await creator.createStructure();
}
