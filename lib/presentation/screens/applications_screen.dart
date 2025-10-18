import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/intake_request/intake_request_bloc.dart';
import '../bloc/intake_request/intake_request_event.dart';
import '../bloc/intake_request/intake_request_state.dart';
import '../pages/loan_application_detail_page.dart';
import '../utils/product_colors.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar todas las solicitudes al iniciar
    context.read<IntakeRequestBloc>().add(const IntakeRequestLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<IntakeRequestBloc>().add(
            const IntakeRequestRefreshRequested(),
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Solicitudes de Préstamo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Administra las solicitudes pendientes de aprobación',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Estadísticas rápidas
              _buildStatsCards(),
              const SizedBox(height: 24),

              // Lista de solicitudes
              _buildApplicationsList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Funcionalidad próximamente')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCards() {
    return BlocBuilder<IntakeRequestBloc, IntakeRequestState>(
      builder: (context, state) {
        final counts = state.statusCounts;
        final pending = counts['pending'] ?? 0;
        final inReview = counts['in_review'] ?? 0;
        final rejected = counts['rejected'] ?? 0;
        final totalPending = pending + inReview;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Pendientes',
                value: '$totalPending',
                icon: Icons.schedule,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Aprobadas',
                value:
                    '${(counts['approved'] ?? 0) + (counts['disbursed'] ?? 0)}',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Rechazadas',
                value: '$rejected',
                icon: Icons.cancel,
                color: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsList() {
    return BlocBuilder<IntakeRequestBloc, IntakeRequestState>(
      builder: (context, state) {
        if (state.status == IntakeRequestStatus.loading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state.status == IntakeRequestStatus.error) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar solicitudes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage ?? 'Error desconocido',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<IntakeRequestBloc>().add(
                        const IntakeRequestRefreshRequested(),
                      );
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final requests = state.requests;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Solicitudes Recientes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (requests.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay solicitudes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Las solicitudes de los clientes aparecerán aquí',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...requests.map((request) {
                final statusColor = _getStatusColor(request.status);
                final statusText = _getStatusText(request.status);
                final dateFormat = DateFormat('dd MMM yyyy');

                final displayName =
                    request.personalInfo?.firstName ??
                    request.contactInfo?.email ??
                    'Cliente';
                final loanAmount = request.financialInfo?.loanAmount ?? 0;

                return _buildApplicationCard(
                  clientName: displayName,
                  amount: 'S/ ${loanAmount.toStringAsFixed(2)}',
                  status: statusText,
                  statusColor: statusColor,
                  date: dateFormat.format(request.createdAt),
                  productCode: request.product?.code,
                  productName: request.product?.name,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            LoanApplicationDetailPage(application: request),
                      ),
                    );
                    // Refrescar la lista cuando vuelve
                    if (context.mounted) {
                      context.read<IntakeRequestBloc>().add(
                        const IntakeRequestLoadRequested(),
                      );
                    }
                  },
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildApplicationCard({
    required String clientName,
    required String amount,
    required String status,
    required Color statusColor,
    required String date,
    String? productCode,
    String? productName,
    required VoidCallback onTap,
  }) {
    final productColor = ProductColors.getColorByCode(productCode);
    final productIcon = ProductColors.getIconByCode(productCode);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Text(
            clientName.isNotEmpty ? clientName[0] : '?',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                clientName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (productCode != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: productColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(productIcon, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      productCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Solicitud: $amount • $date'),
            if (productName != null)
              Text(
                productName,
                style: TextStyle(
                  fontSize: 11,
                  color: productColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'disbursed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'in_review':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobada';
      case 'disbursed':
        return 'Aprobado';
      case 'rejected':
        return 'Rechazada';
      case 'in_review':
        return 'En Revisión';
      default:
        return status;
    }
  }
}
