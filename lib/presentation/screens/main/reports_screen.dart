import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/usecases/reports/generate_report_usecase.dart';
import '../../../domain/usecases/reports/get_conversion_metrics_usecase.dart';
import '../../../domain/usecases/reports/debug_applications_count_usecase.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Use cases - TODO: Inyectar mediante dependency injection
  late final GenerateReportUseCase _generateReportUseCase;
  late final GetConversionMetricsUseCase _getConversionMetricsUseCase;
  late final DebugApplicationsCountUseCase _debugApplicationsCountUseCase;

  // Ampliar rango por defecto a 1 año para capturar todas las solicitudes
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;
  List<dynamic>? _reportData;
  Map<String, dynamic>? _metrics;

  @override
  void initState() {
    super.initState();
    // TODO: Reemplazar con inyección de dependencias
    _generateReportUseCase = GenerateReportUseCase();
    _getConversionMetricsUseCase = GetConversionMetricsUseCase();
    _debugApplicationsCountUseCase = DebugApplicationsCountUseCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Reportes y Análisis',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Analiza el rendimiento de tu cartera de préstamos',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Filtros de fecha
            _buildDateFilters(),
            const SizedBox(height: 16),

            // Botones de acción
            _buildActionButtons(),
            const SizedBox(height: 24),

            // Métricas
            if (_metrics != null) ...[
              _buildMetrics(),
              const SizedBox(height: 24),
            ],

            // Tabla de datos
            if (_reportData != null) _buildReportTable(),

            // Loading
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Período del Reporte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    label: 'Desde',
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateButton(
                    label: 'Hasta',
                    date: _endDate,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateReport,
                icon: const Icon(Icons.assessment),
                label: const Text('Generar Reporte'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _loadMetrics,
                icon: const Icon(Icons.analytics),
                label: const Text('Ver Métricas'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Botón de debug
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _debugCount,
            icon: const Icon(Icons.bug_report),
            label: const Text('Debug: Ver Total de Solicitudes'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(12),
              foregroundColor: Colors.orange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Métricas de Conversión',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Total Solicitudes',
              _metrics!['totalApplications'].toString(),
              Icons.description,
              Colors.blue,
            ),
            _buildMetricRow(
              'Aprobadas',
              _metrics!['approved'].toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildMetricRow(
              'Rechazadas',
              _metrics!['rejected'].toString(),
              Icons.cancel,
              Colors.red,
            ),
            _buildMetricRow(
              'Desembolsadas',
              _metrics!['disbursed'].toString(),
              Icons.attach_money,
              Colors.purple,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Tasa de Conversión',
              '${(_metrics!['conversionRate'] * 100).toStringAsFixed(1)}%',
              Icons.trending_up,
              Colors.orange,
            ),
            _buildMetricRow(
              'Tiempo Promedio',
              '${_metrics!['avgProcessingDays'].toStringAsFixed(1)} días',
              Icons.schedule,
              Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Solicitudes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_reportData!.length} registros',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Cliente')),
                  DataColumn(label: Text('DNI')),
                  DataColumn(label: Text('Monto')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Banda')),
                ],
                rows: _reportData!.map((app) {
                  return DataRow(
                    cells: [
                      DataCell(Text(app['customerName'] ?? 'N/A')),
                      DataCell(Text(app['dni'] ?? 'N/A')),
                      DataCell(
                        Text(
                          'S/ ${app['loanAmount']?.toStringAsFixed(0) ?? '0'}',
                        ),
                      ),
                      DataCell(_buildStatusChip(app['status'])),
                      DataCell(Text(app['scoreBand'] ?? 'N/A')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'disbursed':
        color = Colors.green;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
      _reportData = null;
    });

    final result = await _generateReportUseCase.call(
      GenerateReportParams(
        microfinancieraId: 'mf_demo_001',
        dateFrom: _startDate,
        dateTo: _endDate,
      ),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error generando reporte: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (data) {
        setState(() {
          _reportData = data;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte generado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _metrics = null;
    });

    final result = await _getConversionMetricsUseCase.call(
      GetConversionMetricsParams(
        microfinancieraId: 'mf_demo_001',
        dateFrom: _startDate,
        dateTo: _endDate,
      ),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cargando métricas: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (data) {
        setState(() {
          _metrics = data;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _debugCount() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _debugApplicationsCountUseCase.call(
      DebugApplicationsCountParams(
        microfinancieraId: 'mf_demo_001',
      ),
    );

    setState(() {
      _isLoading = false;
    });

    result.fold(
      (failure) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Error obteniendo datos: ${failure.message}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      (response) {
        if (mounted) {
          // Mostrar diálogo con los resultados
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Debug: Total de Solicitudes'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: ${response['total']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...response['by_status']
                        .entries
                        .map<Widget>((entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
