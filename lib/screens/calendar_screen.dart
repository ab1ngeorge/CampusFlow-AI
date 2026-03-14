import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../services/campus_tools.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Map<DateTime, List<_CalendarEvent>> _events;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _events = {};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildEvents();
  }

  void _buildEvents() {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final student = provider.currentStudent;
    if (student == null) return;

    _events = {};

    // Add opportunity deadlines
    final opportunities = CampusTools.listOpportunities(student.id);
    for (final opp in opportunities) {
      final key = DateTime(opp.deadline.year, opp.deadline.month, opp.deadline.day);
      _events.putIfAbsent(key, () => []);
      _events[key]!.add(_CalendarEvent(
        title: opp.title,
        subtitle: '${opp.typeEmoji} Deadline',
        color: AppColors.warning,
        icon: Icons.timer_outlined,
      ));
    }

    // Add payment due dates
    final payments = CampusTools.getPaymentSummary(student.id);
    if (payments.tuitionNextDue != null) {
      final key = DateTime(payments.tuitionNextDue!.year, payments.tuitionNextDue!.month, payments.tuitionNextDue!.day);
      _events.putIfAbsent(key, () => []);
      _events[key]!.add(_CalendarEvent(
        title: 'Tuition Fee Due',
        subtitle: '₹${payments.tuitionBalance.toStringAsFixed(0)} remaining',
        color: AppColors.error,
        icon: Icons.payment_rounded,
      ));
    }
    if (payments.hostelNextDue != null) {
      final key = DateTime(payments.hostelNextDue!.year, payments.hostelNextDue!.month, payments.hostelNextDue!.day);
      _events.putIfAbsent(key, () => []);
      _events[key]!.add(_CalendarEvent(
        title: 'Hostel Fee Due',
        subtitle: '₹${payments.hostelBalance.toStringAsFixed(0)} remaining',
        color: AppColors.accentViolet,
        icon: Icons.home_rounded,
      ));
    }
  }

  List<_CalendarEvent> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : <_CalendarEvent>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Calendar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 120)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: GoogleFonts.inter(color: AppColors.textPrimary),
                weekendTextStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                todayDecoration: BoxDecoration(
                  color: AppColors.accentTeal.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: GoogleFonts.inter(color: AppColors.accentTeal, fontWeight: FontWeight.w700),
                selectedDecoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.accentIndigo, AppColors.accentViolet]),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
                markerDecoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
                markerSize: 6,
                markersMaxCount: 3,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                weekendStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Event List
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(
                          'No events on ${_selectedDay != null ? DateFormat('MMM d').format(_selectedDay!) : 'this day'}',
                          style: GoogleFonts.inter(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: event.color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: event.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(event.icon, color: event.color, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(event.subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CalendarEvent {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  _CalendarEvent({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}
