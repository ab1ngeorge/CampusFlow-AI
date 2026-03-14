import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/campus_tools.dart';
import '../theme/app_theme.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChatProvider>(context);
    final student = provider.currentStudent;
    if (student == null) return const SizedBox.shrink();

    final dues = provider.cachedDues;
    final unread = provider.unreadNotificationCount;
    final profilePercent = student.academicProfilePercent;
    final isComplete = student.isAcademicProfileComplete;

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
                color: AppColors.accentViolet.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.accentViolet, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentViolet.withValues(alpha: 0.3),
                  AppColors.accentPink.withValues(alpha: 0.3),
                  AppColors.accentIndigo.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar + Name ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentTeal.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        student.firstName[0],
                        style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(student.name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(student.id, style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Profile Completion ──
            if (!isComplete)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Profile Incomplete — $profilePercent%',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: profilePercent / 100,
                        minHeight: 6,
                        backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation(AppColors.warning),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Missing: ${student.missingAcademicFields.join(", ")}',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete your profile to unlock retest requests, scholarship matching, and more.',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                    ),
                  ],
                ),
              ),

            // ── Info Cards ──
            _buildInfoCard('Department', student.department, Icons.school_rounded, AppColors.accentTeal),
            if (student.course != null)
              _buildInfoCard('Course', student.course!, Icons.menu_book_rounded, AppColors.accentIndigo),
            _buildInfoCard('Year / Sem', 'Year ${student.year}${student.semester != null ? " • Sem ${student.semester}" : ""}', Icons.calendar_today_rounded, AppColors.accentIndigo),
            _buildInfoCard('Hostel', student.hostelResident ? 'Resident${student.hostelName != null ? " — ${student.hostelName}" : ""}' : 'Day Scholar', Icons.home_rounded, AppColors.accentViolet),
            if (student.phone != null)
              _buildInfoCard('Phone', student.phone!, Icons.phone_rounded, AppColors.accentPink),
            if (student.email != null)
              _buildInfoCard('Email', student.email!, Icons.email_rounded, AppColors.accentPink),
            if (student.tutorName != null)
              _buildInfoCard('Faculty Advisor', student.tutorName!, Icons.person_rounded, AppColors.accentIndigo),
            if (student.category != null)
              _buildInfoCard('Category', '${student.category}${student.minorityStatus == true ? " (Minority)" : ""}', Icons.group_rounded, AppColors.warning),
            _buildInfoCard('Role', student.role.toUpperCase(), Icons.badge_rounded, AppColors.warning),

            const SizedBox(height: 20),

            // ── Quick Stats ──
            Text('Quick Stats', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Dues', '₹${dues.totalOutstanding.toStringAsFixed(0)}', dues.hasDues ? AppColors.error : AppColors.success)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Unread', '$unread alerts', unread > 0 ? AppColors.warning : AppColors.success)),
              ],
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final clearance = CampusTools.getClearanceStatus(student.id, null);
                final String label;
                final Color color;
                if (clearance == null) {
                  label = 'No Request';
                  color = AppColors.textMuted;
                } else if (clearance.overallStatus == 'approved') {
                  label = '✅ Approved';
                  color = AppColors.success;
                } else if (clearance.overallStatus == 'on_hold') {
                  label = '⏸️ On Hold';
                  color = AppColors.warning;
                } else {
                  label = clearance.overallStatus.toUpperCase();
                  color = AppColors.accentIndigo;
                }
                return _buildStatCard('Clearance', label, color);
              },
            ),

            const SizedBox(height: 24),

            // ── Actions ──
            _buildActionTile(context, 'Edit Profile', Icons.edit_rounded, AppColors.accentIndigo, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            }),
            _buildActionTile(context, 'Clear Chat History', Icons.delete_sweep_rounded, AppColors.error, () async {
              await provider.clearHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chat history cleared', style: GoogleFonts.inter())),
                );
              }
            }),
            _buildActionTile(context, 'Sign Out', Icons.logout_rounded, AppColors.textMuted, () {
              provider.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }),

            const SizedBox(height: 30),
            Text('CampusFlow AI v1.2.0', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                Text(value, style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(label, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: AppColors.surfaceLight,
      ),
    );
  }
}
