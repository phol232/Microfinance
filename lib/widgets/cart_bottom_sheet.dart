import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/payment_card.dart';
import '../services/cart_service.dart';
import '../services/payment_card_service.dart';
import '../presentation/utils/product_colors.dart';
import '../presentation/bloc/card/card_bloc.dart';
import '../presentation/bloc/card/card_state.dart';
import '../presentation/bloc/card/card_event.dart';
import '../presentation/bloc/auth/auth_bloc.dart';
import '../presentation/bloc/auth/auth_state.dart';
import '../presentation/bloc/profile/profile_bloc.dart';
import '../presentation/bloc/transaction/transaction_bloc.dart';
import '../presentation/screens/payment_success_screen.dart';
import '../presentation/screens/payment_processing_screen.dart';
import '../data/datasources/transaction_datasource.dart';

class CartBottomSheet extends StatefulWidget {
  final CartService cartService;
  final PaymentCardService paymentCardService;

  const CartBottomSheet({
    Key? key,
    required this.cartService,
    required this.paymentCardService,
  }) : super(key: key);

  @override
  State<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  PaymentCard? _selectedCard;
  bool _showPaymentMethods = false;
  String? _validationError;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentCards();
  }

  void _loadPaymentCards() async {
    try {
      // Obtener datos del usuario autenticado
      final authState = context.read<AuthBloc>().state;
      final profileState = context.read<ProfileBloc>().state;

      if (authState is! AuthAuthenticated) {
        if (mounted) {
          setState(() {
            _selectedCard = widget.paymentCardService.defaultCard;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario no autenticado')),
          );
        }
        return;
      }

      final userId = authState.user.uid;
      final microfinancieraId =
          profileState.profile?.microfinancieraId ?? 'mf_demo_001';

      // Load user cards from CardBloc
      final cardBloc = context.read<CardBloc>();
      if (cardBloc.state is CardLoaded) {
        final cards = (cardBloc.state as CardLoaded).cards;
        widget.paymentCardService.updateFromRealCards(cards);
        _selectedCard = widget.paymentCardService.defaultCard;
      } else {
        cardBloc.add(CardLoadUserCards(userId, microfinancieraId));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedCard = widget.paymentCardService.defaultCard;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar tarjetas: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CardBloc, CardState>(
      listener: (context, state) {
        if (state is CardLoaded) {
          widget.paymentCardService.updateFromRealCards(state.cards);
          setState(() {
            _selectedCard = widget.paymentCardService.defaultCard;
          });
        }
      },
      child: ListenableBuilder(
        listenable: widget.cartService,
        builder: (context, child) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Expanded(
                        child: Text(
                          'Pagos Pendientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_horiz),
                      ),
                    ],
                  ),
                ),

                // Cart items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.cartService.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartService.items[index];
                      return _buildCartItem(item);
                    },
                  ),
                ),

                // Payment method section
                if (_showPaymentMethods) _buildPaymentMethodsSection(),

                // Bottom section
                _buildBottomSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Product image placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.credit_card,
              color: ProductColors.getColorByCode(item.productCode),
              size: 30,
            ),
          ),

          const SizedBox(width: 12),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${item.productName}, Cuota ${item.installmentNumber}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'S/ ${item.totalPayment.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            onPressed: () {
              widget.cartService.removeItem(item.id);
            },
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: 24,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showPaymentMethods = false;
                  });
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Payment cards list
          ...widget.paymentCardService.cards
              .map((card) => _buildPaymentMethodItem(card))
              .toList(),

          // Add new card button
          GestureDetector(
            onTap: _showAddCardDialog,
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[300]!,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Icon(Icons.add, color: Colors.grey, size: 16),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agregar nueva tarjeta',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Añadir método de pago',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Promo code section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.percent,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Promo Code or Voucher',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Savings with Your Promo Code!',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem(PaymentCard card) {
    final isSelected = _selectedCard?.id == card.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCard = card;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFEA580C) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Card icon
            Container(
              width: 40,
              height: 25,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: card.cardType.toLowerCase() == 'visa'
                      ? [Colors.blue, Colors.indigo]
                      : [Colors.red, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  card.cardType.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.maskedCardNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        card.cardHolderName,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (card.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Principal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Card actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleCardAction(value, card),
              itemBuilder: (context) => [
                if (!card.isDefault)
                  const PopupMenuItem(
                    value: 'set_default',
                    child: Row(
                      children: [
                        Icon(Icons.star_outline, size: 16),
                        SizedBox(width: 8),
                        Text('Establecer como principal'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: Icon(
                isSelected ? Icons.check_circle : Icons.more_vert,
                color: isSelected ? const Color(0xFFEA580C) : Colors.grey,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCardAction(String action, PaymentCard card) {
    switch (action) {
      case 'set_default':
        widget.paymentCardService.setDefaultCard(card.id);
        setState(() {
          _selectedCard = card;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarjeta establecida como principal'),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case 'delete':
        _showDeleteCardDialog(card);
        break;
    }
  }

  void _showDeleteCardDialog(PaymentCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarjeta'),
        content: Text(
          '¿Estás seguro de que quieres eliminar la tarjeta ${card.maskedCardNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              widget.paymentCardService.removeCard(card.id);
              if (_selectedCard?.id == card.id) {
                setState(() {
                  _selectedCard = widget.paymentCardService.defaultCard;
                });
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tarjeta eliminada'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog() {
    final cardNumberController = TextEditingController();
    final cardHolderController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar nueva tarjeta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de tarjeta',
                  hintText: '1234 5678 9012 3456',
                ),
                keyboardType: TextInputType.number,
                maxLength: 19,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cardHolderController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del titular',
                  hintText: 'Juan Pérez',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expiryController,
                      decoration: const InputDecoration(
                        labelText: 'MM/AA',
                        hintText: '12/25',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _addNewCard(
              cardNumberController.text,
              cardHolderController.text,
              expiryController.text,
              cvvController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _addNewCard(
    String cardNumber,
    String cardHolder,
    String expiry,
    String cvv,
  ) {
    if (cardNumber.isEmpty ||
        cardHolder.isEmpty ||
        expiry.isEmpty ||
        cvv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Determine card type based on first digit
    String cardType = 'VISA';
    if (cardNumber.startsWith('5')) {
      cardType = 'MASTERCARD';
    } else if (cardNumber.startsWith('3')) {
      cardType = 'AMEX';
    }

    final newCard = PaymentCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardNumber: cardNumber.replaceAll(' ', ''),
      cardHolderName: cardHolder,
      expiryDate: expiry,
      cardType: cardType,
      isDefault: widget.paymentCardService.cards.isEmpty,
    );

    widget.paymentCardService.addCard(newCard);

    setState(() {
      _selectedCard = newCard;
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tarjeta agregada exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildBottomSection() {
    final subtotal = widget.cartService.totalAmount;
    const shipping = 00.0;
    final total = subtotal + shipping;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Payment method selector
          if (!_showPaymentMethods && _selectedCard != null)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showPaymentMethods = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 25,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              _selectedCard!.cardType.toLowerCase() == 'visa'
                              ? [Colors.blue, Colors.indigo]
                              : [Colors.red, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text('💳', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCard!.maskedCardNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'Payment Method',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),

          // Price breakdown
          if (!_showPaymentMethods) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sub Total'),
                Text('S/ ${subtotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Comisión'),
                Text('S/ ${shipping.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total a Pagar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'S/ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Checkout button
          if (!_showPaymentMethods)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _processCheckout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Procesar Pago (${widget.cartService.itemCount})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _processCheckout() {
    if (_selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un método de pago'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.cartService.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
    final cardBloc = context.read<CardBloc>();
    if (cardBloc.state is! CardLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se han cargado las tarjetas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cards = (cardBloc.state as CardLoaded).cards;
    final selectedRealCard = cards.firstWhere(
      (card) => card.id == _selectedCard!.id,
      orElse: () {
        // Si no encuentra la tarjeta por ID, buscar por número de tarjeta
        return cards.firstWhere(
          (card) => card.cardNumber.endsWith(
            _selectedCard!.cardNumber
                .replaceAll(' ', '')
                .substring(
                  _selectedCard!.cardNumber.replaceAll(' ', '').length - 4,
                ),
          ),
          orElse: () => cards.first, // Usar la primera tarjeta como fallback
        );
      },
    );

    accountId = selectedRealCard.accountId;
    branchId = 'default_branch'; // Valor por defecto para branchId

    print('🔍 CartBottomSheet: Selected card ID: ${_selectedCard!.id}');
    print('🔍 CartBottomSheet: Real card ID: ${selectedRealCard.id}');
    print('🔍 CartBottomSheet: Account ID from card: $accountId');
    print('🔍 CartBottomSheet: User ID: ${authState.user.uid}');

    // Mostrar bottom sheet de confirmación
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _ConfirmPaymentBottomSheet(
        cartService: widget.cartService,
        microfinancieraId: microfinancieraId,
        accountId: accountId,
        cardId: selectedRealCard.id,
        branchId: branchId,
        onConfirm: () {
          Navigator.pop(sheetContext);
          _processPayments(
            microfinancieraId: microfinancieraId,
            accountId: accountId,
            cardId: selectedRealCard.id,
            branchId: branchId,
          );
        },
      ),
    );
  }

  void _processPayments({
    required String microfinancieraId,
    required String accountId,
    required String cardId,
    required String branchId,
  }) async {
    print(
      '🎯 CartBottomSheet: Starting payment processing for ${widget.cartService.itemCount} items',
    );
    print('🎯 CartBottomSheet: Using accountId: $accountId');
    print('🎯 CartBottomSheet: Using cardId: $cardId');

    // La validación ya se hizo antes de cerrar el bottom sheet, pero la hacemos de nuevo por seguridad
    final validationError = await _validatePaymentOrder(microfinancieraId);
    if (validationError != null) {
      if (!mounted) return;
      debugPrint('🚫 Validación falló (segunda verificación): $validationError');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  validationError,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          action: SnackBarAction(
            label: 'Entendido',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      return;
    }

    // Capturar el TransactionBloc ANTES de navegar
    final transactionBloc = context.read<TransactionBloc>();
    
    // Cerrar el bottom sheet de confirmación primero
    Navigator.pop(context);

    print('🔍 CartBottomSheet: Bottom sheet cerrado, navegando INMEDIATAMENTE a PaymentProcessingScreen');

    // Navegar INMEDIATAMENTE a la pantalla de procesamiento
    // ANTES de hacer cualquier operación asíncrona
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentProcessingScreen(
          onComplete: () async {
            print('🔍 PaymentProcessingScreen: Iniciando procesamiento de pagos...');
            
            try {
              // Ahora sí, hacer todos los cálculos dentro del callback
              final datasource = TransactionDatasource();
              print('🔍 PaymentProcessingScreen: Calculando balance anterior...');
              
              final previousBalance = await datasource.calculateAccountBalance(
                mfId: microfinancieraId,
                accountId: accountId,
              );

              print('🔍 PaymentProcessingScreen: Balance anterior calculado: $previousBalance');

              // Guardar detalles de pagos para la pantalla de éxito
              final paymentDetails = <PaymentDetail>[];
              for (final item in widget.cartService.items) {
                paymentDetails.add(
                  PaymentDetail(
                    description: '${item.productCode} - ${item.productName}',
                    installmentNumber: item.installmentNumber,
                    amount: item.totalPayment,
                  ),
                );
              }

              final totalAmount = widget.cartService.totalAmount;
              final newBalance = previousBalance - totalAmount;

              // Usar el transactionBloc capturado antes de navegar
              print('🔍 PaymentProcessingScreen: Procesando pagos con TransactionBloc...');
              
              for (final item in widget.cartService.items) {
                print('🎯 PaymentProcessingScreen: Processing payment for item ${item.id}');

                transactionBloc.add(
                  ProcessPaymentEvent(
                    mfId: microfinancieraId,
                    accountId: accountId,
                    loanId: item.loanId,
                    installmentId: item.id,
                    amount: item.totalPayment,
                    cardId: cardId,
                    branchId: branchId,
                  ),
                );

                await Future.delayed(const Duration(milliseconds: 500));
              }

              // Esperar tiempo razonable para que se procesen los pagos
              await Future.delayed(const Duration(seconds: 2));

              // Limpiar carrito
              widget.cartService.clearCart();

              if (!context.mounted) {
                print('⚠️ PaymentProcessingScreen: Context no montado');
                return;
              }

              print('🎉 PaymentProcessingScreen: Payment processing completed, navigating to success screen');

              // Navegar a pantalla de éxito desde el contexto de PaymentProcessingScreen
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => PaymentSuccessScreen(
                    payments: paymentDetails,
                    totalAmount: totalAmount,
                    previousBalance: previousBalance,
                    newBalance: newBalance,
                  ),
                ),
              );
            } catch (error) {
              print('❌ PaymentProcessingScreen: Error procesando pagos: $error');
              
              if (!context.mounted) return;
              
              // Cerrar pantalla de procesamiento y mostrar error
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Error al procesar los pagos: $error'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  /// Valida que todas las cuotas en el carrito puedan pagarse en orden
  /// Retorna un mensaje de error si hay problemas, null si todo está bien
  Future<String?> _validatePaymentOrder(String microfinancieraId) async {
    final firestore = FirebaseFirestore.instance;
    
    // Agrupar cuotas por préstamo
    final Map<String, List<CartItem>> itemsByLoan = {};
    for (final item in widget.cartService.items) {
      if (!itemsByLoan.containsKey(item.loanId)) {
        itemsByLoan[item.loanId] = [];
      }
      itemsByLoan[item.loanId]!.add(item);
    }

    // Validar cada préstamo
    for (final entry in itemsByLoan.entries) {
      final loanId = entry.key;
      final items = entry.value;
      
      // Obtener cronograma del préstamo
      try {
        final scheduleSnapshot = await firestore
            .collection('microfinancieras')
            .doc(microfinancieraId)
            .collection('loanApplications')
            .doc(loanId)
            .collection('repaymentSchedule')
            .get();

        if (scheduleSnapshot.docs.isEmpty) {
          debugPrint('⚠️ No se encontró cronograma para el préstamo $loanId');
          continue; // Si no hay cronograma, continuar con el siguiente préstamo
        }

        final schedule = scheduleSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'installmentNumber': data['installmentNumber'] ?? 0,
            'status': data['status'] ?? 'pending',
          };
        }).toList();

        // Ordenar por número de cuota
        schedule.sort((a, b) => 
          (a['installmentNumber'] as int).compareTo(b['installmentNumber'] as int)
        );

        // Obtener números de cuotas en el carrito para este préstamo
        final cartInstallmentNumbers = items
            .map((item) => item.installmentNumber)
            .toList()
          ..sort();

        if (cartInstallmentNumbers.isEmpty) {
          continue;
        }

        debugPrint('🔍 Validando orden: Cuotas en carrito: $cartInstallmentNumbers');
        debugPrint('🔍 Cronograma completo: ${schedule.map((s) => '${s['installmentNumber']}: ${s['status']}').join(', ')}');

        // Encontrar la primera cuota pendiente antes de las cuotas en el carrito
        int? firstUnpaidNumber;
        for (var inst in schedule) {
          final instNumber = inst['installmentNumber'] as int;
          final instStatus = (inst['status'] as String).toLowerCase();
          
          // Si esta cuota es anterior a la primera del carrito y no está pagada
          if (instNumber < cartInstallmentNumbers.first && instStatus != 'paid') {
            firstUnpaidNumber = instNumber;
            debugPrint('⚠️ Encontrada cuota pendiente: #$instNumber');
            break;
          }
        }

        if (firstUnpaidNumber != null) {
          final errorMsg = 'Primero debes pagar la cuota #$firstUnpaidNumber. Las cuotas deben pagarse en orden.';
          debugPrint('❌ Error de validación: $errorMsg');
          return errorMsg;
        }

        // Validar que las cuotas en el carrito estén en orden consecutivo
        for (int i = 0; i < cartInstallmentNumbers.length - 1; i++) {
          final current = cartInstallmentNumbers[i];
          final next = cartInstallmentNumbers[i + 1];
          
          // Verificar que no haya cuotas pendientes entre la actual y la siguiente
          for (var inst in schedule) {
            final instNumber = inst['installmentNumber'] as int;
            final instStatus = (inst['status'] as String).toLowerCase();
            
            if (instNumber > current && 
                instNumber < next && 
                instStatus != 'paid') {
              final errorMsg = 'No puedes pagar la cuota #$next sin pagar primero la cuota #$instNumber. Las cuotas deben pagarse en orden.';
              debugPrint('❌ Error de validación: $errorMsg');
              return errorMsg;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error validando orden de pagos: $e');
        // Si hay error al obtener el cronograma, permitir el pago
        // pero registrar el error
      }
    }

    debugPrint('✅ Validación de orden completada: Todo está bien');
    return null; // Todo está bien
  }
}

/// Widget separado para el bottom sheet de confirmación de pago
class _ConfirmPaymentBottomSheet extends StatefulWidget {
  final CartService cartService;
  final String microfinancieraId;
  final String accountId;
  final String cardId;
  final String branchId;
  final VoidCallback onConfirm;

  const _ConfirmPaymentBottomSheet({
    required this.cartService,
    required this.microfinancieraId,
    required this.accountId,
    required this.cardId,
    required this.branchId,
    required this.onConfirm,
  });

  @override
  State<_ConfirmPaymentBottomSheet> createState() => _ConfirmPaymentBottomSheetState();
}

class _ConfirmPaymentBottomSheetState extends State<_ConfirmPaymentBottomSheet> {
  String? _validationError;
  bool _isValidating = false;

  Future<String?> _validatePaymentOrder(String microfinancieraId) async {
    final firestore = FirebaseFirestore.instance;
    
    // Agrupar cuotas por préstamo
    final Map<String, List<CartItem>> itemsByLoan = {};
    for (final item in widget.cartService.items) {
      if (!itemsByLoan.containsKey(item.loanId)) {
        itemsByLoan[item.loanId] = [];
      }
      itemsByLoan[item.loanId]!.add(item);
    }

    // Validar cada préstamo
    for (final entry in itemsByLoan.entries) {
      final loanId = entry.key;
      final items = entry.value;
      
      // Obtener cronograma del préstamo
      try {
        final scheduleSnapshot = await firestore
            .collection('microfinancieras')
            .doc(microfinancieraId)
            .collection('loanApplications')
            .doc(loanId)
            .collection('repaymentSchedule')
            .get();

        if (scheduleSnapshot.docs.isEmpty) {
          debugPrint('⚠️ No se encontró cronograma para el préstamo $loanId');
          continue;
        }

        final schedule = scheduleSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'installmentNumber': data['installmentNumber'] ?? 0,
            'status': data['status'] ?? 'pending',
          };
        }).toList();

        schedule.sort((a, b) => 
          (a['installmentNumber'] as int).compareTo(b['installmentNumber'] as int)
        );

        final cartInstallmentNumbers = items
            .map((item) => item.installmentNumber)
            .toList()
          ..sort();

        if (cartInstallmentNumbers.isEmpty) {
          continue;
        }

        debugPrint('🔍 Validando orden: Cuotas en carrito: $cartInstallmentNumbers');
        debugPrint('🔍 Cronograma completo: ${schedule.map((s) => '${s['installmentNumber']}: ${s['status']}').join(', ')}');

        // Encontrar la primera cuota pendiente antes de las cuotas en el carrito
        int? firstUnpaidNumber;
        for (var inst in schedule) {
          final instNumber = inst['installmentNumber'] as int;
          final instStatus = (inst['status'] as String).toLowerCase();
          
          if (instNumber < cartInstallmentNumbers.first && instStatus != 'paid') {
            firstUnpaidNumber = instNumber;
            debugPrint('⚠️ Encontrada cuota pendiente: #$instNumber');
            break;
          }
        }

        if (firstUnpaidNumber != null) {
          final errorMsg = 'Primero debes pagar la cuota #$firstUnpaidNumber. Las cuotas deben pagarse en orden.';
          debugPrint('❌ Error de validación: $errorMsg');
          return errorMsg;
        }

        // Validar que las cuotas en el carrito estén en orden consecutivo
        for (int i = 0; i < cartInstallmentNumbers.length - 1; i++) {
          final current = cartInstallmentNumbers[i];
          final next = cartInstallmentNumbers[i + 1];
          
          for (var inst in schedule) {
            final instNumber = inst['installmentNumber'] as int;
            final instStatus = (inst['status'] as String).toLowerCase();
            
            if (instNumber > current && 
                instNumber < next && 
                instStatus != 'paid') {
              final errorMsg = 'No puedes pagar la cuota #$next sin pagar primero la cuota #$instNumber. Las cuotas deben pagarse en orden.';
              debugPrint('❌ Error de validación: $errorMsg');
              return errorMsg;
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error validando orden de pagos: $e');
      }
    }

    debugPrint('✅ Validación de orden completada: Todo está bien');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
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
                  'S/ ${widget.cartService.totalAmount.toStringAsFixed(2)}',
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
                  '${widget.cartService.itemCount}',
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
          // Mensaje de error de validación (si existe)
          if (_validationError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _validationError!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
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
                  onPressed: _isValidating ? null : () async {
                    setState(() {
                      _isValidating = true;
                      _validationError = null;
                    });

                    // Validar antes de cerrar el bottom sheet
                    final validationError = await _validatePaymentOrder(widget.microfinancieraId);
                    
                    if (validationError != null) {
                      // Mostrar error dentro del bottom sheet
                      setState(() {
                        _validationError = validationError;
                        _isValidating = false;
                      });
                      return;
                    }
                    
                    // Si la validación pasó, cerrar y procesar
                    setState(() {
                      _validationError = null;
                      _isValidating = false;
                    });
                    widget.onConfirm();
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
                  child: _isValidating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
            ),
          ],
      ),
    );
  }
}
