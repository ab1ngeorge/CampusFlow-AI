import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

/// 7-step registration wizard for new students.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _currentStep = 0;
  bool _isSaving = false;
  final _formKeys = List.generate(7, (_) => GlobalKey<FormState>());

  // ── Step 1: Basic Identity ───────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _admissionCtrl = TextEditingController();
  String? _gender;
  DateTime? _dateOfBirth;
  String? _bloodGroup;

  // ── Step 2: Academic Information ─────────────────────────────
  String? _department;
  final _courseCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  int _year = 1;
  int _semester = 1;
  final _batchCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _tutorCtrl = TextEditingController();

  // ── Step 3: Contact Information ──────────────────────────────
  final _phoneCtrl = TextEditingController();
  final _altPhoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();

  // ── Step 4: Hostel Details ───────────────────────────────────
  bool _isHosteller = false;
  final _hostelNameCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _blockCtrl = TextEditingController();
  final _wardenCtrl = TextEditingController();

  // ── Step 5: Parent / Guardian ────────────────────────────────
  final _fatherCtrl = TextEditingController();
  final _motherCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  final _guardianCtrl = TextEditingController();
  final _guardianPhoneCtrl = TextEditingController();

  // ── Step 6: Social Category ──────────────────────────────────
  final _religionCtrl = TextEditingController();
  final _casteCtrl = TextEditingController();
  String _category = 'General';
  bool _minorityStatus = false;

  // ── Step 7: Documents (info-only for now) ────────────────────
  // Document uploads handled separately via document vault

  static const _genders = ['Male', 'Female', 'Other'];
  static const _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const _departments = [
    'Computer Science', 'Electronics & Communication', 'Electrical',
    'Mechanical', 'Civil', 'Information Technology', 'MBA', 'MCA', 'Other',
  ];
  static const _categories = ['General', 'OBC', 'SC', 'ST', 'EWS'];

  @override
  void initState() {
    super.initState();
    // Pre-fill from existing student data
    final student = Provider.of<ChatProvider>(context, listen: false).currentStudent;
    if (student != null) {
      _nameCtrl.text = student.name;
      _department = student.department;
      _year = student.year;
      _isHosteller = student.hostelResident;
      if (student.admissionNumber != null) _admissionCtrl.text = student.admissionNumber!;
      _gender = student.gender;
      _dateOfBirth = student.dateOfBirth;
      _bloodGroup = student.bloodGroup;
      if (student.course != null) _courseCtrl.text = student.course!;
      if (student.branch != null) _branchCtrl.text = student.branch!;
      if (student.semester != null) _semester = student.semester!;
      if (student.batchYear != null) _batchCtrl.text = student.batchYear.toString();
      if (student.rollNumber != null) _rollCtrl.text = student.rollNumber!;
      if (student.tutorName != null) _tutorCtrl.text = student.tutorName!;
      if (student.phone != null) _phoneCtrl.text = student.phone!;
      if (student.altPhone != null) _altPhoneCtrl.text = student.altPhone!;
      if (student.address != null) _addressCtrl.text = student.address!;
      if (student.city != null) _cityCtrl.text = student.city!;
      if (student.state != null) _stateCtrl.text = student.state!;
      if (student.postalCode != null) _postalCtrl.text = student.postalCode!;
      if (student.hostelName != null) _hostelNameCtrl.text = student.hostelName!;
      if (student.roomNumber != null) _roomCtrl.text = student.roomNumber!;
      if (student.blockFloor != null) _blockCtrl.text = student.blockFloor!;
      if (student.wardenName != null) _wardenCtrl.text = student.wardenName!;
      if (student.fatherName != null) _fatherCtrl.text = student.fatherName!;
      if (student.motherName != null) _motherCtrl.text = student.motherName!;
      if (student.parentPhone != null) _parentPhoneCtrl.text = student.parentPhone!;
      if (student.guardianName != null) _guardianCtrl.text = student.guardianName!;
      if (student.guardianPhone != null) _guardianPhoneCtrl.text = student.guardianPhone!;
      if (student.religion != null) _religionCtrl.text = student.religion!;
      if (student.caste != null) _casteCtrl.text = student.caste!;
      if (student.category != null) _category = student.category!;
      _minorityStatus = student.minorityStatus ?? false;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _admissionCtrl, _courseCtrl, _branchCtrl, _batchCtrl,
      _rollCtrl, _tutorCtrl, _phoneCtrl, _altPhoneCtrl, _addressCtrl,
      _cityCtrl, _stateCtrl, _postalCtrl, _hostelNameCtrl, _roomCtrl,
      _blockCtrl, _wardenCtrl, _fatherCtrl, _motherCtrl, _parentPhoneCtrl,
      _guardianCtrl, _guardianPhoneCtrl, _religionCtrl, _casteCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      final studentId = provider.currentStudent!.id;

      final data = <String, dynamic>{
        // Identity
        'name': _nameCtrl.text.trim(),
        'admission_number': _admissionCtrl.text.trim().isNotEmpty ? _admissionCtrl.text.trim() : null,
        'gender': _gender,
        'date_of_birth': _dateOfBirth?.toIso8601String().split('T').first,
        'blood_group': _bloodGroup,
        // Academic
        'department': _department,
        'course': _courseCtrl.text.trim().isNotEmpty ? _courseCtrl.text.trim() : null,
        'branch': _branchCtrl.text.trim().isNotEmpty ? _branchCtrl.text.trim() : null,
        'year': _year,
        'semester': _semester,
        'batch_year': _batchCtrl.text.trim().isNotEmpty ? int.tryParse(_batchCtrl.text.trim()) : null,
        'roll_number': _rollCtrl.text.trim().isNotEmpty ? _rollCtrl.text.trim() : null,
        'tutor_name': _tutorCtrl.text.trim().isNotEmpty ? _tutorCtrl.text.trim() : null,
        // Contact
        'phone': _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        'alt_phone': _altPhoneCtrl.text.trim().isNotEmpty ? _altPhoneCtrl.text.trim() : null,
        'address': _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
        'city': _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
        'state': _stateCtrl.text.trim().isNotEmpty ? _stateCtrl.text.trim() : null,
        'postal_code': _postalCtrl.text.trim().isNotEmpty ? _postalCtrl.text.trim() : null,
        // Hostel
        'hostel': _isHosteller,
        'hostel_name': _isHosteller && _hostelNameCtrl.text.trim().isNotEmpty ? _hostelNameCtrl.text.trim() : null,
        'room_number': _isHosteller && _roomCtrl.text.trim().isNotEmpty ? _roomCtrl.text.trim() : null,
        'block_floor': _isHosteller && _blockCtrl.text.trim().isNotEmpty ? _blockCtrl.text.trim() : null,
        'warden_name': _isHosteller && _wardenCtrl.text.trim().isNotEmpty ? _wardenCtrl.text.trim() : null,
        // Guardian
        'father_name': _fatherCtrl.text.trim().isNotEmpty ? _fatherCtrl.text.trim() : null,
        'mother_name': _motherCtrl.text.trim().isNotEmpty ? _motherCtrl.text.trim() : null,
        'parent_phone': _parentPhoneCtrl.text.trim().isNotEmpty ? _parentPhoneCtrl.text.trim() : null,
        'guardian_name': _guardianCtrl.text.trim().isNotEmpty ? _guardianCtrl.text.trim() : null,
        'guardian_phone': _guardianPhoneCtrl.text.trim().isNotEmpty ? _guardianPhoneCtrl.text.trim() : null,
        // Gov ID — skip since we don't collect in wizard
        // Social
        'religion': _religionCtrl.text.trim().isNotEmpty ? _religionCtrl.text.trim() : null,
        'caste': _casteCtrl.text.trim().isNotEmpty ? _casteCtrl.text.trim() : null,
        'category': _category,
        'minority_status': _minorityStatus,
        // Mark profile as completed
        'profile_completed': true,
      };

      await SupabaseService.instance.updateStudentProfile(studentId, data);

      // Refresh the student object in the provider
      await provider.refreshStudentProfile();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _nextStep() {
    if (_formKeys[_currentStep].currentState?.validate() ?? false) {
      if (_currentStep < 6) {
        setState(() => _currentStep++);
      } else {
        _saveProfile();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
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
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.app_registration_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Complete Your Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        ),
      ),
      body: Column(
        children: [
          // ── Progress indicator ───────────────────────────────
          _buildProgressBar(),
          // ── Step content ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
            ),
          ),
          // ── Bottom buttons ───────────────────────────────────
          _buildBottomButtons(),
        ],
      ),
    );
  }

  // ── Progress bar ─────────────────────────────────────────────
  Widget _buildProgressBar() {
    final labels = ['Identity', 'Academic', 'Contact', 'Hostel', 'Guardian', 'Social', 'Documents'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: List.generate(7, (i) {
              final isComplete = i < _currentStep;
              final isActive = i == _currentStep;
              return Expanded(
                child: GestureDetector(
                  onTap: i <= _currentStep ? () => setState(() => _currentStep = i) : null,
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isComplete
                              ? AppColors.success
                              : isActive
                                  ? AppColors.accentIndigo
                                  : AppColors.border,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? AppColors.accentIndigo : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${_currentStep + 1} of 7',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ── Step router ──────────────────────────────────────────────
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStep1Identity();
      case 1: return _buildStep2Academic();
      case 2: return _buildStep3Contact();
      case 3: return _buildStep4Hostel();
      case 4: return _buildStep5Guardian();
      case 5: return _buildStep6Social();
      case 6: return _buildStep7Documents();
      default: return const SizedBox.shrink();
    }
  }

  // ── Bottom buttons ───────────────────────────────────────────
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _prevStep,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentIndigo.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _nextStep,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(_currentStep == 6 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded, color: Colors.white),
                label: Text(
                  _currentStep == 6 ? 'Complete Registration' : 'Continue',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  STEP 1: BASIC IDENTITY
  // ════════════════════════════════════════════════════════════
  Widget _buildStep1Identity() {
    return Form(
      key: _formKeys[0],
      child: Column(
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Basic Identity', Icons.person_rounded, 'Your personal identification details'),
          const SizedBox(height: 20),
          _field('Full Name *', _nameCtrl, validator: _requiredValidator, icon: Icons.badge_outlined),
          _field('Admission Number', _admissionCtrl, icon: Icons.numbers_rounded),
          _dropdown('Gender *', _gender, _genders, (v) => setState(() => _gender = v), icon: Icons.wc_rounded),
          _datePicker('Date of Birth', _dateOfBirth, (v) => setState(() => _dateOfBirth = v)),
          _dropdown('Blood Group', _bloodGroup, _bloodGroups, (v) => setState(() => _bloodGroup = v), icon: Icons.bloodtype_rounded),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  STEP 2: ACADEMIC INFORMATION
  // ════════════════════════════════════════════════════════════
  Widget _buildStep2Academic() {
    return Form(
      key: _formKeys[1],
      child: Column(
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Academic Information', Icons.school_rounded, 'Your academic details and specialization'),
          const SizedBox(height: 20),
          _dropdown('Department *', _department, _departments, (v) => setState(() => _department = v), icon: Icons.business_rounded),
          _field('Course / Program', _courseCtrl, hint: 'e.g. B.Tech, M.Tech, MBA', icon: Icons.menu_book_rounded),
          _field('Branch / Specialization', _branchCtrl, hint: 'e.g. CSE, ECE, AI&ML', icon: Icons.account_tree_rounded),
          _buildNumberRow('Year of Study', _year, 1, 6, (v) => setState(() => _year = v)),
          _buildNumberRow('Current Semester', _semester, 1, 12, (v) => setState(() => _semester = v)),
          _field('Batch / Admission Year', _batchCtrl, keyboardType: TextInputType.number, hint: 'e.g. 2024', icon: Icons.date_range_rounded),
          _field('Roll Number', _rollCtrl, icon: Icons.format_list_numbered_rounded),
          _field('Tutor / Faculty Advisor', _tutorCtrl, icon: Icons.supervisor_account_rounded),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  STEP 3: CONTACT INFORMATION
  // ════════════════════════════════════════════════════════════
  Widget _buildStep3Contact() {
    return Form(
      key: _formKeys[2],
      child: Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Contact Information', Icons.contact_phone_rounded, 'How we can reach you'),
          const SizedBox(height: 20),
          _field('Phone Number *', _phoneCtrl, keyboardType: TextInputType.phone, validator: _requiredValidator, icon: Icons.phone_rounded),
          _field('Alternate Phone', _altPhoneCtrl, keyboardType: TextInputType.phone, icon: Icons.phone_forwarded_rounded),
          _field('Residential Address', _addressCtrl, maxLines: 2, icon: Icons.home_rounded),
          _field('City', _cityCtrl, icon: Icons.location_city_rounded),
          _field('State', _stateCtrl, icon: Icons.map_rounded),
          _field('Postal Code', _postalCtrl, keyboardType: TextInputType.number, icon: Icons.local_post_office_rounded),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  STEP 4: HOSTEL DETAILS
  // ════════════════════════════════════════════════════════════
  Widget _buildStep4Hostel() {
    return Form(
      key: _formKeys[3],
      child: Column(
        key: const ValueKey(3),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Hostel Information', Icons.apartment_rounded, 'Your hostel accommodation details'),
          const SizedBox(height: 20),
          _buildToggle('Are you a hosteller?', _isHosteller, (v) => setState(() => _isHosteller = v)),
          if (_isHosteller) ...[
            const SizedBox(height: 16),
            _field('Hostel Name', _hostelNameCtrl, icon: Icons.domain_rounded),
            _field('Room Number', _roomCtrl, icon: Icons.meeting_room_rounded),
            _field('Block / Floor', _blockCtrl, icon: Icons.layers_rounded),
            _field('Hostel Warden Name', _wardenCtrl, icon: Icons.admin_panel_settings_rounded),
          ],
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  STEP 5: PARENT / GUARDIAN
  // ════════════════════════════════════════════════════════════
  Widget _buildStep5Guardian() {
    return Form(
      key: _formKeys[4],
      child: Column(
        key: const ValueKey(4),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Parent / Guardian', Icons.family_restroom_rounded, 'Emergency contact and official records'),
          const SizedBox(height: 20),
          _field('Father\'s Name', _fatherCtrl, icon: Icons.person_rounded),
          _field('Mother\'s Name', _motherCtrl, icon: Icons.person_rounded),
          _field('Parent Phone Number', _parentPhoneCtrl, keyboardType: TextInputType.phone, icon: Icons.phone_rounded),
          const SizedBox(height: 8),
          Divider(color: AppColors.border.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          _field('Guardian Name (if different)', _guardianCtrl, icon: Icons.person_outline_rounded),
          _field('Guardian Phone', _guardianPhoneCtrl, keyboardType: TextInputType.phone, icon: Icons.phone_outlined),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  STEP 6: SOCIAL CATEGORY
  // ════════════════════════════════════════════════════════════
  Widget _buildStep6Social() {
    return Form(
      key: _formKeys[5],
      child: Column(
        key: const ValueKey(5),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Social Category', Icons.diversity_3_rounded, 'Helps recommend eligible scholarships'),
          const SizedBox(height: 20),
          _field('Religion', _religionCtrl, icon: Icons.temple_hindu_rounded),
          _field('Caste / Community', _casteCtrl, icon: Icons.group_rounded),
          _dropdown('Category *', _category, _categories, (v) {
            if (v != null) setState(() => _category = v);
          }, icon: Icons.category_rounded),
          _buildToggle('Minority Status', _minorityStatus, (v) => setState(() => _minorityStatus = v)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  STEP 7: DOCUMENTS (INFO)
  // ════════════════════════════════════════════════════════════
  Widget _buildStep7Documents() {
    final docs = [
      {'icon': Icons.badge_rounded, 'name': 'College ID Card'},
      {'icon': Icons.school_rounded, 'name': '10th Certificate'},
      {'icon': Icons.school_rounded, 'name': '12th Certificate'},
      {'icon': Icons.swap_horiz_rounded, 'name': 'Transfer Certificate'},
      {'icon': Icons.people_rounded, 'name': 'Community Certificate'},
      {'icon': Icons.attach_money_rounded, 'name': 'Income Certificate'},
      {'icon': Icons.assessment_rounded, 'name': 'Semester Mark Lists'},
      {'icon': Icons.work_rounded, 'name': 'Internship Certificates'},
    ];

    return Form(
      key: _formKeys[6],
      child: Column(
        key: const ValueKey(6),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Document Vault', Icons.folder_rounded, 'You can upload documents later from your profile'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Document uploads will be available in your profile after registration. You can skip this step.',
                    style: GoogleFonts.inter(color: AppColors.info, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Recommended Documents', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...docs.map((doc) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(doc['icon'] as IconData, color: AppColors.textMuted, size: 22),
                const SizedBox(width: 14),
                Expanded(child: Text(doc['name'] as String, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14))),
                Icon(Icons.cloud_upload_outlined, color: AppColors.textMuted.withValues(alpha: 0.5), size: 20),
              ],
            ),
          )),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.success.withValues(alpha: 0.1), AppColors.accentTeal.withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
                const SizedBox(height: 10),
                Text('Almost Done!', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.success)),
                const SizedBox(height: 6),
                Text(
                  'Tap "Complete Registration" to save your profile.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  REUSABLE FIELD WIDGETS
  // ════════════════════════════════════════════════════════════

  Widget _stepHeader(String title, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentIndigo.withValues(alpha: 0.12), AppColors.accentViolet.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentIndigo.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentIndigo.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.accentIndigo, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.inter(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted.withValues(alpha: 0.4)),
          prefixIcon: icon != null ? Icon(icon, color: AppColors.textMuted, size: 20) : null,
        ),
      ),
    );
  }

  Widget _dropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
          prefixIcon: icon != null ? Icon(icon, color: AppColors.textMuted, size: 20) : null,
        ),
        dropdownColor: AppColors.surfaceLight,
        style: GoogleFonts.inter(color: AppColors.textPrimary),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _datePicker(String label, DateTime? value, ValueChanged<DateTime> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime(2004, 1, 1),
            firstDate: DateTime(1980),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.accentIndigo,
                    surface: AppColors.surfaceLight,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.textMuted, size: 20),
          ),
          child: Text(
            value != null ? DateFormat('dd MMM yyyy').format(value) : 'Tap to select',
            style: GoogleFonts.inter(color: value != null ? AppColors.textPrimary : AppColors.textMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        title: Text(label, style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        value: value,
        onChanged: (v) => onChanged(v),
        activeThumbColor: AppColors.accentIndigo,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildNumberRow(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.tag_rounded, color: AppColors.textMuted, size: 20),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.textMuted),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            Container(
              width: 48,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.accentIndigo.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$value', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accentIndigo)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.textMuted),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    return null;
  }
}
