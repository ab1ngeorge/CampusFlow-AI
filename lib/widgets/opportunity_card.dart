import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class OpportunityCardList extends StatelessWidget {
  final List<Opportunity> opportunities;

  const OpportunityCardList({super.key, required this.opportunities});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: opportunities
          .map((opp) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OpportunityCard(opportunity: opp),
              ))
          .toList(),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final Opportunity opportunity;

  const _OpportunityCard({required this.opportunity});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final daysLeft = opportunity.deadline.difference(DateTime.now()).inDays;

    return Container(
      decoration: GlassDecoration.card(opacity: 0.06, borderRadius: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(opportunity.typeEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  opportunity.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentTeal.withValues(alpha: 0.2),
                      AppColors.accentIndigo.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${opportunity.matchScore}% match',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            opportunity.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.school_rounded, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  opportunity.eligibility,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 13,
                color: opportunity.isUrgent ? AppColors.warning : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Deadline: ${dateFormat.format(opportunity.deadline)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: opportunity.isUrgent ? FontWeight.w700 : FontWeight.w400,
                  color: opportunity.isUrgent ? AppColors.warning : AppColors.textMuted,
                ),
              ),
              if (opportunity.isUrgent) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '⚠️ $daysLeft days left',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (opportunity.applyUrl != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Apply Now →',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
