import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../services/campus_tools.dart';
import '../theme/app_theme.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);
    final student = provider.currentStudent;
    if (student == null) return const SizedBox.shrink();

    final dues = CampusTools.checkDues(student.id);
    final payments = CampusTools.getPaymentSummary(student.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Financial Overview', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dues Breakdown Pie Chart
            Text('Dues Breakdown', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('Current outstanding balances by category', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            Container(
              height: 240,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: dues.hasDues
                  ? PieChart(PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 45,
                      sections: _buildDueSections(dues),
                    ))
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 48),
                          const SizedBox(height: 10),
                          Text('No Outstanding Dues! 🎉', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.success)),
                        ],
                      ),
                    ),
            ),

            // Legend
            if (dues.hasDues) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (dues.libraryFine > 0) _legendItem('Library', AppColors.error, '₹${dues.libraryFine.toStringAsFixed(0)}'),
                  if (dues.hostelDues > 0) _legendItem('Hostel', AppColors.accentIndigo, '₹${dues.hostelDues.toStringAsFixed(0)}'),
                  if (dues.labFees > 0) _legendItem('Lab', AppColors.accentTeal, '₹${dues.labFees.toStringAsFixed(0)}'),
                  if (dues.tuitionBalance > 0) _legendItem('Tuition', AppColors.warning, '₹${dues.tuitionBalance.toStringAsFixed(0)}'),
                  if (dues.messDues > 0) _legendItem('Mess', AppColors.accentViolet, '₹${dues.messDues.toStringAsFixed(0)}'),
                ],
              ),
            ],

            const SizedBox(height: 30),

            // Payment History Line Chart
            Text('Payment History', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('Recent transactions over time', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: payments.paymentHistory.isEmpty
                  ? Center(child: Text('No payment records yet', style: GoogleFonts.inter(color: AppColors.textMuted)))
                  : LineChart(LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 20000,
                        getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 0.5),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, _) => Text(
                              '₹${(value / 1000).toStringAsFixed(0)}k',
                              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _buildPaymentSpots(payments),
                          isCurved: true,
                          color: AppColors.accentTeal,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.accentTeal,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.accentTeal.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    )),
            ),

            const SizedBox(height: 20),

            // Summary footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem('Total Paid', '₹${(payments.tuitionPaid + payments.hostelPaid).toStringAsFixed(0)}'),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _summaryItem('Outstanding', '₹${payments.totalOutstanding.toStringAsFixed(0)}'),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _summaryItem('Transactions', '${payments.paymentHistory.length}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildDueSections(DuesRecord dues) {
    final total = dues.totalOutstanding;
    final sections = <PieChartSectionData>[];

    void addSection(double value, Color color, String label) {
      if (value > 0) {
        sections.add(PieChartSectionData(
          value: value,
          color: color,
          title: '${(value / total * 100).toStringAsFixed(0)}%',
          titleStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
          radius: 55,
        ));
      }
    }

    addSection(dues.libraryFine, AppColors.error, 'Library');
    addSection(dues.hostelDues, AppColors.accentIndigo, 'Hostel');
    addSection(dues.labFees, AppColors.accentTeal, 'Lab');
    addSection(dues.tuitionBalance, AppColors.warning, 'Tuition');
    addSection(dues.messDues, AppColors.accentViolet, 'Mess');

    return sections;
  }

  List<FlSpot> _buildPaymentSpots(PaymentSummary payments) {
    final history = payments.paymentHistory as List;
    return List.generate(history.length, (i) => FlSpot(i.toDouble(), history[i].amount));
  }

  Widget _legendItem(String label, Color color, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text('$label $value', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}
