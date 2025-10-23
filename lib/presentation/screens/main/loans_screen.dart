import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({Key? key}) : super(key: key);

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _microfinancieraId = 'mf_demo_001';

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_PE',
    symbol: 'S/',
    decimalDigits: 2,
  );

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  Stream<QuerySnapshot> _getLoansStream() {
    return _firestore
        .collection('microfinancieras')
        .doc(_microfinancieraId)
        .collection('loanApplications')
        .where('status', isEqualTo: 'disbursed')
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> _getRepaymentSchedule(
    String loanId,
  ) async {
    final snapshot = await _firestore
        .collection('microfinancieras')
        .doc(_microfinancieraId)
        .collection('loanApplications')
        .doc(loanId)
        .collection('repaymentSchedule')
        .get();

    final schedule = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'installmentNumber': data['installmentNumber'] ?? 0,
        'dueDate': (data['dueDate'] as Timestamp).toDate(),
        'totalPayment': data['totalPayment'] ?? 0.0,
        'principal': data['principal'] ?? 0.0,
        'interest': data['interest'] ?? 0.0,
        'remainingBalance': data['remainingBalance'] ?? 0.0,
        'status': data['status'] ?? 'pending',
      };
    }).toList();

    schedule.sort(
      (a, b) => (a['installmentNumber'] as int).compareTo(
        b['installmentNumber'] as int,
      ),
    );

    return schedule;
  }

  void _showScheduleModal(
    BuildContext context,
    String loanId,
    String clientName,
    double loanAmount,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cronograma de Pagos',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                clientName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _currencyFormat.format(loanAmount),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Schedule table
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getRepaymentSchedule(loanId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final schedule = snapshot.data ?? [];

                    return SingleChildScrollView(
                      controller: scrollController,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 12,
                          horizontalMargin: 16,
                          headingRowHeight: 48,
                          dataRowHeight: 56,
                          headingRowColor: MaterialStateProperty.all(
                            Colors.grey[100],
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                '#',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Fecha',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Monto',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Capital',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Interés',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Saldo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Estado',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          rows: schedule.map((payment) {
                            final status = payment['status'] as String;
                            return DataRow(
                              color: MaterialStateProperty.resolveWith<Color?>((
                                Set<MaterialState> states,
                              ) {
                                if (status == 'paid') {
                                  return Colors.green.withOpacity(0.1);
                                } else if (status == 'overdue') {
                                  return Colors.red.withOpacity(0.1);
                                }
                                return null;
                              }),
                              cells: [
                                DataCell(
                                  Text(
                                    '${payment['installmentNumber']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _dateFormat.format(
                                      payment['dueDate'] as DateTime,
                                    ),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _currencyFormat.format(
                                      payment['totalPayment'],
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _currencyFormat.format(
                                      payment['principal'],
                                    ),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _currencyFormat.format(payment['interest']),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _currencyFormat.format(
                                      payment['remainingBalance'],
                                    ),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                DataCell(_buildStatusBadge(status)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'paid':
        color = Colors.green;
        text = 'Pagado';
        break;
      case 'overdue':
        color = Colors.red;
        text = 'Vencido';
        break;
      case 'pending':
      default:
        color = Colors.orange;
        text = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _getLoansStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final loans = snapshot.data?.docs ?? [];

          if (loans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes préstamos activos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cuando tu solicitud sea aprobada\ny desembolsada, aparecerá aquí',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loanDoc = loans[index];
              final loanData = loanDoc.data() as Map<String, dynamic>;
              final financialInfo =
                  loanData['financialInfo'] as Map<String, dynamic>? ?? {};
              final personalInfo =
                  loanData['personalInfo'] as Map<String, dynamic>? ?? {};
              final disbursedAt = loanData['disbursedAt'] as Timestamp?;

              final clientName =
                  '${personalInfo['firstName'] ?? ''} ${personalInfo['lastName'] ?? ''}'
                      .trim();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monto del préstamo
                      Text(
                        _currencyFormat.format(
                          financialInfo['loanAmount'] ?? 0,
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Nombre del cliente
                      if (clientName.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              clientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),

                      // Fecha de desembolso
                      Text(
                        'Desembolsado: ${disbursedAt != null ? _dateFormat.format(disbursedAt.toDate()) : 'N/A'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),

                      // Información adicional
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.calendar_today,
                            label:
                                '${financialInfo['loanTermMonths'] ?? 0} meses',
                          ),
                          _InfoChip(
                            icon: Icons.trending_up,
                            label: '${loanData['interestRate'] ?? 0}% anual',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Botón para ver cronograma
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showScheduleModal(
                            context,
                            loanDoc.id,
                            clientName,
                            (financialInfo['loanAmount'] ?? 0).toDouble(),
                          ),
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Ver Cronograma de Pagos'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
