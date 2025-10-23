import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/logging/app_logger.dart';
import '../../../domain/entities/loan_application.dart';
import '../../../data/datasources/backend_api_datasource.dart';
import '../../../data/datasources/loan_application_datasource.dart';
import '../../../data/repositories/loan_application_repository_impl.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/datasources/firebase_auth_datasource.dart';
import '../../../domain/usecases/loan_application/update_application_status_usecase.dart';
import '../../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../utils/product_colors.dart';

class LoanApplicationDetailPage extends StatelessWidget {
  final LoanApplication application;

  const LoanApplicationDetailPage({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    final isDisbursed = application.status == 'disbursed';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Solicitud'),
        actions: [
          if (!isDisbursed)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showChangeStatusDialog(context),
              tooltip: 'Cambiar Estado',
            ),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context),
            const SizedBox(height: 16),
            if (application.product != null) ...[
              _buildProductInfo(context),
              const SizedBox(height: 16),
            ],
            if (application.personalInfo != null) ...[
              _buildPersonalInfo(context),
              const SizedBox(height: 16),
            ],
            if (application.contactInfo != null) ...[
              _buildContactInfo(context),
              const SizedBox(height: 16),
            ],
            if (application.employmentInfo != null) ...[
              _buildEmploymentInfo(context),
              const SizedBox(height: 16),
            ],
            if (application.financialInfo != null) ...[
              _buildFinancialInfo(context),
              const SizedBox(height: 16),
            ],
            if (application.additionalInfo != null) ...[
              _buildAdditionalInfo(context),
              const SizedBox(height: 16),
            ],
            if (application.consents != null) ...[
              _buildConsents(context),
              const SizedBox(height: 16),
            ],
            if (application.location != null) ...[
              _buildLocationInfo(context),
              const SizedBox(height: 16),
            ],
            // Botones de acción
            _buildActionButtons(context),
            const SizedBox(height: 16),
            _buildTimestamps(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Acciones',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Botón Calcular Scoring (solo si no tiene scoring Y NO está desembolsado)
            if (application.status == 'in_review' &&
                application.scoring == null &&
                application.status != 'disbursed')
              ElevatedButton.icon(
                onPressed: () => _calculateScoring(context),
                icon: const Icon(Icons.calculate),
                label: const Text('Calcular Scoring'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),

            // Botón Ver Scoring (si ya tiene scoring)
            if (application.scoring != null) ...[
              ElevatedButton.icon(
                onPressed: () => _viewScoring(context),
                icon: const Icon(Icons.assessment),
                label: const Text('Ver Scoring'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Botón Aprobar Definitivamente (si está pre-aprobado)
            if (application.decision != null &&
                application.decision!.result == 'observed' &&
                application.decision!.isAutomatic &&
                application.decision!.comments.contains('Pre-aprobado'))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _approveFinally(context),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Aprobar Definitivamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

            // Botón Tomar Decisión (para otros casos, pero NO si está desembolsado)
            if ((application.status == 'decision' ||
                    application.status == 'observed' ||
                    (application.status == 'in_review' &&
                        application.scoring != null)) &&
                application.status != 'disbursed')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _goToDecisionPage(context),
                  icon: const Icon(Icons.gavel),
                  label: const Text('Tomar Decisión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

            // Botón Desembolsar (solo si está aprobado Y NO desembolsado)
            if (application.status == 'approved')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _disburseLoan(context),
                  icon: const Icon(Icons.attach_money),
                  label: const Text('Desembolsar Crédito'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

            // Mensaje si ya está desembolsado
            if (application.status == 'disbursed')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Préstamo Desembolsado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                            Text(
                              'Este crédito ya fue desembolsado exitosamente',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _viewScoring(BuildContext context) {
    if (application.scoring == null) return;

    final scoring = application.scoring!;
    final decision = application.decision;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resultado del Scoring'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score y Banda
              Card(
                color: _getBandColor(scoring.band),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Banda ${scoring.band}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Score: ${scoring.score}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Decisión
              if (decision != null) ...[
                const Text(
                  'Decisión Automática',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getDecisionColor(decision.result).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getDecisionColor(decision.result),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getDecisionIcon(decision.result),
                            color: _getDecisionColor(decision.result),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getDecisionText(decision.result),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getDecisionColor(decision.result),
                            ),
                          ),
                        ],
                      ),
                      if (decision.comments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          decision.comments,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Reason Codes
              const Text(
                'Factores Principales',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...scoring.reasonCodes.map(
                (code) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(code)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _calculateScoring(context);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Recalcular'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBandColor(String band) {
    switch (band) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getDecisionColor(String result) {
    switch (result) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'observed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getDecisionIcon(String result) {
    switch (result) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'observed':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  String _getDecisionText(String result) {
    switch (result) {
      case 'approved':
        return 'APROBADO';
      case 'rejected':
        return 'RECHAZADO';
      case 'observed':
        return 'OBSERVADO';
      default:
        return result.toUpperCase();
    }
  }

  Future<void> _calculateScoring(BuildContext context) async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Calcular Scoring'),
        content: const Text(
          '¿Deseas calcular el scoring para esta solicitud? '
          'Esto evaluará automáticamente la capacidad crediticia del cliente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Calcular'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      AppLogger.api(
        'Calculando scoring',
        data: {
          'microfinancieraId': application.microfinancieraId,
          'applicationId': application.id,
        },
      );

      final backendApi = BackendApiDatasource();
      final result = await backendApi.calculateScoring(
        microfinancieraId: application.microfinancieraId, // Usar el del objeto
        applicationId: application.id,
      );

      AppLogger.api(
        'Respuesta scoring recibida',
        data: {
          'hasScoring': result['scoring'] != null,
          'hasDecision': result['decision'] != null,
          'score': result['scoring']?['score'],
          'band': result['scoring']?['band'],
          'decisionResult': result['decision']?['result'],
        },
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Cerrar loading

        // Mostrar resultado
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Scoring Calculado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score: ${result['scoring']?['score'] ?? 'N/A'}'),
                Text('Banda: ${result['scoring']?['band'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Decisión: ${result['decision']?['result'] ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text(
                  result['decision']?['comments'] ?? 'Sin comentarios',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Cerrar diálogo
                  Navigator.of(context).pop(); // Volver a la lista
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculando scoring: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goToDecisionPage(BuildContext context) {
    String selectedDecision = 'approved';
    final commentsController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tomar Decisión Manual'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mostrar scoring si existe
              if (application.scoring != null) ...[
                Card(
                  color: _getBandColor(
                    application.scoring!.band,
                  ).withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          'Banda ${application.scoring!.band}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getBandColor(application.scoring!.band),
                          ),
                        ),
                        Text(
                          'Score: ${application.scoring!.score}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Text(
                'Decisión',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Radio buttons para decisión
              StatefulBuilder(
                builder: (context, setState) => Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Aprobar'),
                      value: 'approved',
                      groupValue: selectedDecision,
                      onChanged: (value) {
                        setState(() => selectedDecision = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Rechazar'),
                      value: 'rejected',
                      groupValue: selectedDecision,
                      onChanged: (value) {
                        setState(() => selectedDecision = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Observar'),
                      value: 'observed',
                      groupValue: selectedDecision,
                      onChanged: (value) {
                        setState(() => selectedDecision = value!);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Comentarios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ingrese sus comentarios (mínimo 5 caracteres)...',
                  helperText: 'Explique brevemente el motivo de su decisión',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validar comentarios
              if (commentsController.text.trim().length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Los comentarios deben tener al menos 5 caracteres',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.of(dialogContext).pop();
              await _makeManualDecision(
                context,
                selectedDecision,
                commentsController.text.trim(),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveFinally(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aprobar Definitivamente'),
        content: const Text(
          '¿Confirmas la aprobación definitiva de este crédito?\n\n'
          'El cliente podrá proceder con el desembolso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _makeManualDecision(
      context,
      'approved',
      'Aprobación final confirmada por el analista',
    );
  }

  Future<void> _makeManualDecision(
    BuildContext context,
    String result,
    String comments,
  ) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final backendApi = BackendApiDatasource();
      await backendApi.makeManualDecision(
        microfinancieraId: application.microfinancieraId,
        applicationId: application.id,
        result: result,
        comments: comments,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Cerrar loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Decisión registrada: ${_getDecisionText(result)}'),
            backgroundColor: Colors.green,
          ),
        );

        // Volver a la lista
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Cerrar loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error tomando decisión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disburseLoan(BuildContext context) async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desembolsar Crédito'),
        content: Text(
          '¿Confirmas el desembolso de S/ ${application.financialInfo?.loanAmount.toStringAsFixed(2)} '
          'a ${application.personalInfo?.firstName} ${application.personalInfo?.lastName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar Desembolso'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final backendApi = BackendApiDatasource();
      final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';

      await backendApi.disburseLoan(
        microfinancieraId: application.microfinancieraId,
        applicationId: application.id,
        requestId: requestId,
      );

      if (context.mounted) {
        Navigator.of(context).pop(); // Cerrar loading

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crédito desembolsado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Recargar página
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                LoanApplicationDetailPage(application: application),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error desembolsando: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusCard(BuildContext context) {
    final statusColor = _getStatusColor(application.status);
    final statusText = _getStatusText(application.status);

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
                _getStatusIcon(application.status),
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

  Widget _buildProductInfo(BuildContext context) {
    final product = application.product!;
    final productColor = ProductColors.getColorByCode(product.code);
    final productIcon = ProductColors.getIconByCode(product.code);

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: productColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: productColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: productColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(productIcon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: productColor,
                      ),
                    ),
                    Text(
                      'Código: ${product.code}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProductDetail('Tasa', '${product.rateNominal}%'),
              _buildProductDetail(
                'Tipo',
                product.interestType == 'flat' ? 'Plana' : 'Efectiva',
              ),
              _buildProductDetail(
                'Plazo',
                '${product.termMin}-${product.termMax}m',
              ),
              _buildProductDetail(
                'Monto',
                'S/${product.amountMin.toInt()}-${product.amountMax.toInt()}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetail(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo(BuildContext context) {
    final info = application.personalInfo!;
    return _buildSection(
      context,
      title: 'Datos Personales',
      icon: Icons.person,
      children: [
        _buildInfoRow(context, 'Nombres', info.firstName),
        _buildInfoRow(context, 'Apellidos', info.lastName),
        _buildInfoRow(context, 'Tipo de Documento', info.documentType),
        _buildInfoRow(context, 'Número de Documento', info.documentNumber),
        _buildInfoRow(context, 'Fecha de Nacimiento', info.birthDate),
        _buildInfoRow(context, 'Nacionalidad', info.nationality),
        _buildInfoRow(
          context,
          'Estado Civil',
          _getMaritalStatusText(info.maritalStatus),
        ),
        if (info.dependents != null)
          _buildInfoRow(context, 'Dependientes', '${info.dependents}'),
      ],
    );
  }

  Widget _buildContactInfo(BuildContext context) {
    final info = application.contactInfo!;
    return _buildSection(
      context,
      title: 'Información de Contacto',
      icon: Icons.contact_phone,
      children: [
        _buildInfoRow(context, 'Dirección', info.address),
        _buildInfoRow(context, 'Distrito', info.district),
        _buildInfoRow(context, 'Provincia', info.province),
        _buildInfoRow(context, 'Departamento', info.department),
        _buildInfoRow(context, 'Teléfono Móvil', info.mobilePhone),
        _buildInfoRow(context, 'Email', info.email),
        if (info.homeReference != null)
          _buildInfoRow(context, 'Referencia', info.homeReference!),
      ],
    );
  }

  Widget _buildEmploymentInfo(BuildContext context) {
    final info = application.employmentInfo!;
    return _buildSection(
      context,
      title: 'Información Laboral',
      icon: Icons.work,
      children: [
        _buildInfoRow(
          context,
          'Tipo de Empleo',
          _getEmploymentTypeText(info.employmentType),
        ),
        if (info.employerName != null)
          _buildInfoRow(context, 'Empleador', info.employerName!),
        if (info.position != null)
          _buildInfoRow(context, 'Cargo', info.position!),
        if (info.yearsEmployed != null || info.monthsEmployed != null)
          _buildInfoRow(
            context,
            'Antigüedad',
            '${info.yearsEmployed ?? 0} años, ${info.monthsEmployed ?? 0} meses',
          ),
        if (info.contractType != null)
          _buildInfoRow(
            context,
            'Tipo de Contrato',
            _getContractTypeText(info.contractType!),
          ),
        if (info.workPhone != null)
          _buildInfoRow(context, 'Teléfono Trabajo', info.workPhone!),
      ],
    );
  }

  Widget _buildFinancialInfo(BuildContext context) {
    final info = application.financialInfo!;
    return _buildSection(
      context,
      title: 'Información Financiera',
      icon: Icons.attach_money,
      children: [
        _buildInfoRow(
          context,
          'Ingreso Mensual',
          'S/ ${info.monthlyIncome.toStringAsFixed(2)}',
        ),
        if (info.otherIncome != null)
          _buildInfoRow(
            context,
            'Otros Ingresos',
            'S/ ${info.otherIncome!.toStringAsFixed(2)}',
          ),
        if (info.otherIncomeSource != null)
          _buildInfoRow(
            context,
            'Fuente Otros Ingresos',
            info.otherIncomeSource!,
          ),
        if (info.monthlyExpenses != null)
          _buildInfoRow(
            context,
            'Gastos Mensuales',
            'S/ ${info.monthlyExpenses!.toStringAsFixed(2)}',
          ),
        if (info.currentDebts != null)
          _buildInfoRow(
            context,
            'Deudas Actuales',
            'S/ ${info.currentDebts!.toStringAsFixed(2)}',
          ),
        if (info.currentDebtsEntity != null)
          _buildInfoRow(context, 'Entidad Deudas', info.currentDebtsEntity!),
        const Divider(height: 24),
        _buildInfoRow(
          context,
          'Monto Solicitado',
          'S/ ${info.loanAmount.toStringAsFixed(2)}',
          valueColor: Colors.blue,
        ),
        _buildInfoRow(context, 'Plazo', '${info.loanTermMonths} meses'),
        _buildInfoRow(
          context,
          'Propósito',
          _getLoanPurposeText(info.loanPurpose),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(BuildContext context) {
    final info = application.additionalInfo!;
    return _buildSection(
      context,
      title: 'Información Adicional',
      icon: Icons.info,
      children: [
        _buildInfoRow(
          context,
          'Historial Crediticio',
          info.hasCreditHistory ? 'Sí' : 'No',
        ),
        _buildInfoRow(
          context,
          'Cuenta Bancaria',
          info.hasBankAccount ? 'Sí' : 'No',
        ),
        if (info.bankName != null)
          _buildInfoRow(context, 'Banco', info.bankName!),
        _buildInfoRow(
          context,
          'Tiene Garantía',
          info.hasGuarantee ? 'Sí' : 'No',
        ),
        if (info.guaranteeDescription != null)
          _buildInfoRow(
            context,
            'Descripción Garantía',
            info.guaranteeDescription!,
          ),
        if (info.additionalComments != null)
          _buildInfoRow(context, 'Comentarios', info.additionalComments!),
      ],
    );
  }

  Widget _buildConsents(BuildContext context) {
    final consents = application.consents!;
    return _buildSection(
      context,
      title: 'Consentimientos',
      icon: Icons.check_circle,
      children: [
        _buildConsentRow(
          context,
          'Términos y Condiciones',
          consents.acceptTerms,
        ),
        _buildConsentRow(
          context,
          'Consulta Crediticia',
          consents.authorizeCreditCheck,
        ),
        _buildConsentRow(
          context,
          'Veracidad de Información',
          consents.confirmTruthfulness,
        ),
      ],
    );
  }

  Widget _buildLocationInfo(BuildContext context) {
    final location = application.location!;
    return _buildSection(
      context,
      title: 'Ubicación',
      icon: Icons.location_on,
      children: [
        _buildInfoRow(context, 'Latitud', location.latitude.toStringAsFixed(6)),
        _buildInfoRow(
          context,
          'Longitud',
          location.longitude.toStringAsFixed(6),
        ),
      ],
    );
  }

  Widget _buildTimestamps(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return _buildSection(
      context,
      title: 'Fechas',
      icon: Icons.access_time,
      children: [
        _buildInfoRow(
          context,
          'Creado',
          dateFormat.format(application.createdAt),
        ),
        _buildInfoRow(
          context,
          'Actualizado',
          dateFormat.format(application.updatedAt),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentRow(BuildContext context, String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _showChangeStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cambiar Estado de Solicitud'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'La solicitud se cambiará a:',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _buildStatusButton(
                context,
                'En Revisión',
                'in_review',
                Icons.rate_review,
                Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildStatusButton(
                context,
                'Aprobada',
                'approved',
                Icons.check_circle,
                Colors.green,
              ),
              const SizedBox(height: 8),
              _buildStatusButton(
                context,
                'Rechazada',
                'rejected',
                Icons.cancel,
                Colors.red,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    String label,
    String status,
    IconData icon,
    Color color,
  ) {
    final isCurrentStatus = application.status == status;

    return ElevatedButton.icon(
      onPressed: isCurrentStatus
          ? null
          : () {
              Navigator.of(context).pop();
              _changeStatus(context, status);
            },
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrentStatus ? Colors.grey : color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Future<void> _changeStatus(BuildContext context, String newStatus) async {
    // VALIDACIÓN CRÍTICA: No permitir cambiar estado de préstamos desembolsados
    if (application.status == 'disbursed') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede cambiar el estado de un préstamo ya desembolsado',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Guardar referencias antes del async
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Obtener usuario actual
      final authDataSource = FirebaseAuthDataSource();
      final authRepository = AuthRepositoryImpl(dataSource: authDataSource);
      final getCurrentUserUseCase = GetCurrentUserUseCase(authRepository);
      
      final userResult = await getCurrentUserUseCase();
      
      String userId = '';
      userResult.fold(
        (failure) {
          throw Exception('No se pudo obtener el usuario actual: ${failure.message}');
        },
        (user) {
          if (user == null) {
            throw Exception('Usuario no autenticado');
          }
          userId = user.uid;
        },
      );

      // Usar UpdateApplicationStatusUseCase siguiendo arquitectura limpia
      final dataSource = LoanApplicationDataSource();
      final repository = LoanApplicationRepositoryImpl(dataSource: dataSource);
      final updateStatusUseCase = UpdateApplicationStatusUseCase(repository);
      
      final result = await updateStatusUseCase(
        microfinancieraId: application.microfinancieraId,
        applicationId: application.id,
        newStatus: newStatus,
        userId: userId,
        reason: 'Cambio manual desde app móvil',
      );

      // Cerrar loading
      navigator.pop();

      result.fold(
        (failure) {
          // Mostrar error
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error al cambiar estado: ${failure.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          
          AppLogger.error('Error cambiando estado de aplicación', error: failure.message);
        },
        (_) {
          // Mostrar mensaje de éxito
          messenger.showSnackBar(
            SnackBar(
              content: Text('Estado cambiado a: ${_getStatusText(newStatus)}'),
              backgroundColor: _getStatusColor(newStatus),
              duration: const Duration(seconds: 2),
            ),
          );

          // Volver a la pantalla anterior para que se actualice la lista
          navigator.pop();
        },
      );
    } catch (e) {
      // Cerrar loading
      navigator.pop();

      // Mostrar error
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      AppLogger.error('Error inesperado cambiando estado', error: e);
    }
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'in_review':
        return Icons.rate_review;
      default:
        return Icons.help;
    }
  }

  String _getMaritalStatusText(String status) {
    switch (status) {
      case 'soltero':
        return 'Soltero(a)';
      case 'casado':
        return 'Casado(a)';
      case 'divorciado':
        return 'Divorciado(a)';
      case 'viudo':
        return 'Viudo(a)';
      case 'conviviente':
        return 'Conviviente';
      default:
        return status;
    }
  }

  String _getEmploymentTypeText(String type) {
    switch (type) {
      case 'empleado':
        return 'Empleado';
      case 'independiente':
        return 'Independiente';
      case 'empresario':
        return 'Empresario';
      case 'jubilado':
        return 'Jubilado';
      case 'estudiante':
        return 'Estudiante';
      case 'desempleado':
        return 'Desempleado';
      default:
        return type;
    }
  }

  String _getContractTypeText(String type) {
    switch (type) {
      case 'indefinido':
        return 'Indefinido';
      case 'temporal':
        return 'Temporal';
      case 'independiente':
        return 'Independiente';
      default:
        return type;
    }
  }

  String _getLoanPurposeText(String purpose) {
    switch (purpose) {
      case 'personal':
        return 'Gastos Personales';
      case 'business':
        return 'Capital de Trabajo/Negocio';
      case 'education':
        return 'Educación';
      case 'home':
        return 'Mejoras del Hogar';
      case 'medical':
        return 'Gastos Médicos';
      case 'debt':
        return 'Consolidación de Deudas';
      case 'vehicle':
        return 'Vehículo';
      case 'other':
        return 'Otro';
      default:
        return purpose;
    }
  }
}
