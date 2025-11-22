import 'package:flutter/material.dart';

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
  late TabController _tabController;
  // TODO: Declarar bloc cuando esté correctamente configurado
  // late final AdvisorInboxBloc _bloc;
  final List<String> _statusTabs = [
    'received',
    'routed',
    'in_review',
    'approved',
    'rejected',
  ];

  @override
  void initState() {
    super.initState();

    // TODO: Implementar inyección de dependencias correcta para los casos de uso
    // Por ahora, comentamos la inicialización del bloc para evitar errores de compilación
    // _bloc = AdvisorInboxBloc(
    //   getAssignedApplicationsUseCase: GetAssignedApplicationsUseCase(repository),
    //   getApplicationsByStatusUseCase: GetApplicationsByStatusUseCase(repository),
    //   takeOwnershipOfApplicationUseCase: TakeOwnershipOfApplicationUseCase(repository),
    //   updateApplicationStatusUseCase: UpdateApplicationStatusUseCase(repository),
    //   getApplicationStatsUseCase: GetApplicationStatsUseCase(repository),
    //   getAgentStatsUseCase: GetAgentStatsUseCase(repository),
    // );

    _tabController = TabController(length: _statusTabs.length, vsync: this);

    // TODO: Cargar datos iniciales cuando el bloc esté correctamente inicializado
    // _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // TODO: Cerrar bloc cuando esté disponible
    // _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandeja de Entrada'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Implementar refresh cuando el bloc esté disponible
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Pantalla en construcción',
              style: TextStyle(fontSize: 18, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Se requiere implementar inyección de dependencias',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TODO: Implementar métodos cuando el bloc esté correctamente configurado
  /*
  Widget _buildStatsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<AdvisorInboxBloc, AdvisorInboxState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Asignadas', state.inReviewCount, colorScheme.primary, context),
              _buildStatCard('Disponibles', state.routedCount, const Color(0xFFFF9800), context),
              _buildStatCard('Aprobadas', state.approvedCount, const Color(0xFF4CAF50), context),
              _buildStatCard('Rechazadas', state.rejectedCount, colorScheme.error, context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color, BuildContext context) {
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
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
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
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(LoanApplication application) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(application.status),
          child: Text(
            application.personalInfo?.firstName.substring(0, 1).toUpperCase() ?? '?',
            style: TextStyle(
              color: colorScheme.onPrimary,
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
                style: TextStyle(color: colorScheme.primary),
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
    final colorScheme = Theme.of(context).colorScheme;
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
                  icon: Icon(Icons.assignment, color: colorScheme.primary),
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
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'received':
        return colorScheme.primary;
      case 'routed':
        return const Color(0xFFFF9800); // Warning orange
      case 'in_review':
        return colorScheme.primary;
      case 'approved':
        return const Color(0xFF4CAF50); // Success green
      case 'rejected':
        return colorScheme.error;
      default:
        return colorScheme.onSurfaceVariant;
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
  */
}
