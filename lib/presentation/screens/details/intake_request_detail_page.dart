import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/intake_request.dart';

class IntakeRequestDetailPage extends StatelessWidget {
  final IntakeRequest request;

  const IntakeRequestDetailPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Solicitud'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context),
            const SizedBox(height: 16),
            _buildContactInfo(context),
            const SizedBox(height: 16),
            _buildApplicantInfo(context),
            const SizedBox(height: 16),
            _buildRequestedInfo(context),
            const SizedBox(height: 16),
            _buildRoutingInfo(context),
            const SizedBox(height: 16),
            _buildRiskInfo(context),
            const SizedBox(height: 16),
            _buildTimestamps(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final statusColor = _getStatusColor(request.status);
    final statusText = _getStatusText(request.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(request.status),
                color: statusColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estado', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
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

  Widget _buildContactInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contact_phone, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Información de Contacto',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.phone,
              label: 'Teléfono',
              value: request.contact.phone,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.email,
              label: 'Email',
              value: request.contact.email,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.verified,
              label: 'Verificado',
              value: request.contact.verified ? 'Sí' : 'No',
              valueColor: request.contact.verified
                  ? Colors.green
                  : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Datos del Solicitante',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.badge,
              label: 'DNI',
              value: request.applicant.dni,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.person_outline,
              label: 'Nombre Completo',
              value: request.applicant.fullName,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.location_on,
              label: 'Distrito',
              value: request.applicant.district,
            ),
            if (request.applicant.activity != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                icon: Icons.work,
                label: 'Actividad',
                value: request.applicant.activity!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestedInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.request_quote, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Información Solicitada',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.attach_money,
              label: 'Monto',
              value: 'S/ ${request.requested.amount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.calendar_today,
              label: 'Plazo',
              value: '${request.requested.termMonths} meses',
            ),
            if (request.requested.purpose != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                icon: Icons.category,
                label: 'Propósito',
                value: request.requested.purpose!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoutingInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Información de Enrutamiento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.business,
              label: 'Sucursal',
              value: request.routing.branchId,
            ),
            if (request.routing.assignedUserId != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                icon: Icons.person_pin,
                label: 'Asignado a',
                value: request.routing.assignedUserId!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskInfo(BuildContext context) {
    final riskLevel = _getRiskLevel(request.riskFlags.spamScore);
    final riskColor = _getRiskColor(request.riskFlags.spamScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Análisis de Riesgo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.score,
              label: 'Puntuación de Spam',
              value:
                  '${(request.riskFlags.spamScore * 100).toStringAsFixed(1)}%',
              valueColor: riskColor,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.flag,
              label: 'Nivel de Riesgo',
              value: riskLevel,
              valueColor: riskColor,
            ),
            if (request.riskFlags.reason != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                icon: Icons.info,
                label: 'Razón',
                value: request.riskFlags.reason!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimestamps(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Fechas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              icon: Icons.calendar_today,
              label: 'Creado',
              value: dateFormat.format(request.createdAt),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.update,
              label: 'Actualizado',
              value: dateFormat.format(request.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'received':
        return Colors.blue;
      case 'validated':
        return Colors.green;
      case 'routed':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'converted':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'received':
        return 'Recibida';
      case 'validated':
        return 'Validada';
      case 'routed':
        return 'Enrutada';
      case 'rejected':
        return 'Rechazada';
      case 'converted':
        return 'Convertida';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'received':
        return Icons.inbox;
      case 'validated':
        return Icons.check_circle;
      case 'routed':
        return Icons.route;
      case 'rejected':
        return Icons.cancel;
      case 'converted':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  String _getRiskLevel(double score) {
    if (score < 0.3) return 'Bajo';
    if (score < 0.7) return 'Medio';
    return 'Alto';
  }

  Color _getRiskColor(double score) {
    if (score < 0.3) return Colors.green;
    if (score < 0.7) return Colors.orange;
    return Colors.red;
  }
}
