import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../services/mock_data.dart';
import '../services/notification_helper.dart';
import '../theme/app_theme.dart';

class PostScholarshipScreen extends StatefulWidget {
  const PostScholarshipScreen({super.key});

  @override
  State<PostScholarshipScreen> createState() => _PostScholarshipScreenState();
}

class _PostScholarshipScreenState extends State<PostScholarshipScreen>
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
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Scholarship Management', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.warning,
          labelColor: AppColors.warning,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'All Scholarships'),
            Tab(text: 'Add New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScholarshipList(),
          _buildAddScholarshipForm(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  TAB 1 — Scholarship List
  // ══════════════════════════════════════════════════════════════
  Widget _buildScholarshipList() {
    final list = MockData.scholarships;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No scholarships yet', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Tap "Add New" to create one', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildScholarshipCard(list[index]),
    );
  }

  Widget _buildScholarshipCard(Scholarship s) {
    final isExpired = s.isExpired;
    final accentColor = s.type == 'egrant' ? AppColors.accentTeal : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpired ? AppColors.error.withValues(alpha: 0.3) : AppColors.border),
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
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(s.typeEmoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                      Text('${s.provider} • ${s.typeLabel}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isExpired ? AppColors.error : AppColors.success).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isExpired ? 'Expired' : '${s.daysLeft}d left',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: isExpired ? AppColors.error : AppColors.success),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  if (s.eligibleCourse != null) _infoRow(Icons.school_rounded, 'Course', s.eligibleCourse!),
                  if (s.eligibleCategory != null) ...[const SizedBox(height: 4), _infoRow(Icons.group_rounded, 'Category', s.eligibleCategory!)],
                  if (s.incomeLimit != null) ...[const SizedBox(height: 4), _infoRow(Icons.currency_rupee_rounded, 'Income Limit', '₹${s.incomeLimit!.toStringAsFixed(0)}')],
                  if (s.minMarksPercent != null) ...[const SizedBox(height: 4), _infoRow(Icons.trending_up_rounded, 'Min Marks', '${s.minMarksPercent}%')],
                  const SizedBox(height: 4),
                  _infoRow(Icons.calendar_today_rounded, 'Deadline', _formatDate(s.deadline)),
                ],
              ),
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(s.description, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
          ),

          // Eligible students count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Builder(
              builder: (_) {
                final eligible = _countEligibleStudents(s);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentIndigo.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.smart_toy_rounded, color: AppColors.accentIndigo, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'AI Match: $eligible student${eligible != 1 ? 's' : ''} eligible',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentIndigo),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _countEligibleStudents(Scholarship s) {
    return MockData.students.values
        .where((stu) => stu.role == 'student' && s.isStudentEligible(stu))
        .length;
  }

  // ══════════════════════════════════════════════════════════════
  //  TAB 2 — Add New Scholarship Form
  // ══════════════════════════════════════════════════════════════
  final _formKey = GlobalKey<FormState>();
  String _type = 'scholarship';
  final _nameCtrl = TextEditingController();
  String _provider = 'Government';
  final _descCtrl = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  final _courseCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  int _eligibleYear = 0; // 0 = all
  String _category = 'All';
  String _gender = 'All';
  final _incomeLimitCtrl = TextEditingController();
  final _minMarksCtrl = TextEditingController();
  final _docsCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _processCtrl = TextEditingController();
  bool _requiresIncomeCert = false;

  Widget _buildAddScholarshipForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section: Basic Details ──
            _sectionHeader('📋 Basic Details'),
            const SizedBox(height: 12),

            // Type toggle
            Row(
              children: [
                _typeChip('Scholarship', 'scholarship'),
                const SizedBox(width: 10),
                _typeChip('e-Grant', 'egrant'),
              ],
            ),
            const SizedBox(height: 14),

            _buildField(_nameCtrl, 'Scholarship / Grant Name', Icons.edit_rounded, required: true),
            const SizedBox(height: 12),

            // Provider dropdown
            DropdownButtonFormField<String>(
              initialValue: _provider,
              dropdownColor: AppColors.surface,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
              decoration: _inputDecoration('Provider', Icons.business_rounded),
              items: ['Government', 'Private', 'University'].map((p) =>
                DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => setState(() => _provider = v!),
            ),
            const SizedBox(height: 12),

            _buildField(_descCtrl, 'Description', Icons.description_rounded, maxLines: 3, required: true),
            const SizedBox(height: 12),

            // Deadline picker
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 12),
                    Text('Deadline: ${_formatDate(_deadline)}', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Section: Eligibility Criteria ──
            _sectionHeader('🎯 Eligibility Criteria'),
            const SizedBox(height: 12),

            _buildField(_courseCtrl, 'Eligible Course (e.g. BTech)', Icons.school_rounded),
            const SizedBox(height: 12),
            _buildField(_deptCtrl, 'Eligible Department (optional)', Icons.account_tree_rounded),
            const SizedBox(height: 12),

            // Year dropdown
            DropdownButtonFormField<int>(
              initialValue: _eligibleYear,
              dropdownColor: AppColors.surface,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
              decoration: _inputDecoration('Year of Study', Icons.timeline_rounded),
              items: [
                const DropdownMenuItem(value: 0, child: Text('All Years')),
                ...List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text('Year ${i + 1}'))),
              ],
              onChanged: (v) => setState(() => _eligibleYear = v!),
            ),
            const SizedBox(height: 12),

            // Category
            DropdownButtonFormField<String>(
              initialValue: _category,
              dropdownColor: AppColors.surface,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
              decoration: _inputDecoration('Category', Icons.group_rounded),
              items: ['All', 'SC', 'ST', 'OBC', 'General', 'Minority'].map((c) =>
                DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),

            // Gender
            DropdownButtonFormField<String>(
              initialValue: _gender,
              dropdownColor: AppColors.surface,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
              decoration: _inputDecoration('Gender', Icons.wc_rounded),
              items: ['All', 'Male', 'Female'].map((g) =>
                DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _gender = v!),
            ),
            const SizedBox(height: 12),

            _buildField(_incomeLimitCtrl, 'Annual Income Limit (₹)', Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _buildField(_minMarksCtrl, 'Minimum Marks %', Icons.trending_up_rounded, keyboardType: TextInputType.number),
            const SizedBox(height: 12),

            // Income certificate toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Requires Income Certificate', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)),
                  ),
                  Switch(
                    value: _requiresIncomeCert,
                    activeThumbColor: AppColors.warning,
                    onChanged: (v) => setState(() => _requiresIncomeCert = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Section: Application ──
            _sectionHeader('📎 Application Details'),
            const SizedBox(height: 12),
            _buildField(_docsCtrl, 'Required Documents', Icons.file_copy_rounded, maxLines: 2),
            const SizedBox(height: 12),
            _buildField(_urlCtrl, 'Application Link (URL)', Icons.link_rounded),
            const SizedBox(height: 12),
            _buildField(_processCtrl, 'Application Process', Icons.list_alt_rounded, maxLines: 3),
            const SizedBox(height: 32),

            // Submit
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.warning.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: ElevatedButton.icon(
                onPressed: _submitScholarship,
                icon: const Icon(Icons.publish_rounded, color: Colors.white),
                label: Text('Publish & Notify Students', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Submit & AI notify ──────────────────────────────────────
  void _submitScholarship() {
    if (_nameCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in name and description'), backgroundColor: AppColors.error),
      );
      return;
    }

    final provider = Provider.of<ChatProvider>(context, listen: false);
    final officerName = provider.currentStudent?.name ?? 'Officer';

    final scholarship = Scholarship(
      id: 'SCH-${DateTime.now().millisecondsSinceEpoch}',
      type: _type,
      name: _nameCtrl.text.trim(),
      provider: _provider,
      description: _descCtrl.text.trim(),
      deadline: _deadline,
      eligibleCourse: _courseCtrl.text.trim().isNotEmpty ? _courseCtrl.text.trim() : null,
      eligibleDepartment: _deptCtrl.text.trim().isNotEmpty ? _deptCtrl.text.trim() : null,
      eligibleYear: _eligibleYear > 0 ? _eligibleYear : null,
      eligibleCategory: _category,
      eligibleGender: _gender,
      incomeLimit: _incomeLimitCtrl.text.isNotEmpty ? double.tryParse(_incomeLimitCtrl.text) : null,
      minMarksPercent: _minMarksCtrl.text.isNotEmpty ? double.tryParse(_minMarksCtrl.text) : null,
      requiresIncomeCertificate: _requiresIncomeCert,
      requiredDocuments: _docsCtrl.text.trim().isNotEmpty ? _docsCtrl.text.trim() : null,
      applyUrl: _urlCtrl.text.trim().isNotEmpty ? _urlCtrl.text.trim() : null,
      applicationProcess: _processCtrl.text.trim().isNotEmpty ? _processCtrl.text.trim() : null,
      postedBy: officerName,
    );

    // Add to mock data
    MockData.scholarships.add(scholarship);

    // ── AI eligibility matching → notify eligible students ──
    int notified = 0;
    final allStudents = MockData.students.values.where((s) => s.role == 'student');
    for (final student in allStudents) {
      if (scholarship.isStudentEligible(student)) {
        NotificationHelper.push(
          userId: student.id,
          type: 'opportunity',
          title: '${scholarship.typeEmoji} New ${scholarship.typeLabel}: ${scholarship.name}',
          message: 'You may be eligible for ${scholarship.name} by ${scholarship.provider}. Deadline: ${_formatDate(scholarship.deadline)}. Tap to view details and apply.',
        );
        notified++;
      }
    }

    // Clear form
    _nameCtrl.clear();
    _descCtrl.clear();
    _courseCtrl.clear();
    _deptCtrl.clear();
    _incomeLimitCtrl.clear();
    _minMarksCtrl.clear();
    _docsCtrl.clear();
    _urlCtrl.clear();
    _processCtrl.clear();
    setState(() {
      _type = 'scholarship';
      _provider = 'Government';
      _eligibleYear = 0;
      _category = 'All';
      _gender = 'All';
      _requiresIncomeCert = false;
      _deadline = DateTime.now().add(const Duration(days: 30));
    });

    _tabController.animateTo(0); // switch to list tab

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Published! $notified eligible student${notified != 1 ? "s" : ""} notified.'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary));
  }

  Widget _typeChip(String label, String value) {
    final isActive = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.warning.withValues(alpha: 0.15) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppColors.warning : AppColors.border),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? AppColors.warning : AppColors.textMuted)),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, bool required = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.warning, width: 1.5)),
    );
  }

  void _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.warning, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
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

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
