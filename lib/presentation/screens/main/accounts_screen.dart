import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../domain/entities/account.dart';
import '../../../domain/entities/card.dart' as domain;
import 'package:mobile/core/services/biometric_auth_service.dart';
import 'package:mobile/core/tenant/tenant_controller.dart';
import '../../bloc/account/account_bloc.dart';
import '../../bloc/account/account_event.dart';
import '../../bloc/account/account_state.dart';
import '../../bloc/card/card_bloc.dart';
import '../../bloc/card/card_event.dart';
import '../../bloc/card/card_state.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../account_creation_screen.dart';
import '../account_details_screen.dart';
import '../account/account_movements_screen.dart';
import '../card_info_screen.dart';
import '../card/card_request_screen.dart';
import '../../widgets/chatbot/chatbot_launcher.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Variables para filtros y búsqueda
  AccountType? _selectedAccountType;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserAccounts();
    _loadUserCards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadUserAccounts() {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      context.read<AccountBloc>().add(AccountLoadUserAccounts(uid));
    }
  }

  String? _resolveMicrofinancieraId() {
    final profileState = context.read<ProfileBloc>().state;
    final tenantId = context.read<TenantController>().tenantId;
    return profileState.profile?.microfinancieraId ?? tenantId;
  }

  bool _ensureTenantAvailable() {
    final microId = _resolveMicrofinancieraId();
    if (microId == null || microId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se ha seleccionado una microfinanciera. Inicia sesión nuevamente.',
            ),
          ),
        );
      }
      return false;
    }
    return true;
  }

  void _loadUserCards() {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final microfinancieraId = _resolveMicrofinancieraId();
      if (microfinancieraId == null) {
        _ensureTenantAvailable();
        return;
      }
      context.read<CardBloc>().add(CardLoadUserCards(uid, microfinancieraId));
    }
  }

  // Métodos para filtros y búsqueda
  List<Account> _filterAccounts(List<Account> accounts) {
    List<Account> filteredAccounts = accounts;

    // Filtrar por tipo de cuenta
    if (_selectedAccountType != null) {
      filteredAccounts = filteredAccounts
          .where((account) => account.accountType == _selectedAccountType)
          .toList();
    }

    // Filtrar por búsqueda (número de cuenta)
    if (_searchQuery.isNotEmpty) {
      filteredAccounts = filteredAccounts
          .where((account) => account.accountNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filteredAccounts;
  }

  void _clearFilters() {
    setState(() {
      _selectedAccountType = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _showCreateAccountModal() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    final microfinancieraId = _resolveMicrofinancieraId();
    if (microfinancieraId == null) {
      _ensureTenantAvailable();
      return;
    }
    
    // Obtener las cuentas existentes del usuario
    final accountState = context.read<AccountBloc>().state;
    List<Account> existingAccounts = [];
    if (accountState is AccountLoaded) {
      existingAccounts = accountState.accounts;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccountCreationScreen(
          userId: uid,
          microfinancieraId: microfinancieraId,
          existingAccounts: existingAccounts,
        ),
      ),
    ).then((_) {
      // Reload accounts and cards after modal closes
      _loadUserAccounts();
      _loadUserCards();
    });
  }

  void _showCreateCardModal(String accountId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final accountState = context.read<AccountBloc>().state;
    List<Account> userAccounts = [];
    if (accountState is AccountLoaded) {
      userAccounts = accountState.accounts;
    }

    final microfinancieraId = _resolveMicrofinancieraId();
    if (microfinancieraId == null) {
      _ensureTenantAvailable();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CardRequestScreen(
          userAccounts: userAccounts,
          userId: uid,
          microfinancieraId: microfinancieraId,
        ),
      ),
    ).then((_) {
      if (mounted) {
        // Cargar todas las tarjetas del usuario después de regresar
        context.read<CardBloc>().add(CardLoadUserCards(uid, microfinancieraId));
      }
    });
  }

  void _showCardRequestStatus(String accountId) {
    final cardState = context.read<CardBloc>().state;
    if (cardState is CardLoaded) {
      final pendingCard = cardState.cards.firstWhere(
        (card) => card.accountId == accountId &&
            (card.status == domain.CardStatus.requested ||
             card.status == domain.CardStatus.approved ||
             card.status == domain.CardStatus.inProduction),
        orElse: () => throw StateError('No pending card found'),
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Estado de Solicitud de Tarjeta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipo: ${pendingCard.cardType.displayName}'),
              Text('Marca: ${pendingCard.cardBrand.displayName}'),
              Text('Estado: ${pendingCard.status.displayName}'),
              const SizedBox(height: 16),
              Text(
                _getCardStatusDescription(pendingCard.status),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  String _getCardStatusDescription(domain.CardStatus status) {
    switch (status) {
      case domain.CardStatus.requested:
        return 'Tu solicitud de tarjeta ha sido recibida y está siendo procesada.';
      case domain.CardStatus.approved:
        return 'Tu solicitud ha sido aprobada y la tarjeta está siendo preparada.';
      case domain.CardStatus.inProduction:
        return 'Tu tarjeta está en producción y será enviada pronto.';
      case domain.CardStatus.delivered:
        return 'Tu tarjeta ha sido entregada.';
      case domain.CardStatus.active:
        return 'Tu tarjeta está activa y lista para usar.';
      case domain.CardStatus.blocked:
        return 'Tu tarjeta está bloqueada.';
      case domain.CardStatus.expired:
        return 'Tu tarjeta ha expirado.';
      case domain.CardStatus.cancelled:
        return 'Tu tarjeta ha sido cancelada.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('Inicia sesión para ver tus cuentas'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tus Cuentas'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadUserAccounts();
        },
        child: BlocBuilder<AccountBloc, AccountState>(
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04, // 4% del ancho
                vertical: 12,
              ),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.01), // 1% de la altura

                // Filtros y buscador
                _buildFiltersSection(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                if (state is AccountLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state is AccountError)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar las cuentas',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(state.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadUserAccounts,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (state is AccountLoaded && state.accounts.isEmpty)
                  _buildEmptyState()
                else if (state is AccountLoaded) ...[
                  // Aplicar filtros a las cuentas
                  ...() {
                    final filteredAccounts = _filterAccounts(state.accounts);
                    if (filteredAccounts.isEmpty && (state.accounts.isNotEmpty)) {
                      return [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No se encontraron cuentas',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Intenta ajustar los filtros de búsqueda',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _clearFilters,
                                  icon: const Icon(Icons.clear_all),
                                  label: const Text('Limpiar filtros'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ];
                    }
                    return filteredAccounts.map((account) => _buildAccountCard(account)).toList();
                  }(),
                ]
                else if (state is AccountCreating)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Creando cuenta...'),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const ChatBotLauncherButton(heroTag: 'chatbot-accounts'),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create-account-fab',
            onPressed: _showCreateAccountModal,
            icon: const Icon(Icons.add),
            label: const Text('Crear cuenta'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Column(
      children: [
        // Buscador por número de cuenta
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar por número de cuenta...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.015,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        SizedBox(height: screenHeight * 0.015),

        // Filtro por tipo de cuenta
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<AccountType?>(
                value: _selectedAccountType,
                decoration: InputDecoration(
                  labelText: 'Filtrar por tipo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.015,
                  ),
                ),
                items: [
                  const DropdownMenuItem<AccountType?>(
                    value: null,
                    child: Text('Todos los tipos'),
                  ),
                  ...AccountType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedAccountType = value;
                  });
                },
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            if (_selectedAccountType != null || _searchQuery.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all, size: 18),
                label: Text(
                  'Limpiar',
                  style: TextStyle(fontSize: screenWidth * 0.035),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.012,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_outlined,
                    size: 48,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡Bienvenido a tu banca digital!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aún no tienes cuentas en nuestra microfinanciera',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        color: Colors.green.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Beneficios de crear tu cuenta:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Acceso a préstamos\n• Tarjetas de débito\n• Transferencias gratuitas\n• Ahorro con intereses',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showCreateAccountModal,
                    icon: const Icon(Icons.add),
                    label: const Text('Crear mi primera cuenta'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      '¿Necesitas ayuda?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nuestros asesores están disponibles para ayudarte con el proceso de apertura de cuenta.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Función próximamente disponible'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Chat'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Función próximamente disponible'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Llamar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(Account account) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Card(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02), // 2% de la altura
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.02), // 2% del ancho
                  decoration: BoxDecoration(
                    color: _getAccountTypeColor(account.accountType),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getAccountTypeIcon(account.accountType),
                    color: Colors.white,
                    size: screenWidth * 0.06, // 6% del ancho
                  ),
                ),
                SizedBox(width: screenWidth * 0.03), // 3% del ancho
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.accountType.displayName,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04, // 4% del ancho
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'N° ${_maskAccountNumber(account.accountNumber, account.status)}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035, // 3.5% del ancho
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'CCI: ${_maskCCI(account.cci, account.status)}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03, // 3% del ancho
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Tasa: ${account.interestRate.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03, // 3% del ancho
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${account.currency} ${account.balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045, // 4.5% del ancho
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02, // 2% del ancho
                        vertical: screenHeight * 0.003, // 0.3% de la altura
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(account.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        account.status.displayName,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03, // 3% del ancho
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02), // 2% de la altura
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAccountDetailsModal(account),
                    icon: Icon(Icons.info_outline, size: screenWidth * 0.04),
                    label: Text(
                      'Ver información',
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.015, // 1.5% de la altura
                        horizontal: screenWidth * 0.02, // 2% del ancho
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02), // 2% del ancho
                Expanded(
                  child: BlocBuilder<CardBloc, CardState>(
                    builder: (context, cardState) {
                      bool hasPendingCard = false;
                      if (cardState is CardLoaded) {
                        hasPendingCard = cardState.cards.any((card) =>
                            card.accountId == account.id &&
                            (card.status == domain.CardStatus.requested ||
                             card.status == domain.CardStatus.approved ||
                             card.status == domain.CardStatus.inProduction));
                      }

                      // Solo habilitar el botón si la cuenta está activa
                      final bool isAccountActive = account.status == AccountStatus.active;
                      final bool canRequestCard = isAccountActive && !hasPendingCard;

                      return ElevatedButton.icon(
                        onPressed: hasPendingCard
                            ? () => _showCardRequestStatus(account.id)
                            : (canRequestCard ? () => _showCreateCardModal(account.id) : null),
                        icon: Icon(
                          hasPendingCard ? Icons.visibility : Icons.credit_card,
                          size: screenWidth * 0.04,
                        ),
                        label: Text(
                          hasPendingCard ? 'Ver solicitud' : 'Solicitar tarjeta',
                          style: TextStyle(fontSize: screenWidth * 0.035),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canRequestCard || hasPendingCard ? null : Colors.grey,
                          foregroundColor: canRequestCard || hasPendingCard ? null : Colors.grey.shade600,
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.015, // 1.5% de la altura
                            horizontal: screenWidth * 0.02, // 2% del ancho
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.01), // 1% de la altura
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AccountMovementsScreen(account: account),
                        ),
                      );
                    },
                    icon: Icon(Icons.history, size: screenWidth * 0.04),
                    label: Text(
                      'Movimientos',
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.015, // 1.5% de la altura
                        horizontal: screenWidth * 0.02, // 2% del ancho
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.01), // 1% de la altura
            _buildCardsList(account.id),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsList(String accountId) {
    return BlocBuilder<CardBloc, CardState>(
      builder: (context, state) {
        if (state is CardLoading) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CardLoaded && state.cards.isNotEmpty) {
          final accountCards = state.cards
              .where((card) => card.accountId == accountId)
              .toList();

          if (accountCards.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tarjetas asociadas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...accountCards.map((card) => _buildCardItem(card)),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCardItem(domain.Card card) {
    final bool canViewCardInfo = card.status == domain.CardStatus.active ||
        card.status == domain.CardStatus.delivered ||
        card.status == domain.CardStatus.blocked ||
        card.status == domain.CardStatus.expired;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: _getCardBrandColor(card.cardBrand)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${card.cardBrand.displayName} ${card.cardType.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      card.status == domain.CardStatus.active 
                        ? card.maskedCardNumber 
                        : 'x' * 16,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCardStatusColor(card.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  card.status.displayName,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          if (canViewCardInfo) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCardInfoModal(card),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Ver tarjeta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCardBrandColor(card.cardBrand),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getAccountTypeColor(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return Colors.green;
      case AccountType.checking:
        return Colors.blue;
      case AccountType.microCredit:
        return Colors.orange;
      case AccountType.fixedDeposit:
        return Colors.purple;
    }
  }

  IconData _getAccountTypeIcon(AccountType type) {
    switch (type) {
      case AccountType.savings:
        return Icons.savings;
      case AccountType.checking:
        return Icons.account_balance;
      case AccountType.microCredit:
        return Icons.credit_score;
      case AccountType.fixedDeposit:
        return Icons.lock;
    }
  }

  Color _getStatusColor(AccountStatus status) {
    switch (status) {
      case AccountStatus.active:
        return Colors.green;
      case AccountStatus.pending:
        return Colors.orange;
      case AccountStatus.suspended:
        return Colors.red;
      case AccountStatus.closed:
        return Colors.black;
    }
  }

  Color _getCardBrandColor(domain.CardBrand brand) {
    switch (brand) {
      case domain.CardBrand.visa:
        return Colors.blue;
      case domain.CardBrand.mastercard:
        return Colors.red;
      case domain.CardBrand.amex:
        return Colors.green;
      case domain.CardBrand.dinersClub:
        return Colors.purple;
    }
  }

  Color _getCardStatusColor(domain.CardStatus status) {
    switch (status) {
      case domain.CardStatus.active:
        return Colors.green;
      case domain.CardStatus.requested:
        return Colors.blue;
      case domain.CardStatus.approved:
        return Colors.lightBlue;
      case domain.CardStatus.inProduction:
        return Colors.orange;
      case domain.CardStatus.delivered:
        return Colors.teal;
      case domain.CardStatus.blocked:
        return Colors.red;
      case domain.CardStatus.expired:
        return Colors.grey;
      case domain.CardStatus.cancelled:
        return Colors.black;
    }
  }

  void _showAccountDetailsModal(Account account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AccountDetailsScreen(account: account),
      ),
    );
  }

  void _showCardInfoModal(domain.Card card) async {
    final biometricService = BiometricAuthService();
    
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Verificar si ya hay una autenticación en progreso
      if (biometricService.isAuthenticating) {
        print('DEBUG: Autenticación ya en progreso, reiniciando plugin...');
        await biometricService.forceResetAuthState();
        // Esperar un momento antes de continuar
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Verificar si la biometría está disponible
      final isAvailable = await biometricService.isBiometricAvailable();
      
      if (!isAvailable) {
        // Si no hay biometría disponible, cerrar loading y mostrar mensaje
        if (mounted) Navigator.of(context).pop();
        _showBiometricNotAvailableDialog();
        return;
      }

      // Realizar autenticación biométrica
      final result = await biometricService.authenticate(
        localizedReason: 'Verifica tu identidad para ver la información completa de la tarjeta',
      );

      // Cerrar indicador de carga
      if (mounted) Navigator.of(context).pop();

      if (result == BiometricAuthResult.success) {
        // Autenticación exitosa, mostrar modal
        if (mounted) {
          Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CardInfoScreen(card: card),
          ),
        );
        }
      } else if (result == BiometricAuthResult.cancelled) {
        // Usuario canceló la autenticación, no hacer nada
        // Simplemente volver al estado normal sin mostrar error
        print('DEBUG: Usuario canceló la autenticación biométrica');
      } else {
        // Otros errores (fallida, no disponible, etc.), mostrar mensaje de error
        _showBiometricErrorDialog(result, card);
      }
     } catch (e) {
       // Cerrar indicador de carga en caso de error
       if (mounted) Navigator.of(context).pop();
       _showBiometricErrorDialog(BiometricAuthResult.error, card);
     }
   }

   void _showBiometricNotAvailableDialog() {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Autenticación no disponible'),
         content: const Text(
           'La autenticación biométrica no está disponible en este dispositivo. '
           'Para ver la información completa de la tarjeta, necesitas configurar '
           'huella dactilar o Face ID en la configuración de tu dispositivo.',
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.of(context).pop(),
             child: const Text('Entendido'),
           ),
         ],
       ),
     );
   }

   void _showBiometricErrorDialog(BiometricAuthResult result, domain.Card card) {
     final biometricService = BiometricAuthService();
     final message = biometricService.getResultMessage(result);
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Error de autenticación'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(message),
             const SizedBox(height: 16),
             TextButton(
               onPressed: () => _showDiagnosticInfo(),
               child: const Text('Ver información técnica'),
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.of(context).pop(),
             child: const Text('Cerrar'),
           ),
           if (result == BiometricAuthResult.failed || 
               result == BiometricAuthResult.notAvailable ||
               result == BiometricAuthResult.notEnrolled ||
               result == BiometricAuthResult.error)
             TextButton(
               onPressed: () {
                 Navigator.of(context).pop();
                 // Intentar de nuevo
                 _showCardInfoModal(card);
               },
               child: const Text('Intentar de nuevo'),
             ),
         ],
       ),
     );
   }

   void _showDiagnosticInfo() async {
     final biometricService = BiometricAuthService();
     final diagnosticInfo = await biometricService.getDiagnosticInfo();
     
     if (mounted) {
       showDialog(
         context: context,
         builder: (context) => AlertDialog(
           title: const Text('Información técnica'),
           content: SingleChildScrollView(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text('Dispositivo soportado: ${diagnosticInfo['isDeviceSupported']}'),
                 Text('Puede verificar biometría: ${diagnosticInfo['canCheckBiometrics']}'),
                 Text('Biometrías configuradas: ${diagnosticInfo['hasBiometricsEnrolled']}'),
                 const SizedBox(height: 8),
                 const Text('Tipos disponibles:', style: TextStyle(fontWeight: FontWeight.bold)),
                 ...diagnosticInfo['availableBiometrics'].map<Widget>((type) => Text('• $type')),
                 if (diagnosticInfo['error'] != null) ...[
                   const SizedBox(height: 8),
                   const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
                   Text(diagnosticInfo['error']),
                 ],
               ],
             ),
           ),
           actions: [
             TextButton(
               onPressed: () => Navigator.of(context).pop(),
               child: const Text('Cerrar'),
             ),
           ],
         ),
       );
     }
   }

  // Funciones para enmascarar números sensibles
  String _maskAccountNumber(String accountNumber, AccountStatus status) {
    if (status == AccountStatus.active) {
      return accountNumber;
    }
    return 'x' * accountNumber.length;
  }

  String _maskCCI(String cci, AccountStatus status) {
    if (status == AccountStatus.active) {
      return cci;
    }
    return 'x' * cci.length;
  }

  String _maskCardNumber(String cardNumber, domain.CardStatus status) {
    if (status == domain.CardStatus.active) {
      return cardNumber;
    }
    return 'x' * cardNumber.length;
  }
}
