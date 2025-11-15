import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../bloc/intake_request/intake_request_bloc.dart';
import '../../bloc/intake_request/intake_request_event.dart';
import '../../bloc/intake_request/intake_request_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _microfinancieraId = 'mf_demo_001';

  @override
  void initState() {
    super.initState();
    context.read<IntakeRequestBloc>().add(
      const IntakeRequestLoadRecent(limit: 12),
    );
  }

  Future<List<Map<String, dynamic>>> _getDailyDisbursements() async {
    final today = DateTime.now();
    final fiveDaysAgo = DateTime(today.year, today.month, today.day - 4);

    try {
      // Consulta simple sin índices compuestos
      final snapshot = await _firestore
          .collection('microfinancieras')
          .doc(_microfinancieraId)
          .collection('loanApplications')
          .where('status', isEqualTo: 'disbursed')
          .get();

      final Map<String, double> dailyAmounts = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final disbursedAt = (data['disbursedAt'] as Timestamp?)?.toDate();
        final amount = (data['financialInfo']?['loanAmount'] ?? 0).toDouble();

        if (disbursedAt != null &&
            disbursedAt.isAfter(
              fiveDaysAgo.subtract(const Duration(days: 1)),
            ) &&
            disbursedAt.isBefore(today.add(const Duration(days: 1)))) {
          final dateKey =
              '${disbursedAt.year}-${disbursedAt.month.toString().padLeft(2, '0')}-${disbursedAt.day.toString().padLeft(2, '0')}';
          dailyAmounts[dateKey] = (dailyAmounts[dateKey] ?? 0) + amount;
        }
      }

      final result = <Map<String, dynamic>>[];
      for (int i = 4; i >= 0; i--) {
        final date = DateTime(today.year, today.month, today.day - i);
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final amount = dailyAmounts[dateKey] ?? 0.0;

        result.add({
          'date': date,
          'amount': amount,
          'label': _formatDateLabel(date),
        });
      }

      return result;
    } catch (e) {
      return _getSimulatedDailyDisbursements();
    }
  }

  List<Map<String, dynamic>> _getSimulatedDailyDisbursements() {
    final today = DateTime.now();
    return List.generate(5, (index) {
      final date = today.subtract(Duration(days: 4 - index));
      final amount = _generateDisbursementAmount(date);
      return {'date': date, 'amount': amount, 'label': _formatDateLabel(date)};
    });
  }

  double _generateDisbursementAmount(DateTime date) {
    final seed = date.day + date.month * 31;
    final random = (seed * 9301 + 49297) % 233280;
    return (random / 233280) * 50000 + 10000;
  }

  String _formatDateLabel(DateTime date) {
    final days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return '${days[date.weekday % 7]}\n${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return BlocBuilder<IntakeRequestBloc, IntakeRequestState>(
      builder: (context, state) {
        if (state.status == IntakeRequestStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final counts = state.statusCounts;
        final normalized = _normalizeCounts(counts);
        final total = normalized['total'] ?? 0;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<IntakeRequestBloc>().add(
              const IntakeRequestRefreshRequested(),
            );
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.07, // 7% del ancho
                  ),
                ),
                SizedBox(height: screenHeight * 0.01), // 1% de la altura
                Text(
                  'Resumen de solicitudes y estado de pipeline',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    fontSize: screenWidth * 0.035, // 3.5% del ancho
                  ),
                ),
                SizedBox(height: screenHeight * 0.03), // 3% de la altura
                _buildMetrics(context, normalized),
                SizedBox(height: screenHeight * 0.03), // 3% de la altura
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getDailyDisbursements(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    final dailyDisbursements =
                        snapshot.data ?? _getSimulatedDailyDisbursements();
                    return _BarChartCard(
                      dailyDisbursements: dailyDisbursements,
                    );
                  },
                ),
                SizedBox(height: screenHeight * 0.03), // 3% de la altura
                _PieChartCard(normalized: normalized),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, int> _normalizeCounts(Map<String, int> raw) {
    final approved = (raw['converted'] ?? 0) + (raw['approved'] ?? 0);
    final rejected = raw['rejected'] ?? 0;
    final pending =
        (raw['received'] ?? 0) +
        (raw['validated'] ?? 0) +
        (raw['routed'] ?? 0) +
        (raw['pending'] ?? 0) +
        (raw['in_review'] ?? 0);
    final desembolsadas = raw['disbursed'] ?? 0;
    final enRevision = raw['in_review'] ?? 0;
    final total = raw.values.fold<int>(0, (a, b) => a + b);
    return {
      'aprobadas': approved,
      'rechazadas': rejected,
      'pendientes': pending,
      'desembolsadas': desembolsadas,
      'en_revision': enRevision,
      'total': total,
    };
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.normalized, required this.total});

  final Map<String, int> normalized;
  final int total;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final children = [
          _MetricCard(
            title: 'Total solicitudes',
            value: total,
            color: Colors.blue,
          ),
          _MetricCard(
            title: 'Aprobadas',
            value: normalized['aprobadas'] ?? 0,
            color: Colors.green,
          ),
          _MetricCard(
            title: 'Rechazadas',
            value: normalized['rechazadas'] ?? 0,
            color: Colors.red,
          ),
          _MetricCard(
            title: 'Pendientes',
            value: normalized['pendientes'] ?? 0,
            color: Colors.orange,
          ),
          _MetricCard(
            title: 'Desembolsadas',
            value: normalized['desembolsadas'] ?? 0,
            color: Colors.purple,
          ),
          _MetricCard(
            title: 'En revisión',
            value: normalized['en_revision'] ?? 0,
            color: Colors.blue,
          ),
        ];

        if (isWide) {
          return Column(
            children: [
              // Primera fila: solo Total
              children[0],
              const SizedBox(height: 12),
              // Segunda fila: Aprobadas, Rechazadas, Pendientes
              Row(
                children: [
                  Expanded(child: children[1]),
                  const SizedBox(width: 12),
                  Expanded(child: children[2]),
                  const SizedBox(width: 12),
                  Expanded(child: children[3]),
                ],
              ),
              const SizedBox(height: 12),
              // Tercera fila: Desembolsadas, En revisión
              Row(
                children: [
                  Expanded(child: children[4]),
                  const SizedBox(width: 12),
                  Expanded(child: children[5]),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            children[0],
            const SizedBox(height: 12),
            children[1],
            const SizedBox(height: 12),
            children[2],
            const SizedBox(height: 12),
            children[3],
            const SizedBox(height: 12),
            children[4],
            const SizedBox(height: 12),
            children[5],
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04), // 4% del ancho
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: screenWidth * 0.035, // 3.5% del ancho
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.01), // 1% de la altura
            Container(
              width: screenWidth * 0.1, // 10% del ancho
              height: screenWidth * 0.1, // 10% del ancho (mantener cuadrado)
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(screenWidth * 0.03), // 3% del ancho
              ),
              child: Icon(
                Icons.analytics, 
                color: color,
                size: screenWidth * 0.06, // 6% del ancho
              ),
            ),
            SizedBox(height: screenHeight * 0.01), // 1% de la altura
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: screenWidth * 0.05, // 5% del ancho
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({required this.dailyDisbursements});

  final List<Map<String, dynamic>> dailyDisbursements;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montos desembolsados por día (Últimos 5 días)',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${(value / 1000).toStringAsFixed(0)}K',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= dailyDisbursements.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dailyDisbursements[index]['label'] as String,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: dailyDisbursements
                      .asMap()
                      .entries
                      .map(
                        (entry) => BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: (entry.value['amount'] as double),
                              color: Colors.purple,
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PieChartCard extends StatelessWidget {
  const _PieChartCard({required this.normalized});

  final Map<String, int> normalized;

  @override
  Widget build(BuildContext context) {
    final pendientes = (normalized['pendientes'] ?? 0).toDouble();
    final aprobadas = (normalized['aprobadas'] ?? 0).toDouble();
    final rechazadas = (normalized['rechazadas'] ?? 0).toDouble();
    final desembolsadas = (normalized['desembolsadas'] ?? 0).toDouble();
    final enRevision = (normalized['en_revision'] ?? 0).toDouble();
    final total =
        pendientes + aprobadas + rechazadas + desembolsadas + enRevision;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución por categoría (Pastel)',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: [
                    if (pendientes > 0)
                      PieChartSectionData(
                        color: Colors.orange,
                        value: pendientes,
                        title: _percentLabel(pendientes, total),
                        radius: 80,
                      ),
                    if (aprobadas > 0)
                      PieChartSectionData(
                        color: Colors.green,
                        value: aprobadas,
                        title: _percentLabel(aprobadas, total),
                        radius: 80,
                      ),
                    if (rechazadas > 0)
                      PieChartSectionData(
                        color: Colors.red,
                        value: rechazadas,
                        title: _percentLabel(rechazadas, total),
                        radius: 80,
                      ),
                    if (desembolsadas > 0)
                      PieChartSectionData(
                        color: Colors.purple,
                        value: desembolsadas,
                        title: _percentLabel(desembolsadas, total),
                        radius: 80,
                      ),
                    if (enRevision > 0)
                      PieChartSectionData(
                        color: Colors.teal,
                        value: enRevision,
                        title: _percentLabel(enRevision, total),
                        radius: 80,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (pendientes > 0)
                  _LegendChip(label: 'Pendientes', color: Colors.orange),
                if (aprobadas > 0)
                  _LegendChip(label: 'Aprobadas', color: Colors.green),
                if (rechazadas > 0)
                  _LegendChip(label: 'Rechazadas', color: Colors.red),
                if (desembolsadas > 0)
                  _LegendChip(label: 'Desembolsadas', color: Colors.purple),
                if (enRevision > 0)
                  _LegendChip(label: 'En revisión', color: Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _percentLabel(double value, double total) {
    if (total == 0) return '0%';
    final pct = (value / total * 100).round();
    return '$pct%';
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: CircleAvatar(backgroundColor: color, radius: 8),
      backgroundColor: color.withOpacity(0.1),
    );
  }
}

  Widget _buildMetrics(BuildContext context, Map<String, int> normalized) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Column(
      children: [
        // Fila 1: Solo Total
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total solicitudes',
                value: normalized['total'] ?? 0,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.02), // 2% de la altura

        // Fila 2: Aprobadas, Rechazadas, Pendientes
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Aprobadas',
                value: normalized['aprobadas'] ?? 0,
                color: Colors.green,
              ),
            ),
            SizedBox(width: screenWidth * 0.04), // 4% del ancho
            Expanded(
              child: _MetricCard(
                title: 'Rechazadas',
                value: normalized['rechazadas'] ?? 0,
                color: Colors.red,
              ),
            ),
            SizedBox(width: screenWidth * 0.04), // 4% del ancho
            Expanded(
              child: _MetricCard(
                title: 'Pendientes',
                value: normalized['pendientes'] ?? 0,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.02), // 2% de la altura

        // Fila 3: Desembolsadas, En revisión
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Desembolsadas',
                value: normalized['desembolsadas'] ?? 0,
                color: Colors.purple,
              ),
            ),
            SizedBox(width: screenWidth * 0.04), // 4% del ancho
            Expanded(
              child: _MetricCard(
                title: 'En revisión',
                value: normalized['en_revision'] ?? 0,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
}
