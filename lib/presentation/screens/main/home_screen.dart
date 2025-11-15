import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/intake_request/intake_request_bloc.dart';
import '../../bloc/intake_request/intake_request_event.dart';
import '../../bloc/intake_request/intake_request_state.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_state.dart';
import '../details/loan_application_detail_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar solicitudes recientes al iniciar
    context.read<IntakeRequestBloc>().add(
      const IntakeRequestLoadRecent(limit: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final profile = state.profile;
        final isLoading = state.isLoading && profile == null;
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<IntakeRequestBloc>().add(
              const IntakeRequestRefreshRequested(),
            );
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    RepaintBoundary(
                      child: _WelcomeCard(
                        userName: profile?.firstName ?? 'Usuario',
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03), // 3% de la altura
                    const RepaintBoundary(child: _StatsCards()),
                    SizedBox(height: screenHeight * 0.03), // 3% de la altura
                    const RepaintBoundary(child: _QuickActions()),
                    SizedBox(height: screenHeight * 0.03), // 3% de la altura
                    const RepaintBoundary(child: _RecentActivity()),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : (hour < 18 ? 'Buenas tardes' : 'Buenas noches');

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(screenWidth * 0.03), // 3% del ancho
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(screenWidth * 0.05), // 5% del ancho
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $userName! 👋',
              style: TextStyle(
                fontSize: screenWidth * 0.06, // 6% del ancho
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.01), // 1% de la altura
            Text(
              'Bienvenido a CréditoExpress',
              style: TextStyle(
                fontSize: screenWidth * 0.04, // 4% del ancho
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCards extends StatelessWidget {
  const _StatsCards();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return BlocBuilder<IntakeRequestBloc, IntakeRequestState>(
      builder: (context, state) {
        final counts = state.statusCounts;
        final pending = counts['pending'] ?? 0;
        final inReview = counts['in_review'] ?? 0;
        final total = pending + inReview;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _StatCard(
                title: 'Clientes activos',
                value: '${counts.values.fold(0, (a, b) => a + b)}',
              ),
            ),
            SizedBox(width: screenWidth * 0.03), // 3% del ancho
            Expanded(
              child: _StatCard(
                title: 'Solicitudes pendientes',
                value: '$total',
              ),
            ),
            SizedBox(width: screenWidth * 0.03), // 3% del ancho
            Expanded(
              child: _StatCard(
                title: 'Préstamos en seguimiento',
                value: '${counts['approved'] ?? 0}',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title, 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: screenWidth * 0.035, // 3.5% del ancho
              ),
            ),
            SizedBox(height: screenHeight * 0.01), // 1% de la altura
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.08, // 8% del ancho
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones rápidas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05, // 5% del ancho
          ),
        ),
        SizedBox(height: screenHeight * 0.015), // 1.5% de la altura
        Wrap(
          spacing: screenWidth * 0.03, // 3% del ancho
          runSpacing: screenHeight * 0.015, // 1.5% de la altura
          children: const [
            _QuickActionChip(
              icon: Icons.person_add_alt,
              label: 'Nuevo cliente',
            ),
            _QuickActionChip(icon: Icons.assignment, label: 'Nueva solicitud'),
            _QuickActionChip(icon: Icons.attach_money, label: 'Registrar pago'),
            _QuickActionChip(icon: Icons.bar_chart, label: 'Ver reportes'),
          ],
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return ActionChip(
      avatar: Icon(icon, size: screenWidth * 0.045), // 4.5% del ancho
      label: Text(
        label,
        style: TextStyle(fontSize: screenWidth * 0.035), // 3.5% del ancho
      ),
      onPressed: () {},
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return BlocBuilder<IntakeRequestBloc, IntakeRequestState>(
      builder: (context, state) {
        if (state.status == IntakeRequestStatus.loading) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.08), // 8% del ancho
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final requests = state.requests.take(5).toList();

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
                child: Text(
                  'Actividad reciente',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.05, // 5% del ancho
                  ),
                ),
              ),
              if (requests.isEmpty)
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.08), // 8% del ancho
                  child: const Center(child: Text('No hay solicitudes recientes')),
                )
              else
                ...requests.map((request) {
                  final statusColor = _getStatusColor(request.status);
                  final statusText = _getStatusText(request.status);
                  final timeAgo = _getTimeAgo(request.updatedAt);

                  final displayName =
                      request.personalInfo?.firstName ??
                      request.contactInfo?.email ??
                      'Cliente';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.2),
                      radius: screenWidth * 0.05, // 5% del ancho
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.04, // 4% del ancho
                        ),
                      ),
                    ),
                    title: Text(
                      displayName,
                      style: TextStyle(fontSize: screenWidth * 0.04), // 4% del ancho
                    ),
                    subtitle: Text(
                      timeAgo,
                      style: TextStyle(fontSize: screenWidth * 0.035), // 3.5% del ancho
                    ),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02, // 2% del ancho
                        vertical: screenHeight * 0.005, // 0.5% de la altura
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(screenWidth * 0.03), // 3% del ancho
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: screenWidth * 0.03, // 3% del ancho
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              LoanApplicationDetailPage(application: request),
                        ),
                      );
                      // Refrescar cuando vuelve
                      if (context.mounted) {
                        context.read<IntakeRequestBloc>().add(
                          const IntakeRequestLoadRequested(),
                        );
                      }
                    },
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
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
      case 'rejected':
        return 'Rechazada';
      case 'in_review':
        return 'En Revisión';
      default:
        return status;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Hace un momento';
    }
  }
}
