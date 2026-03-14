import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../services/campus_tools.dart';
import '../theme/app_theme.dart';

class ClearanceScreen extends StatefulWidget {
  const ClearanceScreen({super.key});

  @override
  State<ClearanceScreen> createState() => _ClearanceScreenState();
}

class _ClearanceScreenState extends State<ClearanceScreen>
    with SingleTickerProviderStateMixin {
  ClearanceRequest? _latestRequest;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadClearance();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadClearance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      final student = provider.currentStudent;
      if (student == null) return;

      final request = await CampusTools.getClearanceStatusAsync(student.id, null);
      if (mounted) {
        setState(() {
          _latestRequest = request;
          _isLoading = false;
        });
        _animController.reset();
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load clearance data. Pull down to retry.';
        });
      }
    }
  }

  Future<void> _requestClearance(String type) async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final student = provider.currentStudent;
    if (student == null) return;

    setState(() => _isSubmitting = true);
    try {
      final request = await CampusTools.submitClearanceRequestAsync(student.id, type);
      if (mounted) {
        setState(() {
          _latestRequest = request;
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              request.overallStatus == 'approved'
                  ? '✅ Auto-approved! All departments cleared.'
                  : '📋 Request submitted. Some departments need action.',
              style: GoogleFonts.inter(),
            ),
            backgroundColor:
                request.overallStatus == 'approved' ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request', style: GoogleFonts.inter()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.assignment_rounded, color: AppColors.accentTeal, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Clearance', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: _loadClearance,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentTeal.withValues(alpha: 0.3),
                  AppColors.accentIndigo.withValues(alpha: 0.3),
                  AppColors.accentViolet.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, color: AppColors.textMuted, size: 56),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadClearance,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadClearance,
                  color: AppColors.accentTeal,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status Overview ──
                  if (_latestRequest != null) ...[
                    _buildOverallStatusCard(_latestRequest!),
                    const SizedBox(height: 20),
                    Text(
                      'Department Status',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._latestRequest!.departmentStatuses.entries.map(
                      (e) => _buildDeptRow(e.key, e.value),
                    ),
                    if (_latestRequest!.remarks != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _latestRequest!.remarks!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                  ] else ...[
                    _buildNoClearanceCard(),
                    const SizedBox(height: 28),
                  ],

                  // ── Request Clearance ──
                  Text(
                    'Request Clearance',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRequestButton('No Dues Certificate', 'no_dues_certificate', Icons.check_circle_outline_rounded),
                  _buildRequestButton('Bonafide Certificate', 'bonafide_certificate', Icons.verified_rounded),
                  _buildRequestButton('Transfer Certificate', 'transfer_certificate', Icons.swap_horiz_rounded),
                  _buildRequestButton('Course Completion', 'course_completion_certificate', Icons.school_rounded),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildOverallStatusCard(ClearanceRequest req) {
    final Color statusColor;
    final IconData statusIcon;
    switch (req.overallStatus) {
      case 'approved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'on_hold':
        statusColor = AppColors.warning;
        statusIcon = Icons.pause_circle_rounded;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppColors.info;
        statusIcon = Icons.hourglass_bottom_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.12), statusColor.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.clearanceTypeDisplay,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${req.overallStatus.toUpperCase().replaceAll('_', ' ')}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptRow(String dept, String status) {
    final Color color;
    final IconData icon;
    switch (status) {
      case 'approved':
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case 'on_hold':
        color = AppColors.warning;
        icon = Icons.error_rounded;
        break;
      case 'rejected':
        color = AppColors.error;
        icon = Icons.cancel_rounded;
        break;
      default:
        color = AppColors.textMuted;
        icon = Icons.hourglass_bottom_rounded;
    }

    final displayName = dept[0].toUpperCase() + dept.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              displayName,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.replaceAll('_', ' ').toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoClearanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            'No clearance requests yet',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create a request below to get started',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestButton(String label, String type, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isSubmitting ? null : () => _requestClearance(type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentIndigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.accentIndigo, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (_isSubmitting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentIndigo),
                  )
                else
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
