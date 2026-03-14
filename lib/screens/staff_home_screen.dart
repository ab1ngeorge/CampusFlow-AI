import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import 'staff_main_screen.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen>
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
    _cardAnimations = List.generate(8, (i) {
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

    final pendingCount = provider.getClearancesForDepartment(
      user.staffDepartment ?? user.department,
    ).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome Header ──
              _fadeSlideIn(0, child: _buildWelcomeHeader(user.name, user.staffDepartment ?? user.department)),
              const SizedBox(height: 28),

              // ── Stats Row ──
              Row(
                children: [
                  Expanded(
                    child: _fadeSlideIn(1, child: _buildMiniStat(
                      'Pending',
                      '$pendingCount requests',
                      pendingCount > 0 ? AppColors.warning : AppColors.success,
                      Icons.pending_actions_rounded,
                    )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _fadeSlideIn(2, child: _buildMiniStat(
                      'Open Issues',
                      '${provider.allClearanceRequests.length}',
                      AppColors.accentIndigo,
                      Icons.report_problem_rounded,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Quick Access ──
              _fadeSlideIn(3, child: Text(
                'Staff Actions',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
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
                  _fadeSlideIn(4, child: _DashboardCard(
                    icon: Icons.verified_rounded,
                    label: 'Verify\nClearance',
                    gradient: [AppColors.accentTeal, const Color(0xFF0891B2)],
                    onTap: () => _switchTab(context, 1),
                  )),
                  _fadeSlideIn(5, child: _DashboardCard(
                    icon: Icons.bug_report_rounded,
                    label: 'Manage\nIssues',
                    gradient: [AppColors.error, const Color(0xFFDC2626)],
                    onTap: () => _switchTab(context, 2),
                  )),
                  _fadeSlideIn(6, child: _DashboardCard(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    gradient: [AppColors.warning, const Color(0xFFF59E0B)],
                    onTap: () => _switchTab(context, 3),
                  )),
                  _fadeSlideIn(7, child: _DashboardCard(
                    icon: Icons.person_rounded,
                    label: 'My\nProfile',
                    gradient: [AppColors.accentViolet, AppColors.accentPink],
                    onTap: () => _switchTab(context, 4),
                  )),
                ],
              ),

              const SizedBox(height: 28),

              // ── Recent Activity ──
              Text(
                'Recent Clearance Requests',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...provider.allClearanceRequests.take(3).map((req) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _statusColor(req.overallStatus).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.description_rounded, color: _statusColor(req.overallStatus), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.clearanceTypeDisplay,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Student: ${req.studentId} • ${req.overallStatus}',
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                  ],
                ),
              )),
            ],
          ),
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

  Widget _fadeSlideIn(int index, {required Widget child}) {
    return AnimatedBuilder(
      animation: _cardAnimations[index],
      builder: (context, _) {
        final value = _cardAnimations[index].value;
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
    final mainState = context.findAncestorStateOfType<StaffMainScreenState>();
    mainState?.switchToTab(index);
  }

  Widget _buildWelcomeHeader(String name, String department) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentTeal.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Staff Portal',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentTeal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      department,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentTeal,
                      ),
                    ),
                  ),
                ],
              ),
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

  Widget _buildMiniStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ),
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
