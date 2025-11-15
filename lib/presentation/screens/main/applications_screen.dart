import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../bloc/intake_request/intake_request_bloc.dart';
import '../../bloc/intake_request/intake_request_event.dart';
import '../../bloc/intake_request/intake_request_state.dart';
import '../details/loan_application_detail_page.dart';
import '../../utils/product_colors.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_state.dart';
import '../loan_application_screen.dart';
import '../../widgets/simple_account_creation_modal.dart';
import '../../bloc/account/account_bloc.dart';
import '../../bloc/account/account_state.dart';
import '../../bloc/account/account_event.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _microfinancieraIdFallback = 'mf_demo_001';

  String _resolveMicrofinancieraId(BuildContext context) {
    final profile = context.read<ProfileBloc>().state.profile;
    return profile?.microfinancieraId ?? _microfinancieraIdFallback;
  }

  @override
  void initState() {
    super.initState();
    context.read<IntakeRequestBloc>().add(const IntakeRequestLoadRequested());
    _loadUserAccounts();
  }

  void _loadUserAccounts() {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      context.read<AccountBloc>().add(AccountLoadUserAccounts(uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final authState = context.watch<AuthBloc>().state;
    final String? uid = authState is AuthAuthenticated
        ? authState.user.uid
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tus Solicitudes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<IntakeRequestBloc>().add(
            const IntakeRequestRefreshRequested(),
          );
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle
              Text(
                'Envía y revisa el estado de tus solicitudes de préstamo',
                style: TextStyle(
                  fontSize: screenWidth * 0.04, // 4% del ancho
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: screenHeight * 0.03), // 3% de la altura

              // Estadísticas rápidas
              _buildStatsCards(uid),
              SizedBox(height: screenHeight * 0.03), // 3% de la altura

              // Lista de solicitudes
              _buildApplicationsList(uid),
            ],
          ),
        ),
      ),
      floatingActionButton: BlocBuilder<IntakeRequestBloc, IntakeRequestState>(
        builder: (context, state) {
          final authState = context.watch<AuthBloc>().state;
          final String? uid = authState is AuthAuthenticated
              ? authState.user.uid
              : null;

          final userRequests = uid == null
              ? state.requests
              : state.requests.where((r) => r.userId == uid).toList();

          // Verificar si hay solicitudes pendientes
          final hasPendingApplications = userRequests.any((request) =>
              request.status == 'pending' || request.status == 'in_review');

          return FloatingActionButton(
            onPressed: hasPendingApplications
                ? () => _showPendingApplicationMessage(context)
                : () => _showCreateRequestSheet(context),
            backgroundColor: hasPendingApplications
                ? Colors.grey
                : Theme.of(context).colorScheme.primary,
            child: Icon(
              hasPendingApplications ? Icons.block : Icons.add,
              color: hasPendingApplications
                  ? Colors.white70
                  : Theme.of(context).colorScheme.onPrimary,
            ),
            tooltip: hasPendingApplications
                ? 'Tienes una solicitud pendiente'
                : 'Nueva solicitud',
          );
        },
      ),
    );
  }

  Widget _buildStatsCards(String? uid) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return BlocBuilder<IntakeRequestBloc, IntakeRequestState>(
      builder: (context, state) {
        final filtered = uid == null
            ? state.requests
            : state.requests.where((r) => r.userId == uid).toList();

        int pending = filtered
            .where((r) => r.status == 'pending' || r.status == 'in_review')
            .length;
        int approved = filtered
            .where((r) => r.status == 'approved' || r.status == 'disbursed')
            .length;
        int rejected = filtered.where((r) => r.status == 'rejected').length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Pendientes',
                value: '$pending',
                icon: Icons.schedule,
                color: Colors.orange,
              ),
            ),
            SizedBox(width: screenWidth * 0.03), // 3% del ancho
            Expanded(
              child: _buildStatCard(
                title: 'Aprobadas',
                value: '$approved',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            SizedBox(width: screenWidth * 0.03), // 3% del ancho
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
        child: Column(
          children: [
            Icon(
              icon, 
              color: color, 
              size: screenWidth * 0.08, // 8% del ancho
            ),
            SizedBox(height: screenHeight * 0.01), // 1% de la altura
            Text(
              value,
              style: TextStyle(
                fontSize: screenWidth * 0.06, // 6% del ancho
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: screenHeight * 0.005), // 0.5% de la altura
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.03, // 3% del ancho
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsList(String? uid) {
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

        final requests = uid == null
            ? state.requests
            : state.requests.where((r) => r.userId == uid).toList();

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
                        'Aún no tienes solicitudes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Crea una solicitud pulsando el botón +',
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
                  date: request.createdAt != null
                      ? dateFormat.format(request.createdAt!)
                      : 'Sin fecha',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LoanApplicationDetailPage(application: request),
                      ),
                    );
                  },
                );
              }).toList(),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
      case 'in_review':
        return Colors.orange;
      case 'approved':
      case 'disbursed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'in_review':
        return 'En revisión';
      case 'approved':
        return 'Aprobada';
      case 'disbursed':
        return 'Desembolsada';
      case 'rejected':
        return 'Rechazada';
      default:
        return 'Recibida';
    }
  }

  Widget _buildApplicationCard({
    required String clientName,
    required String amount,
    required String status,
    required Color statusColor,
    required String date,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.description, color: statusColor),
        ),
        title: Text(clientName),
        subtitle: Text('$amount • $date'),
        trailing: Text(
          status,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showPendingApplicationMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No puedes crear una nueva solicitud mientras tengas una pendiente. '
          'Espera a que tu solicitud actual sea aprobada o rechazada.',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showCreateRequestSheet(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes estar autenticado para continuar'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final profileState = context.read<ProfileBloc>().state;
    
    if (profileState.status != ProfileStatus.loaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargando perfil de usuario...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final microfinancieraId = profileState.profile?.microfinancieraId;
    
    if (microfinancieraId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la información de la microfinanciera'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar si el usuario tiene cuentas
    final accountState = context.read<AccountBloc>().state;
    
    if (accountState is AccountLoaded && accountState.accounts.isNotEmpty) {
      // Usuario tiene cuentas, mostrar modal de solicitud de crédito
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoanApplicationScreen(
            userId: authState.user.uid,
            microfinancieraId: microfinancieraId,
          ),
        ),
      );
    } else {
      // Usuario no tiene cuentas, mostrar modal de creación de cuenta
      _showAccountCreationDialog(context, authState.user.uid, microfinancieraId);
    }
  }

  void _showAccountCreationDialog(BuildContext context, String userId, String microfinancieraId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Opciones de Solicitud'),
        content: const Text(
          'Puedes solicitar un crédito de dos formas:\n\n'
          '1. Crear una cuenta (recomendado): Tendrás acceso completo a todos los servicios\n\n'
          '2. Solicitar sin cuenta: Solo para esta solicitud de crédito'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCreditWithoutAccountConfirmation(context, userId, microfinancieraId);
            },
            child: const Text('Solicitar sin Cuenta'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => SimpleAccountCreationModal(
                  userId: userId,
                  microfinancieraId: microfinancieraId,
                ),
              );
            },
            child: const Text('Crear Cuenta'),
          ),
        ],
      ),
    );
  }

  void _showCreditWithoutAccountConfirmation(BuildContext context, String userId, String microfinancieraId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Solicitud sin Cuenta'),
        content: const Text(
          'Al solicitar un crédito sin crear una cuenta:\n\n'
          '• Solo podrás realizar esta solicitud\n'
          '• Necesitarás proporcionar tu número de cuenta y CCI\n'
          '• No tendrás acceso a otros servicios de la plataforma\n\n'
          '¿Estás seguro de que quieres continuar sin crear una cuenta?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoanApplicationScreen(
                    userId: userId,
                    microfinancieraId: microfinancieraId,
                    isWithoutAccount: true,
                  ),
                ),
              );
            },
            child: const Text('Continuar sin Cuenta'),
          ),
        ],
      ),
    );
  }
}
