import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ManageIssuesScreen extends StatefulWidget {
  const ManageIssuesScreen({super.key});

  @override
  State<ManageIssuesScreen> createState() => _ManageIssuesScreenState();
}

class _ManageIssuesScreenState extends State<ManageIssuesScreen> {
  // Mock issues for demo
  final List<IssueTicket> _issues = [
    IssueTicket(
      ticketId: 'ISS-001',
      studentId: 'STU-001001',
      category: 'hostel',
      description: 'Electricity not working in Room 204, Block C since yesterday evening.',
      location: 'Hostel Block C, Room 204',
      status: 'logged',
      assignedTo: 'Hostel Administration',
      submittedAt: DateTime(2026, 3, 13, 18, 0),
    ),
    IssueTicket(
      ticketId: 'ISS-002',
      studentId: 'STU-001002',
      category: 'infrastructure',
      description: 'Broken window in Lab 301. Glass shards on the floor, safety hazard.',
      location: 'ECE Lab 301',
      status: 'in_progress',
      assignedTo: 'Estate & Maintenance',
      submittedAt: DateTime(2026, 3, 12, 10, 0),
    ),
    IssueTicket(
      ticketId: 'ISS-003',
      studentId: 'STU-001003',
      category: 'internet',
      description: 'WiFi not connecting in MBA block since morning. Multiple students affected.',
      location: 'MBA Block, Ground Floor',
      status: 'logged',
      assignedTo: 'IT Department',
      submittedAt: DateTime(2026, 3, 14, 8, 0),
    ),
    IssueTicket(
      ticketId: 'ISS-004',
      studentId: 'STU-001001',
      category: 'cleanliness',
      description: 'Washroom in 2nd floor of CS block needs cleaning urgently.',
      location: 'CS Block, 2nd Floor',
      status: 'resolved',
      assignedTo: 'Housekeeping Department',
      submittedAt: DateTime(2026, 3, 11, 14, 0),
    ),
  ];

  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'all'
        ? _issues
        : _issues.where((i) => i.status == _filter).toList();

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
                gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bug_report_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Manage Issues', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
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
              children: ['all', 'logged', 'in_progress', 'resolved'].map((f) {
                final isActive = _filter == f;
                final label = f == 'in_progress' ? 'In Progress' : f[0].toUpperCase() + f.substring(1);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                    selected: isActive,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.error,
                    backgroundColor: AppColors.surfaceLight,
                    side: BorderSide(color: isActive ? AppColors.error : AppColors.border),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Issues list ──
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 64, color: AppColors.success.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text('No issues found', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildIssueCard(filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(IssueTicket issue) {
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _categoryColor(issue.category).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_categoryIcon(issue.category), color: _categoryColor(issue.category), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${issue.ticketId} • ${issue.category[0].toUpperCase()}${issue.category.substring(1)}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      Text(
                        'By ${issue.studentId} • ${issue.assignedTo}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(issue.status),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              issue.description,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Location
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(issue.location, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),

          // Actions
          if (issue.status != 'resolved')
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (issue.status == 'logged')
                    Expanded(
                      child: _buildActionButton(
                        'Mark In Progress',
                        Icons.play_arrow_rounded,
                        AppColors.warning,
                        () => _updateIssueStatus(issue, 'in_progress'),
                      ),
                    ),
                  if (issue.status == 'logged') const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF16A34A)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _updateIssueStatus(issue, 'resolved'),
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        label: const Text('Resolve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Text('Resolved', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _updateIssueStatus(IssueTicket issue, String newStatus) {
    setState(() {
      // Since IssueTicket fields are final, we replace the item
      final index = _issues.indexWhere((i) => i.ticketId == issue.ticketId);
      if (index != -1) {
        _issues[index] = IssueTicket(
          ticketId: issue.ticketId,
          studentId: issue.studentId,
          category: issue.category,
          description: issue.description,
          location: issue.location,
          photoUrl: issue.photoUrl,
          status: newStatus,
          assignedTo: issue.assignedTo,
          submittedAt: issue.submittedAt,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == 'resolved'
              ? '✅ Issue #${issue.ticketId} resolved'
              : '🔄 Issue #${issue.ticketId} marked as in progress',
        ),
        backgroundColor: newStatus == 'resolved' ? AppColors.success : AppColors.warning,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final label = status == 'in_progress' ? 'In Progress' : status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _issueStatusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _issueStatusColor(status)),
      ),
    );
  }

  Color _issueStatusColor(String status) {
    switch (status) {
      case 'resolved': return AppColors.success;
      case 'in_progress': return AppColors.warning;
      default: return AppColors.accentIndigo;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'hostel': return AppColors.warning;
      case 'infrastructure': return AppColors.error;
      case 'internet': return AppColors.accentIndigo;
      case 'cleanliness': return AppColors.accentTeal;
      case 'safety': return AppColors.error;
      default: return AppColors.textMuted;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'hostel': return Icons.apartment_rounded;
      case 'infrastructure': return Icons.engineering_rounded;
      case 'internet': return Icons.wifi_off_rounded;
      case 'cleanliness': return Icons.cleaning_services_rounded;
      case 'safety': return Icons.security_rounded;
      default: return Icons.report_problem_rounded;
    }
  }
}
