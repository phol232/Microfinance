import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/transaction_repository_impl.dart';
import '../../../data/datasources/transaction_datasource.dart';
import '../../../domain/entities/account.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/usecases/transaction/get_account_balance_usecase.dart';
import '../../../domain/usecases/transaction/get_transaction_history_usecase.dart';
import '../../../domain/usecases/transaction/get_card_transactions_usecase.dart';
import '../../../domain/usecases/transaction/process_disbursement_usecase.dart';
import '../../../domain/usecases/transaction/process_payment_usecase.dart';
import '../../../services/transaction_service.dart';
import '../../bloc/transaction/transaction_bloc.dart';

class AccountMovementsScreen extends StatefulWidget {
  final Account account;

  const AccountMovementsScreen({
    super.key,
    required this.account,
  });

  @override
  State<AccountMovementsScreen> createState() => _AccountMovementsScreenState();
}

class _AccountMovementsScreenState extends State<AccountMovementsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  final int _limit = 50;

  @override
  void initState() {
    super.initState();
    // Set default date range to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final datasource = TransactionDatasource();
        final repository = TransactionRepositoryImpl(datasource: datasource);
        final transactionService = TransactionService(
          processPaymentUseCase: ProcessPaymentUseCase(repository),
          processDisbursementUseCase: ProcessDisbursementUseCase(repository),
          getTransactionHistoryUseCase: GetTransactionHistoryUseCase(repository),
          getAccountBalanceUseCase: GetAccountBalanceUseCase(repository),
          getCardTransactionsUseCase: GetCardTransactionsUseCase(repository),
        );
        return TransactionBloc(transactionService: transactionService)
          ..add(GetTransactionHistoryEvent(
            mfId: widget.account.microfinancieraId,
            accountId: widget.account.id,
            limit: _limit,
            startDate: _startDate,
            endDate: _endDate,
          ));
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: _getAccountTypeColor(widget.account.accountType),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Movimientos de Cuenta',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.account.accountType.displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: _showFilterDialog,
              icon: const Icon(Icons.filter_list),
            ),
          ],
        ),
        body: Column(
          children: [
            // Account Summary Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getAccountTypeColor(widget.account.accountType),
                    _getAccountTypeColor(widget.account.accountType).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getAccountTypeIcon(widget.account.accountType),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.account.accountType.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '**** ${widget.account.accountNumber.substring(widget.account.accountNumber.length - 4)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Saldo Disponible',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${widget.account.currency} ${widget.account.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Transactions List
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historial de Movimientos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: BlocBuilder<TransactionBloc, TransactionState>(
                        builder: (context, state) {
                          if (state is TransactionLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is TransactionError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.red.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error al cargar movimientos',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    state.message,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _refreshTransactions,
                                    child: const Text('Reintentar'),
                                  ),
                                ],
                              ),
                            );
                          } else if (state is TransactionHistoryLoaded) {
                            if (state.transactions.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Sin movimientos',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No hay transacciones en el período seleccionado',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return RefreshIndicator(
                              onRefresh: () async => _refreshTransactions(),
                              child: ListView.builder(
                                itemCount: state.transactions.length,
                                itemBuilder: (context, index) {
                                  final transaction = state.transactions[index];
                                  return _buildTransactionItem(transaction);
                                },
                              ),
                            );
                          }

                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(FinancialTransaction transaction) {
    final isDebit = transaction.debit > 0;
    final amount = isDebit ? transaction.debit : transaction.credit;
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDebit ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isDebit ? Icons.arrow_upward : Icons.arrow_downward,
            color: isDebit ? Colors.red : Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          _getTransactionTypeText(transaction.type),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formattedDate,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            if (transaction.refType.isNotEmpty)
              Text(
                'Ref: ${transaction.refType} - ${transaction.refId}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isDebit ? '-' : '+'}${transaction.currency} ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDebit ? Colors.red : Colors.green,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Movimientos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Fecha de inicio'),
              subtitle: Text(_startDate != null 
                  ? DateFormat('dd/MM/yyyy').format(_startDate!) 
                  : 'No seleccionada'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('Fecha de fin'),
              subtitle: Text(_endDate != null 
                  ? DateFormat('dd/MM/yyyy').format(_endDate!) 
                  : 'No seleccionada'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _refreshTransactions();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _refreshTransactions() {
    context.read<TransactionBloc>().add(
      GetTransactionHistoryEvent(
        mfId: widget.account.microfinancieraId,
        accountId: widget.account.id,
        limit: _limit,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  Color _getAccountTypeColor(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return Colors.green;
      case AccountType.checking:
        return Colors.blue;
      case AccountType.fixedDeposit:
        return Colors.orange;
      case AccountType.microCredit:
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  IconData _getAccountTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return Icons.savings;
      case AccountType.checking:
        return Icons.account_balance;
      case AccountType.fixedDeposit:
        return Icons.lock;
      case AccountType.microCredit:
        return Icons.monetization_on;
      default:
        return Icons.account_balance;
    }
  }

  String _getTransactionTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return 'Depósito';
      case 'withdrawal':
        return 'Retiro';
      case 'transfer':
        return 'Transferencia';
      case 'payment':
        return 'Pago';
      case 'fee':
        return 'Comisión';
      case 'interest':
        return 'Interés';
      default:
        return type;
    }
  }
}