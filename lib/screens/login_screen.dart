import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/mock_data.dart';
import '../services/supabase_config.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _studentIdController = TextEditingController(text: 'STU-001001');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  final _mockUsernameController = TextEditingController();
  final _mockPasswordController = TextEditingController();

  // ── Department-based grouped demo accounts ──
  static const _deptNames = ['CSE', 'ECE', 'ME', 'CE', 'EEE', 'IT', 'AS'];
  static const _deptLabels = ['Computer Science', 'Electronics & Communication', 'Mechanical Engineering', 'Civil Engineering', 'Electrical & Electronics', 'Information Technology', 'Applied Science'];

  // All demo credential cards: { username, password, name, role, dept }
  final List<Map<String, String>> _hodAccounts = [
    for (int i = 0; i < _deptNames.length; i++)
      {'username': 'hod.${_deptNames[i].toLowerCase()}', 'password': 'HOD@123', 'name': 'HOD – ${_deptNames[i]}', 'dept': _deptLabels[i], 'role': 'hod'},
  ];
  final List<Map<String, String>> _tutorAccounts = [
    for (int i = 0; i < _deptNames.length; i++)
      {'username': 'tutor.${_deptNames[i].toLowerCase()}', 'password': 'Tutor@123', 'name': 'Tutor – ${_deptNames[i]}', 'dept': _deptLabels[i], 'role': 'tutor'},
  ];
  final List<Map<String, String>> _collegeStaff = [
    {'username': 'placement.office', 'password': 'Placement@123', 'name': 'Placement Cell',   'dept': 'Internships & Placements', 'role': 'staff'},
    {'username': 'hostel.office',    'password': 'Hostel@123',    'name': 'Hostel Office',     'dept': 'Hostel Dues & Clearance', 'role': 'staff'},
    {'username': 'accounts.office',  'password': 'Accounts@123',  'name': 'Accounts Office',   'dept': 'Fee Payments & Dues', 'role': 'staff'},
    {'username': 'library.staff',    'password': 'Library@123',   'name': 'Library Staff',     'dept': 'Books & Library Clearance', 'role': 'staff'},
    {'username': 'sports.office',    'password': 'Sports@123',    'name': 'Physical Education', 'dept': 'Sports Clearance', 'role': 'staff'},
  ];
  final List<Map<String, String>> _officerAccount = [
    {'username': 'officer', 'password': 'Officer@123', 'name': 'Scholarship Officer', 'dept': 'Scholarships & e-Grants', 'role': 'officer'},
  ];
  final List<Map<String, String>> _adminAccount = [
    {'username': 'admin', 'password': 'Admin@123', 'name': 'System Admin', 'dept': 'Full System Access', 'role': 'admin'},
  ];
  final List<Map<String, String>> _studentAccounts = [
    {'id': 'STU-001001', 'name': 'Arjun Sharma', 'dept': 'Computer Science, Year 3'},
    {'id': 'STU-001002', 'name': 'Priya Nair', 'dept': 'ECE, Year 2'},
    {'id': 'STU-001003', 'name': 'Ravi Kumar', 'dept': 'MBA, Year 1'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _mockUsernameController.dispose();
    _mockPasswordController.dispose();
    super.dispose();
  }

  // ── Mock login by student ID ───────────────────────────────
  void _loginMock(String studentId) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.login(studentId);
    _navigateToChat();
  }

  // ── Mock login by username + password ──────────────────────
  void _loginMockCredentials() {
    final username = _mockUsernameController.text.trim();
    final password = _mockPasswordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter username and password');
      return;
    }

    final creds = MockData.credentials[username];
    if (creds == null || creds['password'] != password) {
      setState(() => _errorMessage = 'Invalid username or password');
      return;
    }
    _loginMock(creds['userId']!);
  }

  // ── Supabase login ──────────────────────────────────────────
  Future<void> _loginSupabase() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter email and password');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.loginWithSupabase(email, password);
      if (mounted) _navigateToChat();
    } catch (e) {
      debugPrint('[LoginScreen] Login error: $e');
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Supabase sign up ────────────────────────────────────────
  Future<void> _signUpSupabase() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final generatedId = await chatProvider.signUpWithSupabase(
        email: email,
        password: password,
        name: name,
      );
      if (mounted) {
        setState(() {
          _isSignUp = false;
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created! Your Student ID is $generatedId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('[LoginScreen] SignUp error: $e');
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToChat() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  String _friendlyError(String msg) {
    if (msg.contains('Invalid login credentials')) return 'Invalid email or password';
    if (msg.contains('Email not confirmed')) return 'Please verify your email first';
    if (msg.contains('User already registered')) return 'This email is already registered';
    if (msg.contains('rate limit')) return 'Too many attempts, try again later';
    if (msg.contains('SocketException') || msg.contains('NetworkException')) {
      return 'Network error. Please check your internet connection.';
    }
    // Show truncated real error for debugging
    final short = msg.length > 120 ? '${msg.substring(0, 120)}...' : msg;
    return 'Error: $short';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.loginGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo & Title
                      _buildLogo(),
                      const SizedBox(height: 24),
                      Text(
                        'CampusFlow',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                        child: Text(
                          'AI Campus Assistant',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Login Card — always show mock/demo login
                      _buildMockLoginCard(),

                      // Optional Supabase signup (for real accounts)
                      if (SupabaseConfig.useSupabase) ...[
                        const SizedBox(height: 24),
                        _buildSupabaseLoginCard(),
                      ],

                      const SizedBox(height: 32),
                      Text(
                        'CampusFlow AI v1.0',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo ─────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentIndigo.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
    );
  }

  // ── Supabase auth card ───────────────────────────────────────
  Widget _buildSupabaseLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: GlassDecoration.card(opacity: 0.08, borderRadius: 24),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isSignUp ? 'Create Account' : 'Sign In',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isSignUp
                ? 'Enter your details to register'
                : 'Use your college email to log in',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          // Error banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Sign-up extra fields
          if (_isSignUp) ...[
            TextField(
              controller: _nameController,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Email
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'College Email',
              hintText: 'student@college.edu',
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted.withValues(alpha: 0.4)),
              labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),

          // Password
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            onSubmitted: (_) => _isSignUp ? _signUpSupabase() : _loginSupabase(),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit button
          _buildGradientButton(
            label: _isSignUp ? 'Create Account' : 'Sign In',
            icon: _isSignUp ? Icons.person_add_rounded : Icons.login_rounded,
            isLoading: _isLoading,
            onPressed: _isLoading
                ? null
                : (_isSignUp ? _signUpSupabase : _loginSupabase),
          ),
          const SizedBox(height: 16),

          // Toggle sign-up / sign-in
          TextButton(
            onPressed: () {
              setState(() {
                _isSignUp = !_isSignUp;
                _errorMessage = null;
              });
            },
            child: Text(
              _isSignUp
                  ? 'Already have an account? Sign In'
                  : 'New student? Create Account',
              style: GoogleFonts.inter(
                color: AppColors.accentIndigo,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mock login card ──────────────────────────────────────────
  Widget _buildMockLoginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: GlassDecoration.card(opacity: 0.08, borderRadius: 24),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign In',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use username & password, or select a demo account',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          // ── Username + Password Fields ──
          TextField(
            controller: _mockUsernameController,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
              hintText: 'e.g. hod.cse, library.staff, admin',
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted.withValues(alpha: 0.5), fontSize: 12),
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _mockPasswordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: AppColors.textMuted, size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Login button
          _buildGradientButton(
            label: 'Sign In',
            icon: Icons.login_rounded,
            isLoading: false,
            onPressed: _loginMockCredentials,
          ),

          // ── OR divider ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.5))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                ),
                Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.5))),
              ],
            ),
          ),

          // ── Student ID Field ──
          TextField(
            controller: _studentIdController,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Student ID',
              labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 14),
          _buildGradientButton(
            label: 'Student Login',
            icon: Icons.school_rounded,
            isLoading: false,
            onPressed: () => _loginMock(_studentIdController.text),
          ),
          const SizedBox(height: 28),

          // ── Demo Accounts ──
          _buildCredentialSection('🎓 Department HODs', _hodAccounts, const Color(0xFFDC2626)),
          const SizedBox(height: 14),
          _buildCredentialSection('👨‍🏫 Department Tutors', _tutorAccounts, AppColors.warning),
          const SizedBox(height: 14),
          _buildCredentialSection('🏛️ College Staff', _collegeStaff, AppColors.accentTeal),
          const SizedBox(height: 14),
          _buildCredentialSection('🎓 Scholarship Officer', _officerAccount, const Color(0xFFF59E0B)),
          const SizedBox(height: 14),
          _buildCredentialSection('🔒 System Admin', _adminAccount, AppColors.accentViolet),
          const SizedBox(height: 14),
          _buildStudentSection('👩‍🎓 Student Accounts', _studentAccounts, AppColors.accentIndigo),
        ],
      ),
    );
  }

  /// Builds a grouped section for credential-based (username/password) demo accounts.
  Widget _buildCredentialSection(String title, List<Map<String, String>> accounts, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: accentColor.withValues(alpha: 0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                style: GoogleFonts.inter(fontSize: 12, color: accentColor, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: Divider(color: accentColor.withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: 8),
        ...accounts.map((acct) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _mockUsernameController.text = acct['username']!;
                _mockPasswordController.text = acct['password']!;
                _loginMockCredentials();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_roleIcon(acct['role']!), color: accentColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acct['name']!,
                            style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            '${acct['username']}  •  ${acct['dept']}',
                            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted.withValues(alpha: 0.5), size: 14),
                  ],
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }

  /// Builds a grouped section for student (ID-based) demo accounts.
  Widget _buildStudentSection(String title, List<Map<String, String>> accounts, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: accentColor.withValues(alpha: 0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                style: GoogleFonts.inter(fontSize: 12, color: accentColor, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: Divider(color: accentColor.withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: 8),
        ...accounts.map((acct) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _loginMock(acct['id']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.school_rounded, color: accentColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acct['name']!,
                            style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            '${acct['id']}  •  ${acct['dept']}',
                            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted.withValues(alpha: 0.5), size: 14),
                  ],
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'hod': return Icons.workspace_premium_rounded;
      case 'tutor': return Icons.school_rounded;
      case 'admin': return Icons.shield_rounded;
      default: return Icons.badge_rounded;
    }
  }

  // ── Gradient button ─────────────────────────────────────────
  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentIndigo.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(color: Colors.white)),
                ],
              ),
      ),
    );
  }
}
