import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/account.dart';
import '../../domain/entities/card.dart' as domain;
import '../bloc/card/card_bloc.dart';
import '../bloc/card/card_state.dart';

class AccountDetailsScreen extends StatelessWidget {
  final Account account;

  const AccountDetailsScreen({
    super.key,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _getAccountTypeColor(account.accountType),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account.accountType.displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${account.currency} ${account.balance.toStringAsFixed(2)}',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Information
            _buildSectionTitle('Información de la Cuenta'),
            const SizedBox(height: 12),
            
            _buildInfoCard(
              'Número de Cuenta',
              _maskAccountNumber(account.accountNumber, account.status),
              Icons.account_balance,
              onCopy: () => _copyToClipboard(
                context,
                _maskAccountNumber(account.accountNumber, account.status),
                'Número de cuenta copiado',
              ),
            ),
            
            const SizedBox(height: 12),
            
            _buildInfoCard(
              'CCI (Código Interbancario)',
              _maskCCI(account.cci, account.status),
              Icons.qr_code,
              onCopy: () => _copyToClipboard(
                context,
                _maskCCI(account.cci, account.status),
                'CCI copiado',
              ),
            ),
            
            const SizedBox(height: 12),
            
            _buildInfoCard(
              'Tasa de Interés',
              '${account.interestRate.toStringAsFixed(2)}% anual',
              Icons.percent,
            ),
            
            const SizedBox(height: 12),
            
            _buildInfoCard(
              'Estado',
              account.status.displayName,
              Icons.info,
              statusColor: _getStatusColor(account.status),
            ),
            
            const SizedBox(height: 20),
            
            // Holder Information
            _buildSectionTitle('Información del Titular'),
            const SizedBox(height: 12),
            
            _buildSimpleInfo('Nombre Completo', account.fullHolderName),
            _buildSimpleInfo('DNI', account.holderDni),
            _buildSimpleInfo('Teléfono', account.holderPhone),
            _buildSimpleInfo('Email', account.holderEmail),
            
            const SizedBox(height: 20),
            
            // Cards Information
            _buildSectionTitle('Tarjetas Asociadas'),
            const SizedBox(height: 12),
            _buildCardsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon, {
    VoidCallback? onCopy,
    Color? statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor ?? Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: statusColor ?? Colors.blue.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: Icon(
                Icons.copy,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsSection() {
    return BlocBuilder<CardBloc, CardState>(
      builder: (context, state) {
        if (state is CardLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is CardLoaded) {
          final accountCards = state.cards
              .where((card) => card.accountId == account.id)
              .toList();

          if (accountCards.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.credit_card_off,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No hay tarjetas asociadas',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: accountCards.map((card) => _buildCardItem(card)).toList(),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            'Error al cargar las tarjetas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardItem(domain.Card card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getCardTypeColor(card.cardType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCardTypeIcon(card.cardType),
              color: _getCardTypeColor(card.cardType),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.cardType.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '**** **** **** ${card.cardNumber.substring(card.cardNumber.length - 4)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getCardStatusColor(card.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              card.status.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getCardStatusColor(card.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
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
    }
  }

  Color _getStatusColor(AccountStatus status) {
    switch (status) {
      case AccountStatus.active:
        return Colors.green;
      case AccountStatus.pending:
        return Colors.orange;
      case AccountStatus.closed:
        return Colors.red;
      case AccountStatus.suspended:
        return Colors.red.shade700;
    }
  }

  Color _getCardTypeColor(domain.CardType type) {
    switch (type) {
      case domain.CardType.debit:
        return Colors.blue;
      case domain.CardType.credit:
        return Colors.purple;
      case domain.CardType.prepaid:
        return Colors.green;
    }
  }

  IconData _getCardTypeIcon(domain.CardType type) {
    switch (type) {
      case domain.CardType.debit:
        return Icons.payment;
      case domain.CardType.credit:
        return Icons.credit_card;
      case domain.CardType.prepaid:
        return Icons.card_giftcard;
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
        return Colors.lightGreen;
      case domain.CardStatus.blocked:
        return Colors.red;
      case domain.CardStatus.expired:
        return Colors.grey;
      case domain.CardStatus.cancelled:
        return Colors.red.shade700;
    }
  }

  String _maskAccountNumber(String accountNumber, AccountStatus status) {
    if (status == AccountStatus.active) {
      return accountNumber;
    }
    // Para cuentas no activas, enmascarar completamente
    return '*' * accountNumber.length;
  }

  String _maskCCI(String cci, AccountStatus status) {
    if (status == AccountStatus.active) {
      return cci;
    }
    // Para cuentas no activas, enmascarar completamente
    return '*' * cci.length;
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }
}