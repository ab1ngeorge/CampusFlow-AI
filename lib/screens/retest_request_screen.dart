import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../services/mock_data.dart';
import '../services/notification_helper.dart';
import '../theme/app_theme.dart';

class RetestRequestScreen extends StatefulWidget {
  const RetestRequestScreen({super.key});

  @override
  State<RetestRequestScreen> createState() => _RetestRequestScreenState();
}

class _RetestRequestScreenState extends State<RetestRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.replay_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Retest Requests', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]))),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accentIndigo,
                labelColor: AppColors.accentIndigo,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(text: 'My Requests'),
                  Tab(text: 'New Request'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyRequests(),
          _buildNewRequestTab(),
        ],
      ),
    );
  }

  // ── Eligibility gate for new requests ───────────────────────
  Widget _buildNewRequestTab() {
    final provider = Provider.of<ChatProvider>(context);
    final student = provider.currentStudent;
    if (student == null) return const SizedBox.shrink();

    if (!student.isAcademicProfileComplete) {
      return _buildProfileBlockScreen(student);
    }
    return _buildNewRequestForm();
  }

  Widget _buildProfileBlockScreen(Student student) {
    final missing = student.missingAcademicFields;
    final percent = student.academicProfilePercent;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // Progress circle
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: percent / 100,
                      strokeWidth: 8,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(
                        percent >= 80 ? AppColors.warning : AppColors.error,
                      ),
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Icon(Icons.lock_rounded, size: 40, color: AppColors.warning),
            const SizedBox(height: 12),
            Text(
              'Profile Incomplete',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your academic profile before submitting requests.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),

            // Missing fields
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Missing Fields',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error),
                  ),
                  const SizedBox(height: 8),
                  ...missing.map((field) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 6, color: AppColors.error.withValues(alpha: 0.7)),
                        const SizedBox(width: 10),
                        Text(field, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Go to profile button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context), // return to main → profile tab
                icon: const Icon(Icons.person_rounded, color: Colors.white),
                label: Text('Update Profile', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 1: My Requests ──────────────────────────────────────
  Widget _buildMyRequests() {
    final provider = Provider.of<ChatProvider>(context);
    final studentId = provider.currentStudent?.id ?? '';
    final myRequests = MockData.retestRequests
        .where((r) => r.studentId == studentId)
        .toList()
      ..sort((a, b) => b.requestDate.compareTo(a.requestDate));

    if (myRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No retest requests yet', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: Text('Submit a Request →', style: GoogleFonts.inter(color: AppColors.accentIndigo, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myRequests.length,
      itemBuilder: (context, index) => _buildRequestCard(myRequests[index]),
    );
  }

  Widget _buildRequestCard(RetestRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                    color: _statusColor(req.finalStatus).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.replay_rounded, color: _statusColor(req.finalStatus), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req.subject, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                      Text('Exam: ${_formatDate(req.examDate)}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                _buildStatusChip(req.statusDisplay, req.finalStatus),
              ],
            ),
          ),

          // Approval progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildApprovalStepper(req),
          ),

          // Reason
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Reason: ${req.reason}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Retest date if approved
          if (req.finalStatus == 'approved' && req.retestDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded, color: AppColors.success, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Retest Date: ${_formatDate(req.retestDate!)}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.success)),
                          if (req.retestInstructions != null)
                            Text(req.retestInstructions!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildApprovalStepper(RetestRequest req) {
    return Row(
      children: [
        _stepCircle('Submitted', true, AppColors.accentIndigo),
        _stepLine(req.tutorStatus != 'pending'),
        _stepCircle('Tutor', req.tutorStatus == 'approved', req.tutorStatus == 'rejected' ? AppColors.error : AppColors.accentTeal),
        _stepLine(req.hodStatus != 'pending'),
        _stepCircle('HOD', req.hodStatus == 'approved', req.hodStatus == 'rejected' ? AppColors.error : AppColors.accentViolet),
        _stepLine(req.finalStatus == 'approved'),
        _stepCircle('Done', req.finalStatus == 'approved', AppColors.success),
      ],
    );
  }

  Widget _stepCircle(String label, bool active, Color color) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: active ? color : AppColors.background,
            border: Border.all(color: active ? color : AppColors.border, width: 2),
            shape: BoxShape.circle,
          ),
          child: active ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 9, color: active ? color : AppColors.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: active ? AppColors.success : AppColors.border,
      ),
    );
  }

  // ── Tab 2: New Request Form ─────────────────────────────────
  final _subjectController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime? _selectedExamDate;

  Widget _buildNewRequestForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentIndigo.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: AppColors.accentIndigo, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Submit a retest request. It will go to your Tutor first, then the HOD for final approval.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Subject
          Text('Subject Name *', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _subjectController,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. Data Structures',
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.book_rounded, color: AppColors.textMuted, size: 20),
              filled: true, fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 20),

          // Exam Date
          Text('Exam Date *', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 7)),
                firstDate: DateTime(2025),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _selectedExamDate = date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _selectedExamDate != null ? _formatDate(_selectedExamDate!) : 'Select exam date',
                    style: GoogleFonts.inter(
                      color: _selectedExamDate != null ? AppColors.textPrimary : AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Reason
          Text('Reason for Retest *', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Explain why you need a retest...',
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 20),

          // Document upload placeholder
          Text('Supporting Document (Optional)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload_rounded, color: AppColors.textMuted.withValues(alpha: 0.5), size: 36),
                const SizedBox(height: 8),
                Text('Tap to upload document', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
                Text('PDF, JPG, PNG (max 5MB)', style: GoogleFonts.inter(color: AppColors.textMuted.withValues(alpha: 0.6), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Submit button
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: AppColors.accentIndigo.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _submitRequest,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              label: Text('Submit Request', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitRequest() {
    if (_subjectController.text.isEmpty || _reasonController.text.isEmpty || _selectedExamDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppColors.error),
      );
      return;
    }

    final provider = Provider.of<ChatProvider>(context, listen: false);
    final student = provider.currentStudent!;
    final newReq = RetestRequest(
      requestId: 'RT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      studentId: student.id,
      studentName: student.name,
      department: student.department,
      subject: _subjectController.text.trim(),
      examDate: _selectedExamDate!,
      reason: _reasonController.text.trim(),
    );
    MockData.retestRequests.add(newReq);

    // ── Push live notification to the assigned tutor ──
    final tutor = MockData.findUserByRoleAndDept('tutor', student.department);
    if (tutor != null) {
      NotificationHelper.push(
        userId: tutor.id,
        type: 'retest_update',
        title: '📝 New Retest Request',
        message: 'Student ${student.name} has requested a retest for ${newReq.subject}.',
      );
    }

    _subjectController.clear();
    _reasonController.clear();
    setState(() => _selectedExamDate = null);
    _tabController.animateTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Retest request submitted! Your tutor will be notified.'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildStatusChip(String label, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor(status)),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return AppColors.success;
      case 'declined': return AppColors.error;
      case 'pending_hod': return AppColors.warning;
      default: return AppColors.accentIndigo;
    }
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
