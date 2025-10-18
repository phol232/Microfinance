import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/loan_application_datasource.dart';
import '../../data/repositories/loan_application_repository_impl.dart';
import '../../domain/repositories/loan_application_repository.dart';
import '../bloc/advisor_inbox/advisor_inbox_bloc.dart';
import '../bloc/advisor_inbox/advisor_inbox_event.dart';
import '../bloc/advisor_inbox/advisor_inbox_state.dart';
import '../components/primary_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../domain/entities/loan_application.dart';
import '../../data/datasources/backend_api_datasource.dart';

class DecisionPage extends StatefulWidget {
  final LoanApplication application;
  final String microfinancieraId;
  final String userId;

  const DecisionPage({
    Key? key,
    required this.application,
    required this.microfinancieraId,
    required this.userId,
  }) : super(key: key);

  @override
  State<DecisionPage> createState() => _DecisionPageState();
}

class _DecisionPageState extends State<DecisionPage> {
  final _commentsController = TextEditingController();
  String? _selectedDecision;
  bool _isSubmitting = false;

  final List<Map<String, String>> _decisionOptions = [
    {
      'value': 'approved',
      'label': 'Aprobar',
      'description': 'Aprobar la solicitud de crédito',
    },
    {
      'value': 'rejected',
      'label': 'Rechazar',
      'description': 'Rechazar la solicitud de crédito',
    },
    {
      'value': 'observed',
      'label': 'Observar',
      'description': 'Solicitar información adicional',
    },
  ];

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verificar si el préstamo ya fue desembolsado
    final isDisbursed = widget.application.status == 'disbursed';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Decisión de Crédito'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alerta si ya está desembolsado
            if (isDisbursed) _buildDisbursedAlert(),

            // Información del cliente
            _buildClientInfo(),

            const SizedBox(height: AppSpacing.lg),

            // Información de scoring
            if (widget.application.scoring != null) _buildScoringInfo(),

            const SizedBox(height: AppSpacing.lg),

            // Opciones de decisión (solo si NO está desembolsado)
            if (!isDisbursed) ...[
              _buildDecisionOptions(),
              const SizedBox(height: AppSpacing.lg),
              _buildCommentsSection(),
              const SizedBox(height: AppSpacing.xl),
              _buildSubmitButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisbursedAlert() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 32),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Préstamo Desembolsado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Este préstamo ya fue desembolsado. No se pueden realizar más cambios.',
                    style: TextStyle(color: Colors.green[800], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Cliente',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),

            _buildInfoRow(
              'Nombre',
              '${widget.application.personalInfo?.firstName ?? ''} ${widget.application.personalInfo?.lastName ?? ''}'
                  .trim(),
            ),
            _buildInfoRow(
              'DNI',
              widget.application.personalInfo?.documentNumber ?? 'N/A',
            ),
            _buildInfoRow(
              'Email',
              widget.application.contactInfo?.email ?? 'N/A',
            ),
            _buildInfoRow(
              'Teléfono',
              widget.application.contactInfo?.mobilePhone ?? 'N/A',
            ),
            _buildInfoRow(
              'Monto Solicitado',
              'S/ ${widget.application.financialInfo?.loanAmount.toStringAsFixed(2) ?? '0.00'}',
            ),
            _buildInfoRow(
              'Plazo',
              '${widget.application.financialInfo?.loanTermMonths ?? 0} meses',
            ),
            _buildInfoRow(
              'Ingreso Mensual',
              'S/ ${widget.application.financialInfo?.monthlyIncome.toStringAsFixed(2) ?? '0.00'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoringInfo() {
    final scoring = widget.application.scoring!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Información de Scoring',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getBandColor(scoring.band).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getBandColor(scoring.band),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Banda ${scoring.band}',
                    style: TextStyle(
                      color: _getBandColor(scoring.band),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('Score', scoring.score.toString()),
                ),
                Expanded(child: _buildInfoRow('Modelo', scoring.modelVersion)),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Reason Codes:',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: scoring.reasonCodes.map((code) {
                return Chip(
                  label: Text(code),
                  backgroundColor: Colors.blue[50],
                  labelStyle: TextStyle(fontSize: 12, color: Colors.blue[700]),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Decisión',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),

            ..._decisionOptions.map((option) {
              return RadioListTile<String>(
                value: option['value']!,
                groupValue: _selectedDecision,
                onChanged: (value) {
                  setState(() {
                    _selectedDecision = value;
                  });
                },
                title: Text(option['label']!),
                subtitle: Text(
                  option['description']!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                activeColor: _getDecisionColor(option['value']!),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comentarios *',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),

            Text(
              'Los comentarios son obligatorios (mínimo 10 caracteres)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: AppSpacing.sm),

            TextField(
              controller: _commentsController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ingresa tus comentarios sobre la decisión...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isValid =
        _selectedDecision != null &&
        _commentsController.text.trim().length >= 10;

    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        text: 'Enviar Decisión',
        onPressed: isValid && !_isSubmitting ? _submitDecision : null,
        isLoading: _isSubmitting,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
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

  Color _getDecisionColor(String decision) {
    switch (decision) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'observed':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _submitDecision() async {
    if (_selectedDecision == null ||
        _commentsController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona una decisión y agrega comentarios (mín. 10 caracteres)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Usar backend REST API en lugar de Firebase Functions
      final backendApi = BackendApiDatasource();

      await backendApi.makeManualDecision(
        microfinancieraId: widget.microfinancieraId,
        applicationId: widget.application.id,
        result: _selectedDecision!,
        comments: _commentsController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Decisión enviada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enviando decisión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
