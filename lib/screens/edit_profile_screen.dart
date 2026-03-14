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

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _saving = false;

  // ── Academic ──
  late String _department;
  late String _course;
  late int _year;
  late int _semester;

  // ── Personal ──
  late TextEditingController _religionCtrl;
  late TextEditingController _casteCtrl;
  late String _category;
  late bool _minorityStatus;

  // ── Contact ──
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _postalCodeCtrl;

  // ── Hostel ──
  late bool _hostelResident;
  late TextEditingController _hostelNameCtrl;
  late TextEditingController _roomNumberCtrl;

  // ── Section expansion state ──
  final List<bool> _expanded = [true, false, false, false];

  @override
  void initState() {
    super.initState();
    final s = Provider.of<ChatProvider>(context, listen: false).currentStudent!;

    _department = s.department.isNotEmpty ? s.department : 'Computer Science';
    _course = s.course ?? 'BTech';
    _year = s.year > 0 ? s.year : 1;
    _semester = s.semester ?? 1;

    _religionCtrl = TextEditingController(text: s.religion ?? '');
    _casteCtrl = TextEditingController(text: s.caste ?? '');
    _category = s.category ?? 'General';
    _minorityStatus = s.minorityStatus ?? false;

    _phoneCtrl = TextEditingController(text: s.phone ?? '');
    _emailCtrl = TextEditingController(text: s.email ?? '');
    _addressCtrl = TextEditingController(text: s.address ?? '');
    _cityCtrl = TextEditingController(text: s.city ?? '');
    _stateCtrl = TextEditingController(text: s.state ?? '');
    _postalCodeCtrl = TextEditingController(text: s.postalCode ?? '');

    _hostelResident = s.hostelResident;
    _hostelNameCtrl = TextEditingController(text: s.hostelName ?? '');
    _roomNumberCtrl = TextEditingController(text: s.roomNumber ?? '');
  }

  @override
  void dispose() {
    _religionCtrl.dispose();
    _casteCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _postalCodeCtrl.dispose();
    _hostelNameCtrl.dispose();
    _roomNumberCtrl.dispose();
    super.dispose();
  }

  // ── Departments & Courses ──
  static const _departments = [
    'Computer Science',
    'Electronics & Communication',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical & Electronics Engineering',
    'Information Technology',
    'Applied Science',
    'MBA',
  ];

  static const _courses = ['BTech', 'MTech', 'MBA', 'BCA', 'MCA', 'BSc', 'MSc'];
  static const _categories = ['General', 'OBC', 'SC', 'ST', 'EWS', 'Minority'];

  // ── Department → Tutor / HOD auto-assignment ──
  static const _deptTutors = {
    'Computer Science': 'Dr. R. Krishnan (CSE Tutor)',
    'Electronics & Communication': 'Dr. S. Patel (ECE Tutor)',
    'Mechanical Engineering': 'Dr. A. Verma (ME Tutor)',
    'Civil Engineering': 'Dr. P. Nair (CE Tutor)',
    'Electrical & Electronics Engineering': 'Dr. M. Das (EEE Tutor)',
    'Information Technology': 'Dr. K. Sharma (IT Tutor)',
    'Applied Science': 'Dr. V. Iyer (AS Tutor)',
    'MBA': 'Dr. L. Reddy (MBA Tutor)',
  };
  static const _deptHods = {
    'Computer Science': 'Prof. D. Menon (HOD – CSE)',
    'Electronics & Communication': 'Prof. G. Rao (HOD – ECE)',
    'Mechanical Engineering': 'Prof. B. Gupta (HOD – ME)',
    'Civil Engineering': 'Prof. T. Joshi (HOD – CE)',
    'Electrical & Electronics Engineering': 'Prof. H. Pillai (HOD – EEE)',
    'Information Technology': 'Prof. N. Kumar (HOD – IT)',
    'Applied Science': 'Prof. J. Bhat (HOD – AS)',
    'MBA': 'Prof. C. Shah (HOD – MBA)',
  };

  String get _assignedTutor => _deptTutors[_department] ?? 'Not Assigned';
  String get _assignedHod => _deptHods[_department] ?? 'Not Assigned';

  @override
  Widget build(BuildContext context) {
    final student = Provider.of<ChatProvider>(context, listen: false).currentStudent!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text('Edit Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Read-only identity header ──
                  _buildIdentityCard(student),
                  const SizedBox(height: 16),

                  // ── Expandable sections ──
                  ExpansionPanelList(
                    elevation: 0,
                    expandedHeaderPadding: EdgeInsets.zero,
                    expansionCallback: (i, isExpanded) {
                      setState(() => _expanded[i] = isExpanded);
                    },
                    children: [
                      _buildAcademicPanel(),
                      _buildPersonalPanel(),
                      _buildContactPanel(),
                      _buildHostelPanel(),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── Save button (pinned bottom) ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.accentIndigo.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveProfile,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, color: Colors.white),
                label: Text(
                  _saving ? 'Saving…' : 'Save Changes',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  IDENTITY CARD (read-only)
  // ════════════════════════════════════════════════════════════════
  Widget _buildIdentityCard(Student s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                s.firstName[0],
                style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(s.id, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                if (s.batchYear != null)
                  Text('Batch: ${s.batchYear}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentIndigo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ID',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accentIndigo),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SECTION 1: ACADEMIC
  // ════════════════════════════════════════════════════════════════
  ExpansionPanel _buildAcademicPanel() {
    return ExpansionPanel(
      isExpanded: _expanded[0],
      canTapOnHeader: true,
      backgroundColor: AppColors.surfaceLight,
      headerBuilder: (_, expanded) => _sectionHeader(Icons.school_rounded, 'Academic Details', AppColors.accentTeal, expanded),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          children: [
            _buildDropdown('Department *', _department, _departments, (v) {
              setState(() => _department = v!);
            }, Icons.account_tree_rounded),
            const SizedBox(height: 14),
            _buildDropdown('Course *', _course, _courses, (v) => setState(() => _course = v!), Icons.menu_book_rounded),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'Year *',
                    _year.toString(),
                    List.generate(5, (i) => '${i + 1}'),
                    (v) => setState(() => _year = int.parse(v!)),
                    Icons.timeline_rounded,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildDropdown(
                    'Semester *',
                    _semester.toString(),
                    List.generate(10, (i) => '${i + 1}'),
                    (v) => setState(() => _semester = int.parse(v!)),
                    Icons.calendar_month_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // ── Auto-assigned Tutor & HOD (read-only) ──
            _buildAutoAssignTile(Icons.person_rounded, 'Faculty Advisor / Tutor', _assignedTutor, AppColors.accentIndigo),
            const SizedBox(height: 10),
            _buildAutoAssignTile(Icons.workspace_premium_rounded, 'Head of Department', _assignedHod, AppColors.accentTeal),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SECTION 2: PERSONAL
  // ════════════════════════════════════════════════════════════════
  ExpansionPanel _buildPersonalPanel() {
    return ExpansionPanel(
      isExpanded: _expanded[1],
      canTapOnHeader: true,
      backgroundColor: AppColors.surfaceLight,
      headerBuilder: (_, expanded) => _sectionHeader(Icons.person_rounded, 'Personal Details', AppColors.accentViolet, expanded),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          children: [
            _buildTextField(_religionCtrl, 'Religion', Icons.temple_hindu_rounded),
            const SizedBox(height: 14),
            _buildTextField(_casteCtrl, 'Caste / Community', Icons.group_rounded),
            const SizedBox(height: 14),
            _buildDropdown('Category', _category, _categories, (v) => setState(() => _category = v!), Icons.category_rounded),
            const SizedBox(height: 14),
            _buildSwitchRow('Minority Status', _minorityStatus, (v) => setState(() => _minorityStatus = v)),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SECTION 3: CONTACT
  // ════════════════════════════════════════════════════════════════
  ExpansionPanel _buildContactPanel() {
    return ExpansionPanel(
      isExpanded: _expanded[2],
      canTapOnHeader: true,
      backgroundColor: AppColors.surfaceLight,
      headerBuilder: (_, expanded) => _sectionHeader(Icons.phone_rounded, 'Contact Details', AppColors.accentPink, expanded),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          children: [
            _buildTextField(_phoneCtrl, 'Phone Number *', Icons.phone_android_rounded, keyboardType: TextInputType.phone),
            const SizedBox(height: 14),
            _buildTextField(_emailCtrl, 'Email Address', Icons.email_rounded, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 14),
            _buildTextField(_addressCtrl, 'Address', Icons.home_rounded, maxLines: 2),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildTextField(_cityCtrl, 'City', Icons.location_city_rounded)),
                const SizedBox(width: 14),
                Expanded(child: _buildTextField(_stateCtrl, 'State', Icons.map_rounded)),
              ],
            ),
            const SizedBox(height: 14),
            _buildTextField(_postalCodeCtrl, 'Postal Code', Icons.pin_drop_rounded, keyboardType: TextInputType.number),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SECTION 4: HOSTEL
  // ════════════════════════════════════════════════════════════════
  ExpansionPanel _buildHostelPanel() {
    return ExpansionPanel(
      isExpanded: _expanded[3],
      canTapOnHeader: true,
      backgroundColor: AppColors.surfaceLight,
      headerBuilder: (_, expanded) => _sectionHeader(Icons.hotel_rounded, 'Hostel Details', AppColors.warning, expanded),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          children: [
            _buildSwitchRow('Hostel Resident', _hostelResident, (v) => setState(() => _hostelResident = v)),
            if (_hostelResident) ...[
              const SizedBox(height: 14),
              _buildTextField(_hostelNameCtrl, 'Hostel Name', Icons.apartment_rounded),
              const SizedBox(height: 14),
              _buildTextField(_roomNumberCtrl, 'Room Number', Icons.meeting_room_rounded),
            ],
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SAVE
  // ════════════════════════════════════════════════════════════════
  Future<void> _saveProfile() async {
    setState(() => _saving = true);

    final provider = Provider.of<ChatProvider>(context, listen: false);
    final old = provider.currentStudent!;

    // Build updated Student
    final updated = Student(
      id: old.id,
      name: old.name,
      department: _department,
      year: _year,
      hostelResident: _hostelResident,
      role: old.role,
      staffDepartment: old.staffDepartment,
      profileCompleted: true,
      // Identity
      admissionNumber: old.admissionNumber,
      gender: old.gender,
      dateOfBirth: old.dateOfBirth,
      bloodGroup: old.bloodGroup,
      profileImageUrl: old.profileImageUrl,
      // Academic
      course: _course,
      branch: _department,
      semester: _semester,
      batchYear: old.batchYear,
      rollNumber: old.rollNumber,
      tutorName: _assignedTutor,
      // Contact
      email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
      altPhone: old.altPhone,
      address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
      city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
      state: _stateCtrl.text.trim().isNotEmpty ? _stateCtrl.text.trim() : null,
      postalCode: _postalCodeCtrl.text.trim().isNotEmpty ? _postalCodeCtrl.text.trim() : null,
      // Hostel
      hostelName: _hostelResident && _hostelNameCtrl.text.trim().isNotEmpty ? _hostelNameCtrl.text.trim() : null,
      roomNumber: _hostelResident && _roomNumberCtrl.text.trim().isNotEmpty ? _roomNumberCtrl.text.trim() : null,
      blockFloor: old.blockFloor,
      wardenName: old.wardenName,
      // Guardian
      fatherName: old.fatherName,
      motherName: old.motherName,
      parentPhone: old.parentPhone,
      guardianName: old.guardianName,
      guardianPhone: old.guardianPhone,
      // Gov ID
      aadhaarNumber: old.aadhaarNumber,
      nationalId: old.nationalId,
      passportNumber: old.passportNumber,
      // Social
      religion: _religionCtrl.text.trim().isNotEmpty ? _religionCtrl.text.trim() : null,
      caste: _casteCtrl.text.trim().isNotEmpty ? _casteCtrl.text.trim() : null,
      category: _category,
      minorityStatus: _minorityStatus,
    );

    // 1. Update MockData in-memory
    MockData.updateStudent(old.id, updated);

    // 2. Persist to Supabase
    bool supabaseSuccess = true;
    if (SupabaseConfig.useSupabase) {
      // Convert empty strings to null for nullable text columns
      String? nullify(String v) => v.trim().isEmpty ? null : v.trim();

      // Phase 1: Base columns (always exist in the students table)
      try {
        await SupabaseService.instance.updateStudentProfile(old.id, {
          'department': _department,
          'year': _year,
          'hostel': _hostelResident,
          'email': nullify(_emailCtrl.text),
        });
        debugPrint('[EditProfile] ✓ Base columns saved to Supabase');
      } catch (e) {
        supabaseSuccess = false;
        debugPrint('[EditProfile] ✗ Base Supabase update failed: $e');
      }

      // Phase 2: Extended profile columns (require ALTER TABLE migration)
      if (supabaseSuccess) {
        try {
          await SupabaseService.instance.updateStudentProfile(old.id, {
            'course': _course,
            'semester': _semester,
            'tutor_name': _assignedTutor,
            'phone': nullify(_phoneCtrl.text),
            'address': nullify(_addressCtrl.text),
            'city': nullify(_cityCtrl.text),
            'state': nullify(_stateCtrl.text),
            'postal_code': nullify(_postalCodeCtrl.text),
            'hostel_name': _hostelResident ? nullify(_hostelNameCtrl.text) : null,
            'room_number': _hostelResident ? nullify(_roomNumberCtrl.text) : null,
            'religion': nullify(_religionCtrl.text),
            'caste': nullify(_casteCtrl.text),
            'category': _category,
            'minority_status': _minorityStatus,
            'profile_completed': true,
          });
          debugPrint('[EditProfile] ✓ Extended columns saved to Supabase');
        } catch (e) {
          // Extended columns may not exist if migration hasn't been run
          debugPrint('[EditProfile] ⚠ Extended columns failed (run ALTER TABLE migration): $e');
        }
      }
    }

    // 3. Refresh ChatProvider from Supabase (keeps provider + MockData in sync)
    provider.invalidateCache();
    await provider.refreshStudentProfile();

    // 4. Push a profile-update notification
    await NotificationHelper.push(
      userId: old.id,
      type: 'profile_update',
      title: '✏️ Profile Updated',
      message: 'Your profile has been updated successfully.',
    );

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            supabaseSuccess
                ? '✅ Profile updated successfully!'
                : '⚠️ Saved locally — cloud sync failed.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: supabaseSuccess ? AppColors.success : AppColors.warning,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  // ════════════════════════════════════════════════════════════════
  //  REUSABLE WIDGETS
  // ════════════════════════════════════════════════════════════════
  Widget _sectionHeader(IconData icon, String title, Color color, bool expanded) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: expanded ? color : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildAutoAssignTile(IconData icon, String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'AUTO',
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accentIndigo, width: 1.5)),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, IconData icon) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      dropdownColor: AppColors.surface,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accentIndigo, width: 1.5)),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSwitchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: value ? AppColors.success : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}
