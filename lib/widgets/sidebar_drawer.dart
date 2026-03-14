import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class SidebarDrawer extends StatelessWidget {
  final Student student;
  final Function(String) onQuickAction;
  final VoidCallback onLogout;
  final Function(String)? onNavigate;

  const SidebarDrawer({
    super.key,
    required this.student,
    required this.onQuickAction,
    required this.onLogout,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppColors.subtleGradient,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => onNavigate?.call('profile'),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentIndigo.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          student.firstName[0],
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    student.name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.id,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentTeal.withValues(alpha: 0.2),
                          AppColors.accentIndigo.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${student.department} • Year ${student.year}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accentTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Navigation Section
            _sectionLabel('NAVIGATE'),
            _actionTile(
              icon: Icons.person_rounded,
              label: 'Profile & Settings',
              color: AppColors.accentIndigo,
              onTap: () => onNavigate?.call('profile'),
            ),
            _actionTile(
              icon: Icons.bar_chart_rounded,
              label: 'Financial Charts',
              color: AppColors.accentTeal,
              onTap: () => onNavigate?.call('charts'),
            ),
            _actionTile(
              icon: Icons.calendar_month_rounded,
              label: 'Calendar & Deadlines',
              color: AppColors.warning,
              onTap: () => onNavigate?.call('calendar'),
            ),

            const Divider(color: AppColors.border, indent: 20, endIndent: 20, height: 20),

            // Quick Actions
            _sectionLabel('QUICK ACTIONS'),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _actionTile(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Check Dues',
                    color: AppColors.warning,
                    onTap: () { Navigator.pop(context); onQuickAction('Do I have any dues?'); },
                  ),
                  _actionTile(
                    icon: Icons.description_rounded,
                    label: 'Request Certificate',
                    color: AppColors.accentIndigo,
                    onTap: () { Navigator.pop(context); onQuickAction('I need a certificate'); },
                  ),
                  _actionTile(
                    icon: Icons.build_rounded,
                    label: 'Report Issue',
                    color: AppColors.error,
                    onTap: () { Navigator.pop(context); onQuickAction('I want to report an issue'); },
                  ),
                  _actionTile(
                    icon: Icons.star_rounded,
                    label: 'Opportunities',
                    color: AppColors.accentTeal,
                    onTap: () { Navigator.pop(context); onQuickAction('Show me opportunities'); },
                  ),
                  _actionTile(
                    icon: Icons.folder_rounded,
                    label: 'My Documents',
                    color: AppColors.accentViolet,
                    onTap: () { Navigator.pop(context); onQuickAction('Show my documents'); },
                  ),
                  _actionTile(
                    icon: Icons.payments_rounded,
                    label: 'Payment Summary',
                    color: AppColors.success,
                    onTap: () { Navigator.pop(context); onQuickAction('Show my fee details'); },
                  ),
                  _actionTile(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    color: AppColors.accentPink,
                    onTap: () { Navigator.pop(context); onQuickAction('Show my notifications'); },
                  ),
                ],
              ),
            ),

            // Version & Logout
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onLogout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Sign Out',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CampusFlow AI v1.1',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: onTap,
        ),
      ),
    );
  }
}
