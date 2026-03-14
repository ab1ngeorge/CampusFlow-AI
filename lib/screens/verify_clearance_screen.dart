import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../services/mock_data.dart';
import '../services/notification_helper.dart';
import '../services/supabase_config.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class VerifyClearanceScreen extends StatefulWidget {
  const VerifyClearanceScreen({super.key});

  @override
  State<VerifyClearanceScreen> createState() => _VerifyClearanceScreenState();
}

class _VerifyClearanceScreenState extends State<VerifyClearanceScreen> {
  String _filter = 'all'; // all, pending, approved, rejected
  List<ClearanceRequest> _requests = [];
  bool _isLoading = true;
  StreamSubscription<Map<String, dynamic>>? _clearanceSub;

  @override
  void initState() {
    super.initState();
    _loadRequests();

    if (SupabaseConfig.useSupabase) {
      _clearanceSub = SupabaseService.instance
          .subscribeToAllClearanceUpdates()
          .listen((event) {
        debugPrint('[VerifyClearance] Realtime change detected, reloading...');
        _loadRequests();
      });
    }
  }

  @override
  void dispose() {
    _clearanceSub?.cancel();
    SupabaseService.instance.unsubscribeGlobalClearance();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      if (SupabaseConfig.useSupabase) {
        _requests = await SupabaseService.instance.getAllClearanceRequestsForStaff();
      } else {
        _requests = List.from(MockData.clearanceRequests);
      }
    } catch (e) {
      debugPrint('[VerifyClearance] Failed to load from Supabase: $e');
      _requests = List.from(MockData.clearanceRequests);
    }
    if (mounted) setState(() => _isLoading = false);
  }
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);
    final user = provider.currentStudent;
    final role = user?.role ?? 'staff';

    // Map the user's role to the clearance department key:
    //   tutor / hod → 'tutor' (they approve the tutor_status column)
    //   staff       → staffDepartment lowercased (e.g. Library → library)
    //   admin       → sees all (no filtering by dept)
    final String deptKey;
    if (role == 'tutor' || role == 'hod') {
      deptKey = 'tutor';
    } else if (role == 'admin') {
      deptKey = 'all';
    } else {
      deptKey = (user?.staffDepartment ?? 'library').toLowerCase();
    }

    final filtered = _filter == 'all'
        ? _requests
        : _requests.where((r) {
            final status = r.departmentStatuses[deptKey] ?? r.overallStatus;
            return status == _filter;
          }).toList();

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
                gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0891B2)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Verify Clearance', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0891B2)]),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Filter chips ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: ['all', 'pending', 'approved', 'rejected'].map((f) {
                final isActive = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      f[0].toUpperCase() + f.substring(1),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                    selected: isActive,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.accentTeal,
                    backgroundColor: AppColors.surfaceLight,
                    side: BorderSide(color: isActive ? AppColors.accentTeal : AppColors.border),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Requests list ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentTeal))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 64, color: AppColors.success.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text('No requests', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRequests,
                        color: AppColors.accentTeal,
                        child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _buildRequestCard(filtered[index], deptKey),
                          ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(ClearanceRequest req, String deptKey) {
    final deptStatus = req.departmentStatuses[deptKey] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor(deptStatus).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.description_rounded, color: _statusColor(deptStatus), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.clearanceTypeDisplay,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Student: ${req.studentId}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(deptStatus),
              ],
            ),
          ),

          // Dept statuses overview
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: req.departmentStatuses.entries.map((e) {
                return Column(
                  children: [
                    Icon(
                      e.value == 'approved'
                          ? Icons.check_circle_rounded
                          : e.value == 'rejected'
                              ? Icons.cancel_rounded
                              : Icons.hourglass_top_rounded,
                      color: _statusColor(e.value),
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.key[0].toUpperCase() + e.key.substring(1),
                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Action buttons (only if pending for this dept)
          if (deptStatus == 'pending')
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(req, deptKey, 'rejected'),
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                      label: Text('Reject', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0891B2)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentTeal.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(req, deptKey, 'approved'),
                        icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                        label: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _updateStatus(ClearanceRequest req, String deptKey, String newStatus) async {
    setState(() {
      req.departmentStatuses[deptKey] = newStatus;
      // Check if all depts are approved
      final allApproved = req.departmentStatuses.values.every((s) => s == 'approved');
      final anyRejected = req.departmentStatuses.values.any((s) => s == 'rejected');
      if (allApproved) {
        req.overallStatus = 'approved';
      } else if (anyRejected) {
        req.overallStatus = 'on_hold';
      } else {
        req.overallStatus = 'in_progress';
      }
    });

    // ── Persist to Supabase ──
    if (SupabaseConfig.useSupabase) {
      try {
        await SupabaseService.instance.updateClearanceRequestStatus(
          requestId: req.requestId,
          deptKey: deptKey,
          newStatus: newStatus,
          overallStatus: req.overallStatus,
        );
      } catch (e) {
        debugPrint('[VerifyClearance] Supabase update failed: $e');
      }
    }

    // ── Push notification to the student ──
    final deptLabel = deptKey[0].toUpperCase() + deptKey.substring(1);
    if (newStatus == 'approved') {
      NotificationHelper.push(
        userId: req.studentId,
        type: 'clearance_update',
        title: '✅ $deptLabel Clearance Approved',
        message: 'Your ${req.clearanceTypeDisplay} request has been approved by the $deptLabel department.',
      );
    } else {
      NotificationHelper.push(
        userId: req.studentId,
        type: 'clearance_update',
        title: '❌ $deptLabel Clearance Rejected',
        message: 'Your ${req.clearanceTypeDisplay} request has been rejected by the $deptLabel department.',
      );
    }

    // Full clearance achieved
    if (req.overallStatus == 'approved') {
      NotificationHelper.push(
        userId: req.studentId,
        type: 'clearance_update',
        title: '🎉 Full Clearance Approved!',
        message: 'All departments have approved your ${req.clearanceTypeDisplay}. You can now collect your certificate.',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'approved'
                ? '✅ Clearance approved for ${req.studentId}'
                : '❌ Clearance rejected for ${req.studentId}',
          ),
          backgroundColor: newStatus == 'approved' ? AppColors.success : AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _statusColor(status),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      case 'in_progress': return AppColors.warning;
      default: return AppColors.accentIndigo;
    }
  }
}
