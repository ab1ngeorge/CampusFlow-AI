import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import 'staff_home_screen.dart';
import 'verify_clearance_screen.dart';
import 'manage_issues_screen.dart';
import 'review_retest_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class StaffMainScreen extends StatefulWidget {
  const StaffMainScreen({super.key});

  @override
  State<StaffMainScreen> createState() => StaffMainScreenState();
}

class StaffMainScreenState extends State<StaffMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    StaffHomeScreen(),
    VerifyClearanceScreen(),
    ReviewRetestScreen(),
    ManageIssuesScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);
    if (provider.currentStudent == null) {
      return const LoginScreen();
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'Home'),
                _buildNavItem(1, Icons.verified_rounded, Icons.verified_outlined, 'Clearance'),
                _buildNavItem(2, Icons.rate_review_rounded, Icons.rate_review_outlined, 'Retest'),
                _buildNavItem(3, Icons.bug_report_rounded, Icons.bug_report_outlined, 'Issues'),
                _buildNavItem(4, Icons.notifications_rounded, Icons.notifications_outlined, 'Alerts'),
                _buildNavItem(5, Icons.person_rounded, Icons.person_outlined, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.accentTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppColors.accentTeal : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.accentTeal : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
