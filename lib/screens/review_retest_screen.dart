import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../services/mock_data.dart';
import '../services/notification_helper.dart';
import '../theme/app_theme.dart';

/// Shared screen for Tutor and HOD to review retest requests.
/// Tutors see requests pending their approval.
/// HODs see requests that tutors have already approved.
class ReviewRetestScreen extends StatefulWidget {
  const ReviewRetestScreen({super.key});

  @override
  State<ReviewRetestScreen> createState() => _ReviewRetestScreenState();
}

class _ReviewRetestScreenState extends State<ReviewRetestScreen> {
  String _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);
    final user = provider.currentStudent;
    if (user == null) return const SizedBox.shrink();

    final isHod = user.userRole == UserRole.hod;
    final isTutor = user.userRole == UserRole.tutor;
    final userDept = user.staffDepartment ?? user.department;

    // Filter requests by role and department
    final allRequests = MockData.retestRequests.where((r) {
      if (r.department != userDept) return false;
      if (isTutor) return true; // tutors see all requests
      if (isHod) return r.tutorStatus == 'approved' || r.hodStatus != 'pending'; // HOD sees tutor-approved
      return true;
    }).toList();

    final filtered = _filter == 'all'
        ? allRequests
        : allRequests.where((r) {
            if (_filter == 'pending') {
              if (isTutor) return r.tutorStatus == 'pending';
              if (isHod) return r.hodStatus == 'pending' && r.tutorStatus == 'approved';
            }
            if (_filter == 'approved') {
              if (isTutor) return r.tutorStatus == 'approved';
              if (isHod) return r.hodStatus == 'approved';
            }
            if (_filter == 'rejected') {
              if (isTutor) return r.tutorStatus == 'rejected';
              if (isHod) return r.hodStatus == 'rejected';
            }
            return true;
          }).toList()
      ..sort((a, b) => b.requestDate.compareTo(a.requestDate));

    final roleLabel = isHod ? 'HOD' : 'Tutor';
    final accentColor = isHod ? AppColors.accentViolet : AppColors.accentTeal;

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
                gradient: LinearGradient(colors: isHod
                    ? [const Color(0xFF7C3AED), const Color(0xFFA855F7)]
                    : [const Color(0xFF0D9488), const Color(0xFF0891B2)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.rate_review_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Retest Approvals', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(roleLabel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: accentColor)),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: isHod
                  ? [const Color(0xFF7C3AED), const Color(0xFFA855F7)]
                  : [const Color(0xFF0D9488), const Color(0xFF0891B2)]),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: ['pending', 'approved', 'rejected', 'all'].map((f) {
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
                    selectedColor: accentColor,
                    backgroundColor: AppColors.surfaceLight,
                    side: BorderSide(color: isActive ? accentColor : AppColors.border),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          // Requests
          Expanded(
            child: filtered.isEmpty
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
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildRequestCard(filtered[index], isTutor, isHod, accentColor),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(RetestRequest req, bool isTutor, bool isHod, Color accentColor) {
    final showActions = (isTutor && req.tutorStatus == 'pending') ||
        (isHod && req.hodStatus == 'pending' && req.tutorStatus == 'approved');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Student avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      req.studentName[0],
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: accentColor),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req.studentName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                      Text('${req.studentId} • ${req.department}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                _buildStatusBadge(req, isTutor),
              ],
            ),
          ),

          // Subject & Exam info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.book_rounded, 'Subject', req.subject),
                  const SizedBox(height: 6),
                  _infoRow(Icons.calendar_today_rounded, 'Exam Date', _formatDate(req.examDate)),
                  const SizedBox(height: 6),
                  _infoRow(Icons.access_time_rounded, 'Requested', _formatDate(req.requestDate)),
                  if (req.documentUrl != null) ...[
                    const SizedBox(height: 6),
                    _infoRow(Icons.attach_file_rounded, 'Document', req.documentUrl!),
                  ],
                ],
              ),
            ),
          ),

          // Reason
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reason', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(req.reason, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),

          // Tutor remarks (visible to HOD)
          if (isHod && req.tutorRemarks != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.comment_rounded, color: AppColors.accentTeal, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tutor Remarks', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accentTeal)),
                          Text(req.tutorRemarks!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Action buttons
          if (showActions)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDecisionDialog(req, isTutor, false),
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
                        gradient: LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.8)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _showDecisionDialog(req, isTutor, true),
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

  void _showDecisionDialog(RetestRequest req, bool isTutor, bool isApproval) {
    final remarksController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isApproval ? 'Approve Request' : 'Reject Request',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isApproval ? "Approve" : "Reject"} retest request for ${req.subject} by ${req.studentName}?',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              maxLines: 3,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Add remarks (optional)',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                filled: true, fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processDecision(req, isTutor, isApproval, remarksController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? AppColors.success : AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isApproval ? 'Approve' : 'Reject', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _processDecision(RetestRequest req, bool isTutor, bool isApproval, String remarks) {
    setState(() {
      if (isTutor) {
        req.tutorStatus = isApproval ? 'approved' : 'rejected';
        req.tutorRemarks = remarks.isNotEmpty ? remarks : null;
        if (isApproval) {
          req.finalStatus = 'pending_hod';
          // Notify HOD
          final hod = MockData.findUserByRoleAndDept('hod', req.department);
          if (hod != null) {
            NotificationHelper.push(
              userId: hod.id,
              type: 'retest_update',
              title: '📋 Retest Awaiting Your Approval',
              message: 'A retest request for ${req.subject} by ${req.studentName} has been approved by the Tutor and needs your review.',
            );
          }
          // Notify student
          NotificationHelper.push(
            userId: req.studentId,
            type: 'retest_update',
            title: '✅ Tutor Approved Your Retest',
            message: 'Your retest request for ${req.subject} has been approved by your Tutor. Awaiting HOD approval.',
          );
        } else {
          req.finalStatus = 'declined';
          // Notify student of rejection
          NotificationHelper.push(
            userId: req.studentId,
            type: 'retest_update',
            title: '❌ Retest Request Declined',
            message: 'Your retest request for ${req.subject} has been declined by your Tutor.${remarks.isNotEmpty ? " Reason: $remarks" : ""}',
          );
        }
      } else {
        // HOD
        req.hodStatus = isApproval ? 'approved' : 'rejected';
        req.hodRemarks = remarks.isNotEmpty ? remarks : null;
        if (isApproval) {
          req.finalStatus = 'approved';
          req.retestDate = DateTime.now().add(const Duration(days: 14));
          req.retestInstructions = 'Report to Exam Hall at 10:00 AM. Carry your ID card.';
          // Notify student of final approval
          NotificationHelper.push(
            userId: req.studentId,
            type: 'retest_update',
            title: '🎉 Retest Approved!',
            message: 'Your retest request for ${req.subject} has been approved by the HOD. Check your requests for the retest date and instructions.',
          );
        } else {
          req.finalStatus = 'declined';
          // Notify student of HOD rejection
          NotificationHelper.push(
            userId: req.studentId,
            type: 'retest_update',
            title: '❌ Retest Rejected by HOD',
            message: 'Your retest request for ${req.subject} has been rejected by the HOD.${remarks.isNotEmpty ? " Reason: $remarks" : ""}',
          );
        }
      }
    });

    final action = isApproval ? 'approved' : 'rejected';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${isApproval ? "✅" : "❌"} Retest request $action for ${req.studentName}'),
        backgroundColor: isApproval ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary))),
      ],
    );
  }

  Widget _buildStatusBadge(RetestRequest req, bool isTutor) {
    final status = isTutor ? req.tutorStatus : req.hodStatus;
    final color = status == 'approved' ? AppColors.success
        : status == 'rejected' ? AppColors.error
        : AppColors.warning;
    final label = status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
