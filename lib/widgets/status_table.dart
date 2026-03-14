import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class StatusTable extends StatelessWidget {
  final ClearanceRequest request;

  const StatusTable({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.accentIndigo.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_rounded,
                    color: AppColors.accentIndigo, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.clearanceTypeDisplay,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      request.requestId,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(request.overallStatus),
            ],
          ),
          const SizedBox(height: 18),

          // Department statuses
          ...request.departmentStatuses.entries.map((entry) =>
            _departmentRow(entry.key, entry.value),
          ),

          if (request.estimatedCompletion != null) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  'Estimated completion: ${dateFormat.format(request.estimatedCompletion!)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],

          if (request.remarks != null && request.remarks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.remarks!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.info,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _departmentRow(String department, String status) {
    String displayName = department[0].toUpperCase() + department.substring(1);
    IconData icon;
    Color statusColor;
    String statusText;

    switch (status) {
      case 'approved':
        icon = Icons.check_circle_rounded;
        statusColor = AppColors.success;
        statusText = 'Approved';
        break;
      case 'rejected':
        icon = Icons.cancel_rounded;
        statusColor = AppColors.error;
        statusText = 'Rejected';
        break;
      case 'on_hold':
        icon = Icons.pause_circle_rounded;
        statusColor = AppColors.warning;
        statusText = 'On Hold';
        break;
      default:
        icon = Icons.hourglass_bottom_rounded;
        statusColor = AppColors.textMuted;
        statusText = 'Pending';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: statusColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayName,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'approved':
        color = AppColors.success;
        text = 'Approved';
        break;
      case 'rejected':
        color = AppColors.error;
        text = 'Rejected';
        break;
      case 'on_hold':
        color = AppColors.warning;
        text = 'On Hold';
        break;
      case 'submitted':
        color = AppColors.info;
        text = 'Submitted';
        break;
      default:
        color = AppColors.accentTeal;
        text = 'In Progress';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
