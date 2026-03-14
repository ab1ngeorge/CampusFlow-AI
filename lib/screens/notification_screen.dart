import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../services/campus_tools.dart';
import '../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  List<CampusNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;
  int _lastRevision = -1;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<ChatProvider>(context);
    if (_lastRevision != -1 && provider.realtimeRevision > _lastRevision) {
      _loadNotifications();
    }
    _lastRevision = provider.realtimeRevision;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      final student = provider.currentStudent;
      if (student == null) return;

      final notifs = await CampusTools.getNotificationsAsync(student.id);
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _isLoading = false;
        });
        _animController.reset();
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load notifications. Pull down to retry.';
        });
      }
    }
  }

  Future<void> _markAsRead(CampusNotification notif) async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final student = provider.currentStudent;
    if (student == null) return;

    await CampusTools.markNotificationReadAsync(student.id, notif.id);
    provider.invalidateCache();
    setState(() => notif.read = true);
  }

  Future<void> _markAllRead() async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final student = provider.currentStudent;
    if (student == null) return;

    await CampusTools.markAllNotificationsReadAsync(student.id);
    provider.invalidateCache();
    setState(() {
      for (var n in _notifications) {
        n.read = true;
      }
    });
  }

  // ── Date grouping ───────────────────────────────────────────
  Map<String, List<CampusNotification>> _groupByDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<CampusNotification>> groups = {};

    for (final n in _notifications) {
      final nDate = DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day);
      String label;
      if (nDate == today) {
        label = 'Today';
      } else if (nDate == yesterday) {
        label = 'Yesterday';
      } else {
        label = 'Earlier';
      }
      groups.putIfAbsent(label, () => []);
      groups[label]!.add(n);
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.read).length;

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
                color: AppColors.accentPink.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_rounded,
                  color: AppColors.accentPink, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Notifications',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 20)),
            if (unread > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unread new',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // ── Live indicator ──
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text('LIVE',
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success)),
              ],
            ),
          ),
          // ── Mark All Read ──
          if (unread > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded,
                  color: AppColors.accentIndigo),
              tooltip: 'Mark all as read',
              onPressed: _markAllRead,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
            onPressed: _loadNotifications,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentPink.withValues(alpha: 0.3),
                  AppColors.accentViolet.withValues(alpha: 0.3),
                  AppColors.accentIndigo.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accentPink))
          : _error != null
              ? _buildErrorState()
              : _notifications.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: AppColors.accentPink,
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, _) {
                          return _buildGroupedList();
                        },
                      ),
                    ),
    );
  }

  // ── Date-grouped list ───────────────────────────────────────
  Widget _buildGroupedList() {
    final groups = _groupByDate();
    final sectionOrder = ['Today', 'Yesterday', 'Earlier'];

    final List<Widget> children = [];
    int globalIndex = 0;

    for (final section in sectionOrder) {
      final items = groups[section];
      if (items == null || items.isEmpty) continue;

      // Section header
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: section == 'Today'
                      ? AppColors.accentIndigo
                      : section == 'Yesterday'
                          ? AppColors.accentViolet
                          : AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                section,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: section == 'Today'
                      ? AppColors.accentIndigo
                      : AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${items.length})',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );

      // Notification cards
      for (final notif in items) {
        final idx = globalIndex++;
        final itemDelay = (idx * 0.06).clamp(0.0, 0.7);
        final itemEnd = (itemDelay + 0.3).clamp(0.0, 1.0);
        final progress = Curves.easeOutCubic.transform(
          ((_animController.value - itemDelay) / (itemEnd - itemDelay))
              .clamp(0.0, 1.0),
        );

        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - progress)),
                child: _buildNotifCard(notif),
              ),
            ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: children,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.textMuted, size: 56),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Retry',
                  style:
                      GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_off_outlined,
              color: AppColors.textMuted, size: 56),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'You\'re all caught up!',
            style:
                GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(CampusNotification notif) {
    final timeFormat = DateFormat('dd MMM, h:mm a');
    final Color accentColor;
    final IconData typeIcon;
    switch (notif.type) {
      case 'due_reminder':
        accentColor = AppColors.warning;
        typeIcon = Icons.account_balance_wallet_rounded;
        break;
      case 'clearance_update':
        accentColor = AppColors.accentTeal;
        typeIcon = Icons.assignment_turned_in_rounded;
        break;
      case 'opportunity':
        accentColor = AppColors.success;
        typeIcon = Icons.star_rounded;
        break;
      case 'alert':
        accentColor = AppColors.error;
        typeIcon = Icons.warning_rounded;
        break;
      case 'retest_update':
        accentColor = AppColors.accentViolet;
        typeIcon = Icons.replay_rounded;
        break;
      case 'profile_update':
        accentColor = AppColors.warning;
        typeIcon = Icons.edit_rounded;
        break;
      default:
        accentColor = AppColors.accentIndigo;
        typeIcon = Icons.notifications_rounded;
    }

    return GestureDetector(
      onTap: () {
        if (!notif.read) _markAsRead(notif);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.read
              ? AppColors.surfaceLight
              : accentColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.read
                ? AppColors.border
                : accentColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: notif.read
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notif.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.message,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeFormat.format(notif.timestamp),
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
