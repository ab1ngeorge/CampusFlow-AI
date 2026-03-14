import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';
import 'retest_request_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // 8 staggered animations: welcome, stat1, stat2, label, card0-5
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
    final student = provider.currentStudent;
    if (student == null) return const SizedBox.shrink();

    final dues = provider.cachedDues;
    final unread = provider.unreadNotificationCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await provider.refreshAllData();
            // Replay animations on refresh
            _animController.reset();
            _animController.forward();
          },
          color: AppColors.accentTeal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Welcome Header ──
                _fadeSlideIn(0, child: _buildWelcomeHeader(student.firstName, student.name)),
                const SizedBox(height: 28),

                // ── Quick Stats Row ──
                Row(
                  children: [
                    Expanded(
                      child: _fadeSlideIn(1, child: _buildMiniStat(
                        'Total Dues',
                        dues.hasDues ? '₹${dues.totalOutstanding.toStringAsFixed(0)}' : 'Clear ✓',
                        dues.hasDues ? AppColors.warning : AppColors.success,
                        Icons.account_balance_wallet_rounded,
                      )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _fadeSlideIn(2, child: _buildMiniStat(
                        'Alerts',
                        '$unread unread',
                        unread > 0 ? AppColors.error : AppColors.success,
                        Icons.notifications_active_rounded,
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Profile Completion Banner (if incomplete) ──
                if (!student.isAcademicProfileComplete)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.warning.withValues(alpha: 0.12),
                            AppColors.error.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          // Mini progress circle
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: student.academicProfilePercent / 100,
                                  strokeWidth: 4,
                                  backgroundColor: AppColors.border,
                                  valueColor: const AlwaysStoppedAnimation(AppColors.warning),
                                ),
                                Text(
                                  '${student.academicProfilePercent}%',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.warning),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profile Incomplete',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                                Text(
                                  '${student.missingAcademicFields.length} field${student.missingAcademicFields.length > 1 ? 's' : ''} missing — requests locked',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _switchTab(context, 5), // Profile tab
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Fix →', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Quick Access ──
                _fadeSlideIn(3, child: Text(
                  'Quick Access',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                )),
                const SizedBox(height: 16),

                // Grid of cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                  children: [
                    _fadeSlideIn(4, child: _DashboardCard(
                      icon: Icons.assignment_rounded,
                      label: 'Clearance\nStatus',
                      gradient: [AppColors.accentTeal, const Color(0xFF0891B2)],
                      onTap: () => _switchTab(context, 1),
                    )),
                    _fadeSlideIn(5, child: _DashboardCard(
                      icon: Icons.smart_toy_rounded,
                      label: 'AI\nAssistant',
                      gradient: [AppColors.accentIndigo, AppColors.accentViolet],
                      onTap: () => _switchTab(context, 3),
                    )),
                    _fadeSlideIn(6, child: _DashboardCard(
                      icon: Icons.star_rounded,
                      label: 'Opportunities',
                      gradient: [AppColors.warning, const Color(0xFFF59E0B)],
                      onTap: () {
                        _switchTab(context, 3);
                        Future.delayed(const Duration(milliseconds: 300), () {
                          provider.sendQuickAction('Show me available opportunities');
                        });
                      },
                    )),
                    _fadeSlideIn(7, child: _DashboardCard(
                      icon: Icons.report_problem_rounded,
                      label: 'Report\nIssue',
                      gradient: [AppColors.error, const Color(0xFFDC2626)],
                      onTap: () {
                        _switchTab(context, 3);
                        Future.delayed(const Duration(milliseconds: 300), () {
                          provider.sendQuickAction('I want to report an issue');
                        });
                      },
                    )),
                    _fadeSlideIn(8, child: _DashboardCard(
                      icon: Icons.replay_rounded,
                      label: 'Request\nRetest',
                      gradient: [AppColors.accentViolet, AppColors.accentPink],
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RetestRequestScreen()));
                      },
                    )),
                    _fadeSlideIn(9, child: _DashboardCard(
                      icon: Icons.payment_rounded,
                      label: 'Payment\nTracker',
                      gradient: [AppColors.success, const Color(0xFF16A34A)],
                      onTap: () => _switchTab(context, 2),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    final mainState = context.findAncestorStateOfType<MainScreenState>();
    mainState?.switchToTab(index);
  }

  Widget _buildWelcomeHeader(String firstName, String fullName) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentTeal.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              firstName[0],
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                fullName,
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
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
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
              // Background icon
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  widget.icon,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
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
