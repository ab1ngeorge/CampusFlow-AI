import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../services/campus_tools.dart';
import '../theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  PaymentSummary? _summary;
  DuesRecord? _dues;
  bool _isLoading = true;
  String? _error;

  late AnimationController _animController;
  late List<Animation<double>> _sectionAnims;

  final _currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    // 4 sections staggered
    _sectionAnims = List.generate(4, (i) {
      final start = (i * 0.15).clamp(0.0, 0.6);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _animController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final provider = Provider.of<ChatProvider>(context, listen: false);
      final student = provider.currentStudent;
      if (student == null) return;

      final summary = await CampusTools.getPaymentSummaryAsync(student.id);
      final dues = await CampusTools.checkDuesAsync(student.id);

      if (mounted) {
        setState(() {
          _summary = summary;
          _dues = dues;
          _isLoading = false;
        });
        _animController.reset();
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load payment data. Pull down to retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Payments',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.3),
                  AppColors.accentTeal.withValues(alpha: 0.3),
                  AppColors.accentIndigo.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.success))
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.success,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _slideUpSection(0, _buildOutstandingCard()),
                        const SizedBox(height: 24),
                        _slideUpSection(1, Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Due Reminders', Icons.alarm_rounded, AppColors.warning),
                            const SizedBox(height: 12),
                            _buildDueReminders(),
                          ],
                        )),
                        const SizedBox(height: 24),
                        _slideUpSection(2, Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Category Breakdown', Icons.pie_chart_rounded, AppColors.accentIndigo),
                            const SizedBox(height: 12),
                            _buildCategoryBreakdown(),
                          ],
                        )),
                        const SizedBox(height: 24),
                        _slideUpSection(3, Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Payment History', Icons.history_rounded, AppColors.accentTeal),
                            const SizedBox(height: 12),
                            _buildPaymentHistory(),
                          ],
                        )),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _slideUpSection(int index, Widget child) {
    return AnimatedBuilder(
      animation: _sectionAnims[index],
      builder: (context, _) {
        final value = _sectionAnims[index].value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, color: AppColors.textMuted, size: 56),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 1. OUTSTANDING OVERVIEW
  // ═══════════════════════════════════════════════════════════════
  Widget _buildOutstandingCard() {
    final total = _summary?.totalOutstanding ?? 0;
    final hasDues = _dues?.hasDues ?? false;
    final clearanceReady = !hasDues;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: clearanceReady
              ? [const Color(0xFF065F46), const Color(0xFF064E3B)]
              : [const Color(0xFF7C2D12), const Color(0xFF78350F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (clearanceReady ? AppColors.success : AppColors.warning)
                .withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Total Outstanding',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (clearanceReady ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (clearanceReady ? AppColors.success : AppColors.warning)
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      clearanceReady ? Icons.verified_rounded : Icons.warning_rounded,
                      size: 14,
                      color: clearanceReady ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      clearanceReady ? 'Clearance Ready' : 'Dues Pending',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: clearanceReady ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currencyFormat.format(total),
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            clearanceReady
                ? '✅ All dues cleared — you\'re eligible for clearance!'
                : '⚠️ Clear outstanding dues to proceed with clearance.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. DUE REMINDERS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDueReminders() {
    final reminders = <_DueReminder>[];

    if (_summary != null) {
      if (_summary!.tuitionBalance > 0 && _summary!.tuitionNextDue != null) {
        reminders.add(_DueReminder(
          label: 'Tuition Fee',
          amount: _summary!.tuitionBalance,
          dueDate: _summary!.tuitionNextDue!,
          icon: Icons.school_rounded,
          color: AppColors.accentIndigo,
        ));
      }
      if (_summary!.hostelBalance > 0 && _summary!.hostelNextDue != null) {
        reminders.add(_DueReminder(
          label: 'Hostel Payment',
          amount: _summary!.hostelBalance,
          dueDate: _summary!.hostelNextDue!,
          icon: Icons.apartment_rounded,
          color: AppColors.accentTeal,
        ));
      }
      if (_summary!.libraryFines > 0) {
        reminders.add(_DueReminder(
          label: 'Library Fine',
          amount: _summary!.libraryFines,
          dueDate: DateTime.now(),
          icon: Icons.menu_book_rounded,
          color: AppColors.warning,
        ));
      }
      if (_summary!.labFees > 0) {
        reminders.add(_DueReminder(
          label: 'Lab Penalty',
          amount: _summary!.labFees,
          dueDate: DateTime.now(),
          icon: Icons.science_rounded,
          color: AppColors.error,
        ));
      }
    }

    if (reminders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('All clear!',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success)),
                  const SizedBox(height: 2),
                  Text('You have no upcoming or overdue payments.',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: reminders.map((r) => _buildDueReminderCard(r)).toList(),
    );
  }

  Widget _buildDueReminderCard(_DueReminder reminder) {
    final now = DateTime.now();
    final daysLeft = reminder.dueDate.difference(now).inDays;
    final isOverdue = daysLeft < 0;
    final isUrgent = daysLeft <= 7 && daysLeft >= 0;

    final Color badgeColor = isOverdue
        ? AppColors.error
        : (isUrgent ? AppColors.warning : AppColors.textMuted);
    final String badgeText = isOverdue
        ? 'OVERDUE'
        : (daysLeft == 0 ? 'DUE TODAY' : 'Due in $daysLeft days');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppColors.error.withValues(alpha: 0.06)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: reminder.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(reminder.icon, color: reminder.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.label,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Due: ${_dateFormat.format(reminder.dueDate)}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_currencyFormat.format(reminder.amount),
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badgeText,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. CATEGORY BREAKDOWN
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCategoryBreakdown() {
    if (_summary == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCategoryCard('Tuition', Icons.school_rounded, AppColors.accentIndigo, _summary!.tuitionPaid, _summary!.tuitionBalance, _summary!.tuitionNextDue)),
            const SizedBox(width: 12),
            Expanded(child: _buildCategoryCard('Hostel', Icons.apartment_rounded, AppColors.accentTeal, _summary!.hostelPaid, _summary!.hostelBalance, _summary!.hostelNextDue)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildCategoryCard('Library Fines', Icons.menu_book_rounded, AppColors.warning, 0, _summary!.libraryFines, null)),
            const SizedBox(width: 12),
            Expanded(child: _buildCategoryCard('Lab Fees', Icons.science_rounded, AppColors.error, 0, _summary!.labFees, null)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color, double paid, double balance, DateTime? nextDue) {
    final total = paid + balance;
    final progress = total > 0 ? paid / total : 1.0;
    final isClear = balance == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              if (isClear)
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text('Balance: ${_currencyFormat.format(balance)}',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: balance > 0 ? AppColors.warning : AppColors.success)),
          if (paid > 0) ...[
            const SizedBox(height: 2),
            Text('Paid: ${_currencyFormat.format(paid)}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          ],
          if (nextDue != null) ...[
            const SizedBox(height: 4),
            Text('Next: ${_dateFormat.format(nextDue)}', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. PAYMENT HISTORY TIMELINE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPaymentHistory() {
    final history = _summary?.paymentHistory ?? [];

    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 10),
            Text('No payment records yet',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(history.length, (index) {
        final record = history[index];
        final isLast = index == history.length - 1;
        return _buildTimelineItem(record, isLast);
      }),
    );
  }

  Widget _buildTimelineItem(PaymentRecord record, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.type, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(_dateFormat.format(record.date), style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text('Receipt: ${record.receiptId}', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_currencyFormat.format(record.amount),
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _DueReminder {
  final String label;
  final double amount;
  final DateTime dueDate;
  final IconData icon;
  final Color color;

  _DueReminder({
    required this.label,
    required this.amount,
    required this.dueDate,
    required this.icon,
    required this.color,
  });
}
