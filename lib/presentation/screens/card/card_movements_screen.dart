import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/card.dart' as domain;
import '../../../domain/entities/transaction.dart';
import 'package:mobile/core/services/transaction_service.dart';
import '../../../data/repositories/transaction_repository_impl.dart';
import '../../../data/datasources/transaction_datasource.dart';
import '../../../domain/usecases/transaction/process_payment_usecase.dart';
import '../../../domain/usecases/transaction/process_disbursement_usecase.dart';
import '../../../domain/usecases/transaction/get_transaction_history_usecase.dart';
import '../../../domain/usecases/transaction/get_card_transactions_usecase.dart';
import '../../../domain/usecases/transaction/get_account_balance_usecase.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../theme/app_colors.dart';

class CardMovementsScreen extends StatefulWidget {
  final domain.Card card;

  const CardMovementsScreen({Key? key, required this.card}) : super(key: key);

  @override
  State<CardMovementsScreen> createState() => _CardMovementsScreenState();
}

class _CardMovementsScreenState extends State<CardMovementsScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  DateTime? _startDate;
  DateTime? _endDate;
  int _limit = 50;

  @override
  Widget build(BuildContext context) {
    final repository = TransactionRepositoryImpl(
      datasource: TransactionDatasource(),
    );

    print('🔍 CardMovementsScreen: Building with card ID: ${widget.card.id}');
    print('🔍 CardMovementsScreen: Card number: ${widget.card.cardNumber}');

    return BlocProvider(
      create: (context) =>
          TransactionBloc(
            transactionService: TransactionService(
              processPaymentUseCase: ProcessPaymentUseCase(repository),
              processDisbursementUseCase: ProcessDisbursementUseCase(
                repository,
              ),
              getTransactionHistoryUseCase: GetTransactionHistoryUseCase(
                repository,
              ),
              getCardTransactionsUseCase: GetCardTransactionsUseCase(
                repository,
              ),
              getAccountBalanceUseCase: GetAccountBalanceUseCase(repository),
            ),
          )..add(
            GetCardTransactionsEvent(
              mfId: widget.card.microfinancieraId,
              cardId: widget.card.id,
              limit: _limit,
              startDate: _startDate,
              endDate: _endDate,
            ),
          ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Movimientos de Tarjeta',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildCardHeader(),
            Expanded(child: _buildTransactionsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
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
              Icon(_getCardIcon(), color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCardTypeText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatCardNumber(widget.card.cardNumber),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
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
            'Historial de Movimientos',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TransactionError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar movimientos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshTransactions,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (state is CardTransactionsLoaded) {
          if (state.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sin movimientos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No hay transacciones registradas para esta tarjeta',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refreshTransactions(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.transactions.length,
              itemBuilder: (context, index) {
                final transaction = state.transactions[index];
                return _buildTransactionCard(transaction);
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTransactionCard(FinancialTransaction transaction) {
    final isDebit = transaction.debit > 0;
    final amount = isDebit ? transaction.debit : transaction.credit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDebit
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDebit ? Icons.arrow_upward : Icons.arrow_downward,
            color: isDebit ? Colors.red : Colors.green,
            size: 24,
          ),
        ),
        title: Text(
          _getTransactionTypeLabel(transaction.type),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${_dateFormat.format(transaction.createdAt)} • ${_timeFormat.format(transaction.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (transaction.refType.isNotEmpty &&
                transaction.refId.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Ref: ${transaction.refType} - ${transaction.refId.substring(0, 8)}...',
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isDebit ? '-' : '+'}${_currencyFormat.format(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isDebit ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDebit
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isDebit ? 'Débito' : 'Crédito',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDebit ? Colors.red : Colors.green,
                ),
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
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Fecha de inicio'),
                subtitle: Text(
                  _startDate != null
                      ? _dateFormat.format(_startDate!)
                      : 'No seleccionada',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        _startDate ??
                        DateTime.now().subtract(const Duration(days: 30)),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('Fecha de fin'),
                subtitle: Text(
                  _endDate != null
                      ? _dateFormat.format(_endDate!)
                      : 'No seleccionada',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate:
                        _startDate ??
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('Límite de resultados'),
                subtitle: Text('$_limit transacciones'),
                trailing: DropdownButton<int>(
                  value: _limit,
                  items: [25, 50, 100, 200]
                      .map(
                        (limit) => DropdownMenuItem(
                          value: limit,
                          child: Text('$limit'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _limit = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
                _limit = 50;
              });
              Navigator.of(context).pop();
              _refreshTransactions();
            },
            child: const Text('Limpiar'),
          ),
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
    print(
      '🔍 CardMovementsScreen: Refreshing transactions for card ID: ${widget.card.id}',
    );
    print('🔍 CardMovementsScreen: Card number: ${widget.card.cardNumber}');
    print('🔍 CardMovementsScreen: MF ID: ${widget.card.microfinancieraId}');

    context.read<TransactionBloc>().add(
      GetCardTransactionsEvent(
        mfId: widget.card.microfinancieraId,
        cardId: widget.card.id,
        limit: _limit,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  IconData _getCardIcon() {
    switch (widget.card.cardType) {
      case domain.CardType.debit:
        return Icons.payment;
      case domain.CardType.credit:
        return Icons.credit_card;
      case domain.CardType.prepaid:
        return Icons.card_giftcard;
    }
  }

  String _getCardTypeText() {
    switch (widget.card.cardType) {
      case domain.CardType.debit:
        return 'Tarjeta de Débito';
      case domain.CardType.credit:
        return 'Tarjeta de Crédito';
      case domain.CardType.prepaid:
        return 'Tarjeta Prepagada';
    }
  }

  String _formatCardNumber(String cardNumber) {
    if (cardNumber.length < 4) return cardNumber;
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  String _getTransactionTypeLabel(String type) {
    switch (type) {
      case 'PAYMENT':
        return 'Pago de Cuota';
      case 'DISBURSEMENT':
        return 'Desembolso';
      case 'ACCOUNT_DEBIT':
        return 'Débito de Cuenta';
      case 'ACCOUNT_CREDIT':
        return 'Crédito a Cuenta';
      case 'TRANSFER':
        return 'Transferencia';
      case 'PURCHASE':
        return 'Compra';
      case 'WITHDRAWAL':
        return 'Retiro';
      case 'DEPOSIT':
        return 'Depósito';
      default:
        return type;
    }
  }
}
