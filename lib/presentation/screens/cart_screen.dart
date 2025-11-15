import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../services/cart_service.dart';
import '../../models/cart_item.dart';
import '../utils/product_colors.dart';
import '../bloc/transaction/transaction_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/profile/profile_bloc.dart';
import '../bloc/profile/profile_state.dart';
import '../bloc/card/card_bloc.dart';
import '../bloc/card/card_event.dart';
import '../bloc/card/card_state.dart';
import '../../services/transaction_service.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/datasources/transaction_datasource.dart';
import '../../domain/usecases/transaction/process_payment_usecase.dart';
import '../../domain/usecases/transaction/process_disbursement_usecase.dart';
import '../../domain/usecases/transaction/get_transaction_history_usecase.dart';
import '../../domain/usecases/transaction/get_card_transactions_usecase.dart';
import '../../domain/usecases/transaction/get_account_balance_usecase.dart';
import '../../domain/entities/card.dart' as domain;

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  String? _selectedPaymentMethod;
  List<domain.Card> _userCards = [];

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_onCartChanged);
    _cartService.loadCart();
    _loadUserCards();
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _loadUserCards() {
    final authState = context.read<AuthBloc>().state;
    final profileState = context.read<ProfileBloc>().state;
    final cardState = context.read<CardBloc>().state;

    print('🔍 CartScreen: Current CardBloc state: ${cardState.runtimeType}');

    // Si ya hay tarjetas cargadas, usarlas inmediatamente
    if (cardState is CardLoaded) {
      print('🔍 CartScreen: Cards already loaded, using existing cards');
      _onCardsLoaded(cardState.cards);
    }

    if (authState is AuthAuthenticated) {
      final microfinancieraId =
          profileState.profile?.microfinancieraId ?? 'mf_demo_001';
      print('🔍 CartScreen: Loading cards for user: ${authState.user.uid}');
      context.read<CardBloc>().add(
        CardLoadUserCards(authState.user.uid, microfinancieraId),
      );
    }
  }

  void _onCardsLoaded(List<domain.Card> cards) {
    print('🔍 CartScreen: Loaded ${cards.length} cards');
    for (var card in cards) {
      print(
        '🔍 CartScreen: Card ID: ${card.id}, AccountID: ${card.accountId}, CardNumber: ${card.cardNumber}',
      );
    }

    setState(() {
      _userCards = cards;
      if (_userCards.isNotEmpty && _selectedPaymentMethod == null) {
        _selectedPaymentMethod = _userCards.first.id;
        print(
          '🔍 CartScreen: Selected payment method: $_selectedPaymentMethod',
        );
      }
    });
  }

  void _addPaymentMethod() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Agregar Método de Pago',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              _buildPaymentMethodOption(
                icon: Icons.credit_card,
                title: 'Tarjeta de Crédito/Débito',
                subtitle: 'Visa, Mastercard, American Express',
                onTap: () => _showCardForm(),
              ),
              const SizedBox(height: 16),
              _buildPaymentMethodOption(
                icon: Icons.account_balance,
                title: 'Transferencia Bancaria',
                subtitle: 'Desde tu cuenta bancaria',
                onTap: () => _showBankTransferForm(),
              ),
              const SizedBox(height: 16),
              _buildPaymentMethodOption(
                icon: Icons.phone_android,
                title: 'Billetera Digital',
                subtitle: 'Yape, Plin, BIM',
                onTap: () => _showDigitalWalletForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEA580C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFFEA580C), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showCardForm() {
    Navigator.pop(context);
    // TODO: Implementar formulario de tarjeta
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulario de tarjeta en desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showBankTransferForm() {
    Navigator.pop(context);
    // TODO: Implementar formulario de transferencia
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transferencia bancaria en desarrollo'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDigitalWalletForm() {
    Navigator.pop(context);
    // TODO: Implementar formulario de billetera digital
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Billetera digital en desarrollo'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _checkout() {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un método de pago'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_cartService.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indicador visual de drag
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Título
            const Text(
              'Confirmar Pago',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Información del pago
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  _currencyFormat.format(_cartService.totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cuotas:', style: TextStyle(fontSize: 16)),
                Text(
                  '${_cartService.itemCount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '¿Confirmas el pago de estas cuotas?',
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Botones
            BlocConsumer<TransactionBloc, TransactionState>(
              listener: (blocContext, state) {
                if (state is TransactionError) {
                  Navigator.pop(sheetContext); // Cerrar bottom sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error al procesar el pago: ${state.message}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (blocContext, state) {
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state is TransactionLoading
                            ? null
                            : () => Navigator.pop(sheetContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFFEA580C)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Color(0xFFEA580C),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: state is TransactionLoading
                            ? null
                            : () {
                                Navigator.pop(
                                  sheetContext,
                                ); // Cerrar bottom sheet
                                _processPayments();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: state is TransactionLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Confirmar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Espacio para botón inferior del teléfono
            SizedBox(height: MediaQuery.of(sheetContext).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _processPayments() async {
    // Obtener datos del usuario autenticado
    final authState = context.read<AuthBloc>().state;
    final profileState = context.read<ProfileBloc>().state;

    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Usuario no autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String microfinancieraId;
    String accountId;
    String branchId;

    final profile = profileState.profile;
    if (profile != null) {
      microfinancieraId = profile.microfinancieraId ?? 'default_mf';
    } else {
      microfinancieraId = 'default_mf';
    }

    // Obtener el accountId de la tarjeta seleccionada
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No hay método de pago seleccionado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedCard = _userCards.firstWhere(
      (card) => card.id == _selectedPaymentMethod,
      orElse: () => throw Exception('Tarjeta no encontrada'),
    );

    accountId = selectedCard.accountId;
    branchId = 'default_branch'; // Valor por defecto para branchId

    print('🔍 CartScreen: Processing payment with accountId: $accountId');
    print('🔍 CartScreen: Selected card ID: ${selectedCard.id}');
    print('🔍 CartScreen: Selected card accountId: ${selectedCard.accountId}');
    print('🔍 CartScreen: Selected card userId: ${selectedCard.userId}');
    print('🔍 CartScreen: Selected card number: ${selectedCard.cardNumber}');
    print('🔍 CartScreen: Current user ID: ${authState.user.uid}');

    // Procesar cada cuota en el carrito
    for (final item in _cartService.items) {
      context.read<TransactionBloc>().add(
        ProcessPaymentEvent(
          mfId: microfinancieraId,
          accountId: accountId,
          loanId: item.loanId,
          installmentId: item.id, // Usar el ID del item como installmentId
          amount: item.totalPayment,
          cardId: _selectedPaymentMethod!,
          branchId: branchId,
        ),
      );

      // Esperar un poco entre transacciones para evitar problemas de concurrencia
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = TransactionRepositoryImpl(
      datasource: TransactionDatasource(),
    );

    return BlocProvider(
      create: (context) => TransactionBloc(
        transactionService: TransactionService(
          processPaymentUseCase: ProcessPaymentUseCase(repository),
          processDisbursementUseCase: ProcessDisbursementUseCase(repository),
          getTransactionHistoryUseCase: GetTransactionHistoryUseCase(
            repository,
          ),
          getCardTransactionsUseCase: GetCardTransactionsUseCase(repository),
          getAccountBalanceUseCase: GetAccountBalanceUseCase(repository),
        ),
      ),
      child: BlocListener<CardBloc, CardState>(
        listener: (context, state) {
          print(
            '🔍 CartScreen: BlocListener received state: ${state.runtimeType}',
          );
          if (state is CardLoaded) {
            print(
              '🔍 CartScreen: CardLoaded state received with ${state.cards.length} cards',
            );
            _onCardsLoaded(state.cards);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text(
              'Carrito de Pagos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFFEA580C),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: _cartService.items.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCartItems(),
                            const SizedBox(height: 24),
                            _buildPaymentMethods(),
                            const SizedBox(height: 24),
                            _buildSummary(),
                          ],
                        ),
                      ),
                    ),
                    _buildCheckoutButton(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega cuotas desde el cronograma de pagos',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Volver al Cronograma'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuotas Seleccionadas (${_cartService.itemCount})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cartService.items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _cartService.items[index];
            return _buildCartItem(item);
          },
        ),
      ],
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ProductColors.getColorByCode(
                      item.productCode,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.productCode,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ProductColors.getColorByCode(item.productCode),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _cartService.removeItem(item.id),
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey[600],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.productName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              item.clientName,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cuota #${item.installmentNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Vence: ${_dateFormat.format(item.dueDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  _currencyFormat.format(item.totalPayment),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Método de Pago',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addPaymentMethod,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFEA580C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_userCards.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.credit_card_off, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'No hay métodos de pago',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Agrega una tarjeta o método de pago',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _userCards.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final card = _userCards[index];
              final isSelected = _selectedPaymentMethod == card.id;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = card.id;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFEA580C)
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.credit_card,
                        color: isSelected
                            ? const Color(0xFFEA580C)
                            : Colors.grey[600],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '****${card.cardNumber.substring(card.cardNumber.length - 4)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFFEA580C)
                                    : Colors.black,
                              ),
                            ),
                            Text(
                              '${card.cardBrand.displayName} ${card.cardType.displayName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFFEA580C),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del Pago',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal (${_cartService.itemCount} cuotas)',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              Text(
                _currencyFormat.format(_cartService.totalAmount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comisión',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              Text(
                _currencyFormat.format(0),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                _currencyFormat.format(_cartService.totalAmount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEA580C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _checkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Pagar ${_currencyFormat.format(_cartService.totalAmount)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
