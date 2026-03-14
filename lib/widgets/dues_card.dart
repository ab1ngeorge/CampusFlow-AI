import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class DuesCard extends StatelessWidget {
  final DuesRecord dues;

  const DuesCard({super.key, required this.dues});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

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
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Outstanding Dues',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _dueRow('Library Fine', dues.libraryFine, currencyFormat),
          _dueRow('Hostel Dues', dues.hostelDues, currencyFormat),
          _dueRow('Lab Fees', dues.labFees, currencyFormat),
          _dueRow('Tuition Balance', dues.tuitionBalance, currencyFormat),
          _dueRow('Mess Dues', dues.messDues, currencyFormat),

          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

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
                  gradient: dues.hasDues
                      ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)])
                      : const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF22C55E)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currencyFormat.format(dues.totalOutstanding),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dueRow(String label, double amount, NumberFormat format) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                amount > 0 ? Icons.circle : Icons.check_circle_rounded,
                size: 10,
                color: amount > 0 ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            format.format(amount),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: amount > 0 ? AppColors.warning : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
