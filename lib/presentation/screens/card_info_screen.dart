import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/card.dart' as domain;
import 'card/card_movements_screen.dart';

class CardInfoScreen extends StatefulWidget {
  final domain.Card card;

  const CardInfoScreen({super.key, required this.card});

  @override
  State<CardInfoScreen> createState() => _CardInfoScreenState();
}

class _CardInfoScreenState extends State<CardInfoScreen> {
  late bool _isContactlessEnabled;
  late bool _isOnlineEnabled;
  late bool _isAtmEnabled;
  late bool _isInternationalEnabled;

  @override
  void initState() {
    super.initState();
    _isContactlessEnabled = widget.card.isContactlessEnabled ?? false;
    _isOnlineEnabled = widget.card.isOnlineEnabled ?? false;
    _isAtmEnabled = widget.card.isAtmEnabled ?? false;
    _isInternationalEnabled = widget.card.isInternationalEnabled ?? false;
  }

  void _updateSecuritySetting(String settingName, bool newValue) {
    setState(() {
      switch (settingName) {
        case 'contactless':
          _isContactlessEnabled = newValue;
          break;
        case 'online':
          _isOnlineEnabled = newValue;
          break;
        case 'atm':
          _isAtmEnabled = newValue;
          break;
        case 'international':
          _isInternationalEnabled = newValue;
          break;
      }
    });

    // TODO: Aquí se debe llamar al bloc/repository para guardar el cambio
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Configuración actualizada: $settingName ${newValue ? "activada" : "desactivada"}',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: newValue ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: _getCardBrandColor(),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.card.cardBrand.displayName} ${widget.card.cardType.displayName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.card.holderName,
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
            // Card Number Section
            _buildInfoSection(
              title: 'Número de Tarjeta',
              child: _buildCopyableField(
                label: 'Número',
                value: _getCardNumberToShow(widget.card),
                fullValue: _getCardNumberToCopy(widget.card),
                context: context,
              ),
            ),

            const SizedBox(height: 20),

            // Card Details
            _buildInfoSection(
              title: 'Detalles de la Tarjeta',
              child: Column(
                children: [
                  _buildDetailRow('Tipo', widget.card.cardType.displayName),
                  _buildDetailRow('Marca', widget.card.cardBrand.displayName),
                  _buildDetailRow('Estado', widget.card.status.displayName),
                  _buildDetailRow(
                    'Fecha de Expiración',
                    widget.card.formattedExpiryDate,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Limits Section
            _buildInfoSection(
              title: 'Límites Disponibles',
              child: Column(
                children: [
                  _buildLimitRow('Límite Diario', widget.card.dailyLimit ?? 0),
                  _buildLimitRow(
                    'Límite Mensual',
                    widget.card.monthlyLimit ?? 0,
                  ),
                  _buildLimitRow('Límite ATM', widget.card.atmLimit ?? 0),
                  _buildLimitRow('Límite Online', widget.card.onlineLimit ?? 0),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Security Settings
            _buildInfoSection(
              title: 'Configuraciones de Seguridad',
              child: Column(
                children: [
                  _buildSecurityToggle(
                    'Contactless',
                    _isContactlessEnabled,
                    Icons.contactless,
                    'contactless',
                  ),
                  _buildSecurityToggle(
                    'Compras Online',
                    _isOnlineEnabled,
                    Icons.shopping_cart,
                    'online',
                  ),
                  _buildSecurityToggle(
                    'Uso en ATM',
                    _isAtmEnabled,
                    Icons.atm,
                    'atm',
                  ),
                  _buildSecurityToggle(
                    'Uso Internacional',
                    _isInternationalEnabled,
                    Icons.public,
                    'international',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Movements Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showMovementsInfo(context),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Ver Movimientos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCardBrandColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCopyableField({
    required String label,
    required String value,
    required String fullValue,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
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
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copyToClipboard(
              context,
              fullValue,
              'Número de tarjeta copiado',
            ),
            icon: Icon(Icons.copy, color: Colors.grey.shade600, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'S/ ${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityToggle(
    String label,
    bool isEnabled,
    IconData icon,
    String settingKey,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? _getCardBrandColor().withOpacity(0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled
                    ? _getCardBrandColor().withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isEnabled ? _getCardBrandColor() : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: (newValue) =>
                  _updateSecuritySetting(settingKey, newValue),
              activeColor: _getCardBrandColor(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getCardBrandColor() {
    switch (widget.card.cardBrand) {
      case domain.CardBrand.visa:
        return const Color(0xFF00BCD4); // Celeste como en el inicio
      case domain.CardBrand.mastercard:
        return const Color(0xFFEB001B);
      case domain.CardBrand.amex:
        return const Color(0xFF006FCF);
      case domain.CardBrand.dinersClub:
        return const Color(0xFF0079BE);
    }
  }

  String _getCardNumberToShow(domain.Card card) {
    if (card.status == domain.CardStatus.active) {
      return _formatCardNumber(card.cardNumber);
    }
    return '**** **** **** ${card.cardNumber.substring(card.cardNumber.length - 4)}';
  }

  String _getCardNumberToCopy(domain.Card card) {
    if (card.status == domain.CardStatus.active) {
      return card.cardNumber;
    }
    return '**** **** **** ${card.cardNumber.substring(card.cardNumber.length - 4)}';
  }

  String _formatCardNumber(String cardNumber) {
    if (cardNumber.length != 16) return cardNumber;
    return '${cardNumber.substring(0, 4)} ${cardNumber.substring(4, 8)} ${cardNumber.substring(8, 12)} ${cardNumber.substring(12, 16)}';
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

  void _showMovementsInfo(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CardMovementsScreen(card: widget.card),
      ),
    );
  }
}