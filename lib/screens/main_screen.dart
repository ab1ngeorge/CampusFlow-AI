import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'clearance_screen.dart';
import 'payment_screen.dart';
import 'chat_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'staff_main_screen.dart';
import 'admin_main_screen.dart';
import 'officer_main_screen.dart';

/// Routes to the correct shell based on the logged-in user's role.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);
    final user = provider.currentStudent;

    if (user == null) return const LoginScreen();

    switch (user.userRole) {
      case UserRole.staff:
      case UserRole.hod:
      case UserRole.tutor:
        return const StaffMainScreen();
      case UserRole.admin:
        return const AdminMainScreen();
      case UserRole.officer:
        return const OfficerMainScreen();
      case UserRole.student:
        return const StudentMainScreen();
    }
  }
}

/// The original student navigation shell (unchanged logic).
class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({super.key});

  @override
  State<StudentMainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<StudentMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ClearanceScreen(),
    PaymentScreen(),
    ChatScreen(),
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
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.assignment_rounded, Icons.assignment_outlined, 'Clearance'),
                _buildNavItem(2, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Payments'),
                _buildCenterNavItem(),
                _buildAlertNavItem(provider),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.accentIndigo.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppColors.accentIndigo : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.accentIndigo : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem() {
    final isActive = _currentIndex == 3;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 3),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryGradient : null,
          color: isActive ? null : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: isActive ? null : Border.all(color: AppColors.border),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.accentIndigo.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.smart_toy_rounded,
          color: isActive ? Colors.white : AppColors.textMuted,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildAlertNavItem(ChatProvider provider) {
    final isActive = _currentIndex == 4;
    final unread = provider.unreadNotificationCount;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 4),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.accentIndigo.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive
                      ? Icons.notifications_rounded
                      : Icons.notifications_outlined,
                  color: isActive ? AppColors.accentIndigo : AppColors.textMuted,
                  size: 22,
                ),
                // ── Live badge ──
                if (unread > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: AnimatedScale(
                      scale: unread > 0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: unread > 9 ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: unread > 9 ? BorderRadius.circular(8) : null,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Alerts',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.accentIndigo : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
