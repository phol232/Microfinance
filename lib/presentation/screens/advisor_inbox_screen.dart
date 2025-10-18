import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/datasources/loan_application_datasource.dart';
import '../../data/repositories/loan_application_repository_impl.dart';
import '../../domain/repositories/loan_application_repository.dart';
import '../bloc/advisor_inbox/advisor_inbox_bloc.dart';
import '../bloc/advisor_inbox/advisor_inbox_event.dart';
import '../bloc/advisor_inbox/advisor_inbox_state.dart';
import '../components/loading_indicator.dart';
import '../components/error_banner.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../domain/entities/loan_application.dart';

class AdvisorInboxScreen extends StatefulWidget {
  final String microfinancieraId;
  final String agentId;
  final String agentUserId;

  const AdvisorInboxScreen({
    Key? key,
    required this.microfinancieraId,
    required this.agentId,
    required this.agentUserId,
  }) : super(key: key);

  @override
  State<AdvisorInboxScreen> createState() => _AdvisorInboxScreenState();
}

class _AdvisorInboxScreenState extends State<AdvisorInboxScreen>
    with TickerProviderStateMixin {
  late final AdvisorInboxBloc _bloc;
  late TabController _tabController;
  final List<String> _statusTabs = ['received', 'routed', 'in_review', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    
    // Inicializar repositorio y bloc
    final repository = LoanApplicationRepositoryImpl(
      dataSource: LoanApplicationDataSource(),
    );
    
    _bloc = AdvisorInboxBloc(repository: repository);
    
    _tabController = TabController(
      length: _statusTabs.length,
      vsync: this,
    );

    // Cargar datos iniciales
    _loadInitialData();
  }

  void _loadInitialData() {
    // Cargar aplicaciones asignadas al agente
    _bloc.add(LoadAssignedApplications(
      microfinancieraId: widget.microfinancieraId,
      agentId: widget.agentId,
    ));

    // Cargar estadísticas
    _bloc.add(LoadApplicationStats(
      microfinancieraId: widget.microfinancieraId,
      agentId: widget.agentId,
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandeja del Asesor'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (index) {
            final status = _statusTabs[index];
            _bloc.add(FilterByStatus([status]));
          },
          tabs: const [
            Tab(text: 'Recibidas'),
            Tab(text: 'En Ruta'),
            Tab(text: 'En Revisión'),
            Tab(text: 'Aprobadas'),
            Tab(text: 'Rechazadas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _bloc.add(RefreshApplications(
              microfinancieraId: widget.microfinancieraId,
              agentId: widget.agentId,
            )),
          ),
        ],
      ),
      body: BlocProvider(
        create: (context) => _bloc,
        child: BlocListener<AdvisorInboxBloc, AdvisorInboxState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: Colors.red,
                ),
              );
            }
            
            if (state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.successMessage!),
                  backgroundColor: Colors.green,
                ),
              );
              _bloc.clearSuccessMessage();
            }
          },
          child: Column(
            children: [
              // Estadísticas
              _buildStatsSection(),
              
              // Lista de aplicaciones
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _statusTabs.map((status) {
                    return _buildApplicationsList(status);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return BlocBuilder<AdvisorInboxBloc, AdvisorInboxState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Asignadas', state.inReviewCount, AppColors.primary),
              _buildStatCard('Disponibles', state.routedCount, Colors.orange),
              _buildStatCard('Aprobadas', state.approvedCount, Colors.green),
              _buildStatCard('Rechazadas', state.rejectedCount, Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationsList(String status) {
    return BlocBuilder<AdvisorInboxBloc, AdvisorInboxState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const LoadingIndicator();
        }

        final applications = state.applications
            .where((app) => app.status == status)
            .toList();

        if (applications.isEmpty) {
          return _buildEmptyState(status);
        }

        return RefreshIndicator(
          onRefresh: () async {
            _bloc.add(RefreshApplications(
              microfinancieraId: widget.microfinancieraId,
              agentId: widget.agentId,
            ));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              return _buildApplicationCard(application);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;

    switch (status) {
      case 'received':
        message = 'No hay solicitudes recibidas';
        icon = Icons.inbox;
        break;
      case 'routed':
        message = 'No hay solicitudes en ruta';
        icon = Icons.directions;
        break;
      case 'in_review':
        message = 'No tienes casos asignados';
        icon = Icons.assignment;
        break;
      case 'approved':
        message = 'No hay solicitudes aprobadas';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        message = 'No hay solicitudes rechazadas';
        icon = Icons.cancel;
        break;
      default:
        message = 'No hay aplicaciones';
        icon = Icons.inbox;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(LoanApplication application) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(application.status),
          child: Text(
            application.personalInfo?.firstName.substring(0, 1).toUpperCase() ?? '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${application.personalInfo?.firstName ?? ''} ${application.personalInfo?.lastName ?? ''}'.trim(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DNI: ${application.personalInfo?.documentNumber ?? 'N/A'}'),
            Text('S/ ${application.financialInfo?.loanAmount.toStringAsFixed(2) ?? '0.00'}'),
            Text('${_formatDate(application.createdAt)}'),
            if (application.routing?.agentId != null)
              Text(
                'Asignado a: ${application.routing!.agentId}',
                style: TextStyle(color: Colors.blue[600]),
              ),
          ],
        ),
        trailing: _buildTrailingActions(application),
        onTap: () => _navigateToApplicationDetail(application),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildTrailingActions(LoanApplication application) {
    if (application.status == 'routed' && application.routing?.agentId == null) {
      return BlocBuilder<AdvisorInboxBloc, AdvisorInboxState>(
        builder: (context, state) {
          return state.isTakingOwnership
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.assignment, color: AppColors.primary),
                  onPressed: () => _showTakeOwnershipDialog(application),
                );
        },
      );
    }

    return Icon(
      _getStatusIcon(application.status),
      color: _getStatusColor(application.status),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'received':
        return Colors.blue;
      case 'routed':
        return Colors.orange;
      case 'in_review':
        return AppColors.primary;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'received':
        return Icons.inbox;
      case 'routed':
        return Icons.directions;
      case 'in_review':
        return Icons.assignment;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _showTakeOwnershipDialog(LoanApplication application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tomar Posesión'),
        content: Text(
          '¿Deseas tomar posesión de la solicitud de ${application.personalInfo?.firstName ?? 'N/A'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _takeOwnership(application);
            },
            child: const Text('Tomar'),
          ),
        ],
      ),
    );
  }

  void _takeOwnership(LoanApplication application) {
    _bloc.add(TakeOwnershipOfApplication(
      microfinancieraId: widget.microfinancieraId,
      applicationId: application.id,
      agentId: widget.agentId,
      agentUserId: widget.agentUserId,
    ));
  }

  void _navigateToApplicationDetail(LoanApplication application) {
    // TODO: Navegar a la página de detalle de la aplicación
    Navigator.pushNamed(
      context,
      '/application-detail',
      arguments: {
        'application': application,
        'microfinancieraId': widget.microfinancieraId,
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
