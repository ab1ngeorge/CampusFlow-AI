import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class PaymentSummaryCard extends StatelessWidget {
  final PaymentSummary summary;

  const PaymentSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      decoration: GlassDecoration.card(opacity: 0.06, borderRadius: 18),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: AppColors.accentTeal, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Payment Summary',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tuition
          _sectionRow('Tuition', 
            'Paid: ${currencyFormat.format(summary.tuitionPaid)}',
            'Balance: ${currencyFormat.format(summary.tuitionBalance)}',
            summary.tuitionNextDue != null ? 'Next due: ${dateFormat.format(summary.tuitionNextDue!)}' : null,
            summary.tuitionBalance,
          ),
          const SizedBox(height: 12),

          // Hostel
          _sectionRow('Hostel', 
            'Paid: ${currencyFormat.format(summary.hostelPaid)}',
            'Balance: ${currencyFormat.format(summary.hostelBalance)}',
            summary.hostelNextDue != null ? 'Next due: ${dateFormat.format(summary.hostelNextDue!)}' : null,
            summary.hostelBalance,
          ),
          const SizedBox(height: 12),

          // Other
          Row(
            children: [
              Expanded(child: _smallCard('Library Fines', currencyFormat.format(summary.libraryFines), summary.libraryFines)),
              const SizedBox(width: 10),
              Expanded(child: _smallCard('Lab Fees', currencyFormat.format(summary.labFees), summary.labFees)),
            ],
          ),

          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Outstanding',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: summary.totalOutstanding > 0
                      ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)])
                      : const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF22C55E)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currencyFormat.format(summary.totalOutstanding),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // Payment history section
          if (summary.paymentHistory.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Recent Payments',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            ...summary.paymentHistory.take(3).map((record) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 16, color: AppColors.success.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.type,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    currencyFormat.format(record.amount),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(record.date),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _sectionRow(String title, String paid, String balance, String? nextDue, double balanceAmount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  paid,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.success),
                ),
              ),
              Text(
                balance,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: balanceAmount > 0 ? AppColors.warning : AppColors.success,
                ),
              ),
            ],
          ),
          if (nextDue != null) ...[
            const SizedBox(height: 4),
            Text(
              nextDue,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _smallCard(String title, String amount, double value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: value > 0 ? AppColors.warning : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
