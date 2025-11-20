import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../domain/usecases/reports/generate_report_usecase.dart';
import '../../../domain/usecases/reports/get_conversion_metrics_usecase.dart';
import '../../../domain/usecases/reports/debug_applications_count_usecase.dart';
import 'package:mobile/core/tenant/tenant_controller.dart';

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

  String? _currentMicrofinancieraId() {
    return context.read<TenantController>().tenantId;
  }

  bool _assertTenantConfigured() {
    final tenantId = _currentMicrofinancieraId();
    if (tenantId == null || tenantId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Selecciona una microfinanciera para generar reportes.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
    return true;
  }

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Reportes y Análisis',
              style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              'Analiza el rendimiento de tu cartera de préstamos',
              style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.grey),
            ),
            SizedBox(height: screenHeight * 0.03),

            // Filtros de fecha
            _buildDateFilters(),
            SizedBox(height: screenHeight * 0.02),

            // Botones de acción
            _buildActionButtons(),
            SizedBox(height: screenHeight * 0.03),

            // Métricas
            if (_metrics != null) ...[
              _buildMetrics(),
              SizedBox(height: screenHeight * 0.03),
            ],

            // Tabla de datos
            if (_reportData != null) _buildReportTable(),

            // Loading
            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.08),
                  child: const CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilters() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Período del Reporte',
              style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenHeight * 0.02),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    label: 'Desde',
                    date: _startDate,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey.shade600),
            ),
            SizedBox(height: screenHeight * 0.005),
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateReport,
                icon: Icon(Icons.assessment, size: screenWidth * 0.05),
                label: Text('Generar Reporte', style: TextStyle(fontSize: screenWidth * 0.035)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _loadMetrics,
                icon: Icon(Icons.analytics, size: screenWidth * 0.05),
                label: Text('Ver Métricas', style: TextStyle(fontSize: screenWidth * 0.035)),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.01),
        // Botón de debug
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _debugCount,
            icon: Icon(Icons.bug_report, size: screenWidth * 0.05),
            label: Text('Debug: Ver Total de Solicitudes', style: TextStyle(fontSize: screenWidth * 0.035)),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.all(screenWidth * 0.03),
              foregroundColor: Colors.orange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métricas de Conversión',
              style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenHeight * 0.02),
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
            Divider(height: screenHeight * 0.03),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: Icon(icon, color: color, size: screenWidth * 0.05),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(child: Text(label, style: TextStyle(fontSize: screenWidth * 0.035))),
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTable() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Solicitudes',
                  style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_reportData!.length} registros',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: screenWidth * 0.035),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: screenWidth * 0.05,
                horizontalMargin: screenWidth * 0.02,
                headingRowHeight: screenHeight * 0.06,
                dataRowHeight: screenHeight * 0.05,
                columns: [
                  DataColumn(label: Text('Cliente', style: TextStyle(fontSize: screenWidth * 0.035))),
                  DataColumn(label: Text('DNI', style: TextStyle(fontSize: screenWidth * 0.035))),
                  DataColumn(label: Text('Monto', style: TextStyle(fontSize: screenWidth * 0.035))),
                  DataColumn(label: Text('Estado', style: TextStyle(fontSize: screenWidth * 0.035))),
                  DataColumn(label: Text('Banda', style: TextStyle(fontSize: screenWidth * 0.035))),
                ],
                rows: _reportData!.map((app) {
                  return DataRow(
                    cells: [
                      DataCell(Text(app['customerName'] ?? 'N/A', style: TextStyle(fontSize: screenWidth * 0.032))),
                      DataCell(Text(app['dni'] ?? 'N/A', style: TextStyle(fontSize: screenWidth * 0.032))),
                      DataCell(
                        Text(
                          'S/ ${app['loanAmount']?.toStringAsFixed(0) ?? '0'}',
                          style: TextStyle(fontSize: screenWidth * 0.032),
                        ),
                      ),
                      DataCell(_buildStatusChip(app['status'])),
                      DataCell(Text(app['scoreBand'] ?? 'N/A', style: TextStyle(fontSize: screenWidth * 0.032))),
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
    final screenWidth = MediaQuery.of(context).size.width;
    
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
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenWidth * 0.01),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: screenWidth * 0.03,
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

    final microfinancieraId = _currentMicrofinancieraId();
    if (microfinancieraId == null || microfinancieraId.isEmpty) {
      _assertTenantConfigured();
      setState(() => _isLoading = false);
      return;
    }

    final result = await _generateReportUseCase.call(
      GenerateReportParams(
        microfinancieraId: microfinancieraId,
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

    final microfinancieraId = _currentMicrofinancieraId();
    if (microfinancieraId == null || microfinancieraId.isEmpty) {
      _assertTenantConfigured();
      setState(() => _isLoading = false);
      return;
    }

    final result = await _getConversionMetricsUseCase.call(
      GetConversionMetricsParams(
        microfinancieraId: microfinancieraId,
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

    final microfinancieraId = _currentMicrofinancieraId();
    if (microfinancieraId == null || microfinancieraId.isEmpty) {
      _assertTenantConfigured();
      setState(() => _isLoading = false);
      return;
    }

    final result = await _debugApplicationsCountUseCase.call(
      DebugApplicationsCountParams(
        microfinancieraId: microfinancieraId,
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
