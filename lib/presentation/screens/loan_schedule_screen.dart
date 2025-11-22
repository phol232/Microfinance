import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:mobile/presentation/bloc/card/card_bloc.dart';
import 'package:mobile/presentation/bloc/transaction/transaction_bloc.dart';
import 'package:mobile/presentation/models/cart_item.dart';
import 'package:mobile/infrastructure/services/cart_service.dart';
import 'package:mobile/infrastructure/services/payment_card_service.dart';
import 'package:mobile/presentation/utils/product_colors.dart';
import 'package:mobile/presentation/widgets/cart_bottom_sheet.dart';

class LoanScheduleScreen extends StatefulWidget {
  final String loanId;
  final Map<String, dynamic> loanData;
  final String microfinancieraId;

  const LoanScheduleScreen({
    Key? key,
    required this.loanId,
    required this.loanData,
    required this.microfinancieraId,
  }) : super(key: key);

  @override
  State<LoanScheduleScreen> createState() => _LoanScheduleScreenState();
}

class _LoanScheduleScreenState extends State<LoanScheduleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CartService _cartService = CartService();
  final PaymentCardService _paymentCardService = PaymentCardService();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/ ',
    decimalDigits: 2,
    customPattern: '¤#,##0.00',
  );
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isMultiSelectMode = false;
  Set<String> _selectedInstallments = {};
  String _searchQuery = '';
  bool _shouldRefreshParent = false;

  late Future<List<Map<String, dynamic>>> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _scheduleFuture = _getRepaymentSchedule();
    _cartService.addListener(_onCartChanged);
    _cartService.loadCart();
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartChanged);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _refreshSchedule() {
    setState(() {
      _scheduleFuture = _getRepaymentSchedule();
    });
  }

  Future<List<Map<String, dynamic>>> _getRepaymentSchedule() async {
    final snapshot = await _firestore
        .collection('microfinancieras')
        .doc(widget.microfinancieraId)
        .collection('loanApplications')
        .doc(widget.loanId)
        .collection('repaymentSchedule')
        .get();

    final schedule = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'installmentNumber': data['installmentNumber'] ?? 0,
        'dueDate': (data['dueDate'] as Timestamp).toDate(),
        'totalPayment': (data['totalPayment'] as num?)?.toDouble() ?? 0.0,
        'principal': (data['principal'] as num?)?.toDouble() ?? 0.0,
        'interest': (data['interest'] as num?)?.toDouble() ?? 0.0,
        'remainingBalance':
            (data['remainingBalance'] as num?)?.toDouble() ?? 0.0,
        'status': data['status'] ?? 'pending',
      };
    }).toList();

    schedule.sort(
      (a, b) => (a['installmentNumber'] as int).compareTo(
        b['installmentNumber'] as int,
      ),
    );

    return schedule;
  }

  Color _getStatusColor(String status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF4CAF50); // Success green
      case 'overdue':
        return colorScheme.error;
      case 'pending':
        return const Color(0xFFFF9800); // Warning orange
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Pagado';
      case 'overdue':
        return 'Vencido';
      case 'pending':
        return 'Pendiente';
      default:
        return status;
    }
  }

  Future<void> _addToCart(Map<String, dynamic> installment) async {
    final personalInfo =
        widget.loanData['personalInfo'] as Map<String, dynamic>? ?? {};
    final productInfo =
        widget.loanData['product'] as Map<String, dynamic>? ?? {};

    final clientName =
        '${personalInfo['firstName'] ?? ''} ${personalInfo['lastName'] ?? ''}'
            .trim();
    final displayName = clientName.isNotEmpty ? clientName : 'Cliente';
    final productCode = productInfo['code'] ?? '';
    final productName = productInfo['name'] ?? 'Crédito';

    final cartItem = CartItem(
      id: installment['id'],
      loanId: widget.loanId,
      installmentNumber: installment['installmentNumber'],
      dueDate: installment['dueDate'],
      totalPayment: (installment['totalPayment'] as num).toDouble(),
      principal: (installment['principal'] as num).toDouble(),
      interest: (installment['interest'] as num).toDouble(),
      productName: productName,
      productCode: productCode,
      clientName: displayName,
    );

    _cartService.addItem(cartItem);
  }

  void _removeFromCart(String installmentId) {
    _cartService.removeItem(installmentId);
  }

  void _enterMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = true;
      _selectedInstallments.clear();
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedInstallments.clear();
    });
  }

  void _toggleInstallmentSelection(String installmentId) {
    setState(() {
      if (_selectedInstallments.contains(installmentId)) {
        _selectedInstallments.remove(installmentId);
      } else {
        _selectedInstallments.add(installmentId);
      }
    });
  }

  Future<void> _addSelectedToCart() async {
    final schedule = await _getRepaymentSchedule();

    int added = 0;
    for (String installmentId in _selectedInstallments) {
      final installment = schedule.firstWhere(
        (inst) => inst['id'] == installmentId,
        orElse: () => <String, dynamic>{},
      );
      if (installment.isNotEmpty && !_cartService.isInCart(installmentId)) {
        await _addToCart(installment);
        added++;
      }
    }

    _exitMultiSelectMode();

    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$added cuota${added > 1 ? 's' : ''} agregada${added > 1 ? 's' : ''} al carrito',
        ),
        backgroundColor: const Color(0xFF4CAF50), // Success green
        action: SnackBarAction(
          label: 'Ver Carrito',
          textColor: colorScheme.onPrimary,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (modalContext) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: context.read<CardBloc>()),
                  BlocProvider.value(value: context.read<TransactionBloc>()),
                ],
                child: CartBottomSheet(
                  cartService: _cartService,
                  paymentCardService: _paymentCardService,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final personalInfo =
        widget.loanData['personalInfo'] as Map<String, dynamic>? ?? {};
    final financialInfo =
        widget.loanData['financialInfo'] as Map<String, dynamic>? ?? {};
    final productInfo =
        widget.loanData['product'] as Map<String, dynamic>? ?? {};

    final clientName =
        '${personalInfo['firstName'] ?? ''} ${personalInfo['lastName'] ?? ''}'
            .trim();
    final displayName = clientName.isNotEmpty ? clientName : 'Cliente';
    final amount = (financialInfo['loanAmount'] ?? 0.0) as num;
    final productCode = productInfo['code'] ?? '';
    final productName = productInfo['name'] ?? 'Crédito';

    final themeColor = ProductColors.getColorByCode(productCode);
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is PaymentProcessed) {
          _shouldRefreshParent = true;
          _refreshSchedule();
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, _shouldRefreshParent);
          return false;
        },
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: Text(
              _isMultiSelectMode
                  ? '${_selectedInstallments.length} seleccionadas'
                  : 'Cronograma de Pagos',
            ),
            backgroundColor: themeColor,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context, _shouldRefreshParent),
            ),
            actions: [
              if (_isMultiSelectMode) ...[
                IconButton(
                  onPressed: _selectedInstallments.isNotEmpty
                      ? _addSelectedToCart
                      : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  tooltip: 'Agregar al carrito',
                ),
                IconButton(
                  onPressed: _exitMultiSelectMode,
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancelar selección',
                ),
              ] else
                IconButton(
                  onPressed: _enterMultiSelectMode,
                  icon: const Icon(Icons.checklist),
                  tooltip: 'Selección múltiple',
                ),
            ],
          ),
          body: Column(
            children: [
              // Encabezado compacto del préstamo
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: themeColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withOpacity(0.2),
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
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              displayName,
                              style: TextStyle(
                                color: colorScheme.onPrimary.withOpacity(0.9),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Monto',
                            style: TextStyle(
                              color: colorScheme.onPrimary.withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            _currencyFormat.format(amount),
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Buscador
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por número de cuota...',
                    prefixIcon: Icon(Icons.search, color: themeColor),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Lista de cuotas
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _scheduleFuture, // <- future cacheado
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
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
                              'Error al cargar el cronograma',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final schedule = snapshot.data ?? [];

                    // Filtrar cuotas según búsqueda
                    final filteredSchedule = _searchQuery.isEmpty
                        ? schedule
                        : schedule.where((installment) {
                            final number = installment['installmentNumber']
                                .toString();
                            final searchLower = _searchQuery.toLowerCase();
                            return number.contains(searchLower) ||
                                'cuota $number'.contains(searchLower) ||
                                '#$number'.contains(searchLower);
                          }).toList();

                    if (schedule.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay cronograma disponible',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (filteredSchedule.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron cuotas',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Intenta con otro término de búsqueda',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      key: PageStorageKey(
                        'loan_schedule_${widget.loanId}',
                      ), // <- preserva posición
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: filteredSchedule.length,
                      itemBuilder: (context, index) {
                        final colorScheme = Theme.of(context).colorScheme;
                        final installment = filteredSchedule[index];
                        final status = (installment['status'] as String);
                        final isPaid = status.toLowerCase() == 'paid';
                        final isOverdue = status.toLowerCase() == 'overdue';
                        final isSelected = _selectedInstallments.contains(
                          installment['id'],
                        );

                        return GestureDetector(
                          onTap: _isMultiSelectMode && !isPaid
                              ? () => _toggleInstallmentSelection(
                                  installment['id'],
                                )
                              : null,
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _isMultiSelectMode && isSelected
                                    ? themeColor
                                    : _getStatusColor(
                                        status,
                                        context,
                                      ).withOpacity(0.3),
                                width: _isMultiSelectMode && isSelected ? 2 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Cuota #${installment['installmentNumber']}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                status,
                                                context,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getStatusText(status),
                                              style: TextStyle(
                                                color: colorScheme.onPrimary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Monto
                                      Text(
                                        _currencyFormat.format(
                                          installment['totalPayment'],
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 12,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _dateFormat.format(
                                                installment['dueDate'],
                                              ),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      Text(
                                        'Capital: ${_currencyFormat.format(installment['principal'])}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        'Interés: ${_currencyFormat.format(installment['interest'])}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const Spacer(),

                                      if (!_isMultiSelectMode)
                                        AnimatedBuilder(
                                          animation: _cartService,
                                          builder: (context, _) {
                                            final isInCart = _cartService.items
                                                .any(
                                                  (item) =>
                                                      item.id ==
                                                      installment['id'],
                                                );
                                            final bg = isPaid
                                                ? colorScheme
                                                      .surfaceContainerHighest
                                                : isInCart
                                                ? const Color(0xFFFF9800)
                                                : (isOverdue
                                                      ? colorScheme.error
                                                      : themeColor);
                                            final fg = isPaid
                                                ? colorScheme.onSurfaceVariant
                                                : colorScheme.onPrimary;

                                            return SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: isPaid
                                                    ? null
                                                    : () async {
                                                        if (isInCart) {
                                                          _removeFromCart(
                                                            installment['id'],
                                                          );
                                                        } else {
                                                          await _addToCart(
                                                            installment,
                                                          );
                                                        }
                                                      },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: bg,
                                                  foregroundColor: fg,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  elevation: isPaid ? 0 : 2,
                                                ),
                                                child: Text(
                                                  isPaid
                                                      ? 'Pagado'
                                                      : isInCart
                                                      ? 'Seleccionado'
                                                      : 'Agregar',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),

                                // Checkbox de selección múltiple
                                if (_isMultiSelectMode && !isPaid)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (_) =>
                                            _toggleInstallmentSelection(
                                              installment['id'],
                                            ),
                                        activeColor: themeColor,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
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
                ),
              ),
            ],
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _cartService,
            builder: (context, _) {
              return _cartService.itemCount > 0
                  ? FloatingActionButton.extended(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (modalContext) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(
                                value: context.read<CardBloc>(),
                              ),
                              BlocProvider.value(
                                value: context.read<TransactionBloc>(),
                              ),
                            ],
                            child: CartBottomSheet(
                              cartService: _cartService,
                              paymentCardService: _paymentCardService,
                            ),
                          ),
                        );
                      },
                      backgroundColor: const Color(0xFFEA580C),
                      icon: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Pagos (${_cartService.itemCount})',
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
