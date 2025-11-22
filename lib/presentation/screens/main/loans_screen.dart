import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../bloc/card/card_bloc.dart';
import '../../utils/product_colors.dart';
import '../loan_schedule_screen.dart';
import '../../widgets/chatbot/chatbot_launcher.dart';
import '../../../data/repositories/transaction_repository_impl.dart';
import '../../../data/datasources/transaction_datasource.dart';
import '../../../data/repositories/card_repository_impl.dart';
import '../../../data/datasources/card_datasource.dart';
import '../../../domain/usecases/transaction/get_transaction_history_usecase.dart';
import '../../../domain/usecases/transaction/process_payment_usecase.dart';
import '../../../domain/usecases/transaction/process_disbursement_usecase.dart';
import '../../../domain/usecases/transaction/get_card_transactions_usecase.dart';
import '../../../domain/usecases/card/get_user_cards_usecase.dart';
import '../../../domain/usecases/card/request_card_usecase.dart';
import '../../../domain/usecases/card/get_cards_by_account_usecase.dart';
import '../../../domain/usecases/card/get_cards_by_status_usecase.dart';
import '../../../domain/usecases/card/update_card_usecase.dart';
import '../../../domain/usecases/card/change_card_status_usecase.dart';
import '../../../domain/usecases/card/get_card_by_id_usecase.dart';
import '../../../domain/usecases/card/update_card_limits_usecase.dart';
import '../../../domain/usecases/card/update_card_security_settings_usecase.dart';
import '../../../domain/usecases/transaction/get_account_balance_usecase.dart';
import 'package:mobile/infrastructure/services/transaction_service.dart';
import 'package:mobile/infrastructure/tenant/tenant_controller.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({Key? key}) : super(key: key);

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _resolveMicrofinancieraId(BuildContext context) {
    final profile = context.read<ProfileBloc>().state.profile;
    final tenantId = context.read<TenantController>().tenantId;
    return profile?.microfinancieraId ?? tenantId;
  }

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/ ',
    decimalDigits: 2,
    customPattern: '¤#,##0.00',
  );

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  Stream<QuerySnapshot> _getLoansStream(BuildContext context) {
    final microId = _resolveMicrofinancieraId(context);
    final uid = _auth.currentUser?.uid;
    if (uid == null || microId == null || microId.isEmpty) {
      return const Stream.empty();
    }
    final tenantId = microId;
    try {
      return _firestore
          .collection('microfinancieras')
          .doc(tenantId)
          .collection('loanApplications')
          .where('status', whereIn: ['disbursed', 'filled'])
          .where('userId', isEqualTo: uid)
          .snapshots()
          .handleError((error) {
            debugPrint('Error en stream de créditos: $error');
            return const Stream<QuerySnapshot>.empty();
          });
    } catch (e) {
      debugPrint('Error al crear stream de créditos: $e');
      return const Stream<QuerySnapshot>.empty();
    }
  }

  Color _getStatusColor(String status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'active':
      case 'disbursed':
        return const Color(0xFF4CAF50); // Success green
      case 'pending':
        return const Color(0xFFFF9800); // Warning orange
      case 'overdue':
      case 'in_arrears':
        return colorScheme.error;
      case 'closed':
      case 'paid':
      case 'filled':
      case 'completed':
        return colorScheme.primary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'disbursed':
        return 'Activo';
      case 'pending':
        return 'Pendiente';
      case 'overdue':
      case 'in_arrears':
        return 'Vencido';
      case 'closed':
      case 'paid':
        return 'Pagado';
      case 'filled':
      case 'completed':
        return 'Completado';
      default:
        return status;
    }
  }

  void _navigateToSchedule(
    BuildContext context,
    String loanId,
    Map<String, dynamic> loanData,
  ) {
    final transactionRepository = TransactionRepositoryImpl(
      datasource: TransactionDatasource(),
    );

    final cardRepository = CardRepositoryImpl(cardDataSource: CardDataSource());

    final microfinancieraId = _resolveMicrofinancieraId(context);
    if (microfinancieraId == null || microfinancieraId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontró microfinanciera activa. Intenta nuevamente.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => TransactionBloc(
                transactionService: TransactionService(
                  processPaymentUseCase: ProcessPaymentUseCase(
                    transactionRepository,
                  ),
                  processDisbursementUseCase: ProcessDisbursementUseCase(
                    transactionRepository,
                  ),
                  getTransactionHistoryUseCase: GetTransactionHistoryUseCase(
                    transactionRepository,
                  ),
                  getCardTransactionsUseCase: GetCardTransactionsUseCase(
                    transactionRepository,
                  ),
                  getAccountBalanceUseCase: GetAccountBalanceUseCase(
                    transactionRepository,
                  ),
                ),
              ),
            ),
            BlocProvider(
              create: (context) => CardBloc(
                getUserCardsUseCase: GetUserCardsUseCase(cardRepository),
                requestCardUseCase: RequestCardUseCase(cardRepository),
                getCardsByAccountUseCase: GetCardsByAccountUseCase(
                  cardRepository,
                ),
                getCardsByStatusUseCase: GetCardsByStatusUseCase(
                  cardRepository,
                ),
                updateCardUseCase: UpdateCardUseCase(cardRepository),
                blockCardUseCase: BlockCardUseCase(cardRepository),
                unblockCardUseCase: UnblockCardUseCase(cardRepository),
                cancelCardUseCase: CancelCardUseCase(cardRepository),
                activateCardUseCase: ActivateCardUseCase(cardRepository),
                getCardByIdUseCase: GetCardByIdUseCase(cardRepository),
                updateCardLimitsUseCase: UpdateCardLimitsUseCase(
                  cardRepository,
                ),
                updateCardSecuritySettingsUseCase:
                    UpdateCardSecuritySettingsUseCase(cardRepository),
              ),
            ),
          ],
          child: LoanScheduleScreen(
            loanId: loanId,
            loanData: loanData,
            microfinancieraId: microfinancieraId,
          ),
        ),
      ),
    ).then((shouldRefresh) {
      if (shouldRefresh == true && mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Forzar reconstrucción del stream
              });
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getLoansStream(context),
        builder: (context, snapshot) {
          // Manejo de estados de conexión con timeout
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Mostrar loading solo por un tiempo limitado
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando créditos...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            final colorScheme = Theme.of(context).colorScheme;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar créditos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          // Forzar reconstrucción
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final loans = snapshot.data?.docs ?? [];

          if (loans.isEmpty) {
            final colorScheme = Theme.of(context).colorScheme;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aún no tienes préstamos desembolsados',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cuando tengas créditos activos aparecerán aquí',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final colorScheme = Theme.of(context).colorScheme;
              final doc = loans[index];
              final data = doc.data() as Map<String, dynamic>;

              // Extraer información del crédito
              final financialInfo =
                  data['financialInfo'] as Map<String, dynamic>? ?? {};
              final productInfo =
                  data['product'] as Map<String, dynamic>? ?? {};

              final amount = (financialInfo['loanAmount'] ?? 0.0) as num;
              final termMonths = financialInfo['loanTermMonths'] ?? 0;
              final rate = (productInfo['rateNominal'] ?? 0.0) as num;
              final productCode = productInfo['code'] ?? '';
              final productName = productInfo['name'] ?? 'Crédito';
              final status = (data['status'] ?? 'disbursed').toString();
              final statusText = _getStatusText(status);
              final statusColor = _getStatusColor(status, context);
              final createdAt =
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              final microId = _resolveMicrofinancieraId(context);
              if (microId == null || microId.isEmpty) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<QuerySnapshot>(
                future: _firestore
                    .collection('microfinancieras')
                    .doc(microId)
                    .collection('loanApplications')
                    .doc(doc.id)
                    .collection('repaymentSchedule')
                    .get(),
                builder: (context, scheduleSnapshot) {
                  if (scheduleSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (scheduleSnapshot.hasError ||
                      scheduleSnapshot.data == null ||
                      scheduleSnapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final scheduleDocs = scheduleSnapshot.data!.docs;
                  int paidCount = 0;
                  double totalPaid = 0.0;
                  double monthlyPayment = 0.0;
                  double totalLoanAmount = 0.0;

                  for (var scheduleDoc in scheduleDocs) {
                    final scheduleData =
                        scheduleDoc.data() as Map<String, dynamic>;
                    final scheduleStatus = scheduleData['status'] ?? 'pending';
                    final totalPayment =
                        (scheduleData['totalPayment'] as num?)?.toDouble() ??
                            0.0;

                    totalLoanAmount += totalPayment;
                    if (monthlyPayment == 0.0 && totalPayment > 0) {
                      monthlyPayment = totalPayment;
                    }
                    if (scheduleStatus == 'paid') {
                      paidCount++;
                      totalPaid += totalPayment;
                    }
                  }

                  final double pendingBalance = totalLoanAmount - totalPaid;
                  final totalInstallments = termMonths;
                  final progressPercentage = totalInstallments > 0
                      ? (paidCount / totalInstallments) * 100
                      : 0.0;
                  final derivedStatus =
                      (pendingBalance <= 0.01 && totalInstallments > 0)
                          ? 'filled'
                          : status;
                  final statusText = _getStatusText(derivedStatus);
                  final statusColor = _getStatusColor(derivedStatus, context);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ProductColors.getColorByCode(
                            productCode,
                          ).withOpacity(0.1),
                          ProductColors.getColorByCode(
                            productCode,
                          ).withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(
                        color: ProductColors.getColorByCode(
                          productCode,
                        ).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con nombre del producto y estado
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ProductColors.getColorByCode(
                                    productCode,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  ProductColors.getIconByCode(productCode),
                                  color: colorScheme.onPrimary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Crédito $statusText',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Monto Aprobado destacado
                          Text(
                            'Monto Aprobado',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currencyFormat.format(amount),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ProductColors.getColorByCode(productCode),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Progreso de Pago
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progreso de Pago',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '${progressPercentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: ProductColors.getColorByCode(
                                    productCode,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressPercentage / 100,
                              minHeight: 8,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ProductColors.getColorByCode(productCode),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Información en filas
                          Row(
                            children: [
                              Expanded(
                                child: _buildIndicatorItem(
                                  'Tasa',
                                  '${rate.toStringAsFixed(2)}%',
                                  Icons.percent,
                                  ProductColors.getColorByCode(productCode),
                                  context,
                                ),
                              ),
                              Expanded(
                                child: _buildIndicatorItem(
                                  'Plazo',
                                  '$totalInstallments meses',
                                  Icons.calendar_today,
                                  ProductColors.getColorByCode(productCode),
                                  context,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildIndicatorItem(
                                  'Cuota Mensual',
                                  _currencyFormat.format(monthlyPayment),
                                  Icons.description,
                                  ProductColors.getColorByCode(productCode),
                                  context,
                                ),
                              ),
                              Expanded(
                                child: _buildIndicatorItem(
                                  'Pagadas',
                                  '$paidCount/$totalInstallments',
                                  Icons.check_circle,
                                  const Color(0xFF4CAF50), // Success green
                                  context,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Total Pagado y Saldo Pendiente
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Pagado',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currencyFormat.format(totalPaid),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4CAF50),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Saldo Pendiente',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currencyFormat.format(pendingBalance),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: ProductColors.getColorByCode(
                                          productCode,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Fecha de desembolso
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Desembolsado: ${_dateFormat.format(createdAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Botón Ver Cronograma
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _navigateToSchedule(context, doc.id, data),
                              icon: const Icon(Icons.schedule, size: 18),
                              label: const Text('Ver Cronograma de Cuotas'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ProductColors.getColorByCode(
                                  productCode,
                                ),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: const ChatBotLauncherButton(
        heroTag: 'chatbot-loans',
      ),
    );
  }

  Widget _buildIndicatorItem(
    String label,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
