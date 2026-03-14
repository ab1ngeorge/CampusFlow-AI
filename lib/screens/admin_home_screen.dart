import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/mock_data.dart';
import '../theme/app_theme.dart';
import 'admin_main_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardAnimations = List.generate(10, (i) {
      final start = (i * 0.08).clamp(0.0, 0.7);
      final end = (start + 0.3).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _animController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);
    final user = provider.currentStudent;
    if (user == null) return const SizedBox.shrink();

    final totalStudents = MockData.students.values.where((s) => s.role == 'student').length;
    final totalStaff = MockData.students.values.where((s) => s.role == 'staff').length;
    final pendingClearances = MockData.clearanceRequests.where((r) => r.overallStatus != 'approved').length;
    final totalOpportunities = MockData.opportunities.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome Header ──
              _fadeSlideIn(0, child: _buildAdminHeader(user.name)),
              const SizedBox(height: 28),

              // ── Stats Grid ──
              _fadeSlideIn(1, child: Text(
                'System Overview',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              )),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _fadeSlideIn(2, child: _buildStatCard('Students', '$totalStudents', Icons.school_rounded, AppColors.accentIndigo))),
                  const SizedBox(width: 12),
                  Expanded(child: _fadeSlideIn(3, child: _buildStatCard('Staff', '$totalStaff', Icons.badge_rounded, AppColors.accentTeal))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _fadeSlideIn(4, child: _buildStatCard('Pending', '$pendingClearances', Icons.pending_actions_rounded, AppColors.warning))),
                  const SizedBox(width: 12),
                  Expanded(child: _fadeSlideIn(5, child: _buildStatCard('Opportunities', '$totalOpportunities', Icons.star_rounded, AppColors.accentViolet))),
                ],
              ),
              const SizedBox(height: 28),

              // ── Quick Actions ──
              _fadeSlideIn(6, child: Text(
                'Admin Actions',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              )),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: [
                  _fadeSlideIn(7, child: _DashboardCard(
                    icon: Icons.people_rounded,
                    label: 'Manage\nUsers',
                    gradient: [AppColors.accentIndigo, AppColors.accentViolet],
                    onTap: () => _switchTab(context, 1),
                  )),
                  _fadeSlideIn(8, child: _DashboardCard(
                    icon: Icons.analytics_rounded,
                    label: 'System\nAnalytics',
                    gradient: [AppColors.accentTeal, const Color(0xFF0891B2)],
                    onTap: () => _switchTab(context, 2),
                  )),
                  _fadeSlideIn(9, child: _DashboardCard(
                    icon: Icons.campaign_rounded,
                    label: 'Post\nAnnouncement',
                    gradient: [AppColors.warning, const Color(0xFFF59E0B)],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📢 Announcement posting coming soon!'), duration: Duration(seconds: 2)),
                      );
                    },
                  )),
                  _fadeSlideIn(9, child: _DashboardCard(
                    icon: Icons.work_rounded,
                    label: 'Post\nOpportunity',
                    gradient: [AppColors.success, const Color(0xFF16A34A)],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🎯 Opportunity posting coming soon!'), duration: Duration(seconds: 2)),
                      );
                    },
                  )),
                ],
              ),

              const SizedBox(height: 28),

              // ── System Health ──
              Text(
                'System Health',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              _buildHealthCard('Database', 'Connected', AppColors.success, Icons.storage_rounded),
              const SizedBox(height: 8),
              _buildHealthCard('Auth Service', 'Active', AppColors.success, Icons.security_rounded),
              const SizedBox(height: 8),
              _buildHealthCard('AI Engine', 'Running', AppColors.success, Icons.smart_toy_rounded),
              const SizedBox(height: 8),
              _buildHealthCard('Notifications', 'Active', AppColors.success, Icons.notifications_active_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fadeSlideIn(int index, {required Widget child}) {
    final idx = index.clamp(0, _cardAnimations.length - 1);
    return AnimatedBuilder(
      animation: _cardAnimations[idx],
      builder: (context, _) {
        final value = _cardAnimations[idx].value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  void _switchTab(BuildContext context, int index) {
    final mainState = context.findAncestorStateOfType<AdminMainScreenState>();
    mainState?.switchToTab(index);
  }

  Widget _buildAdminHeader(String name) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentViolet.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accentViolet.withValues(alpha: 0.2), AppColors.accentPink.withValues(alpha: 0.2)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🔒 Administrator',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentViolet,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildHealthCard(String service, String status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Text(service, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const Spacer(),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(status, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(widget.icon, size: 80, color: Colors.white.withValues(alpha: 0.08)),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 24),
                    ),
                    const Spacer(),
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
