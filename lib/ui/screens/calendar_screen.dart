import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vie_de_famille/core/models/family_event.dart';
import 'package:vie_de_famille/core/models/member.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/screens/add_event_screen.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/member_avatar.dart';

enum _CalendarView { day, week, month }

/// Écran calendrier — 3 vues : Jour / Semaine / Mois
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  _CalendarView _view = _CalendarView.month;

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final members = ref.watch(membersProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Planning',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        actions: [
          // Toggle Jour / Semaine / Mois
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<_CalendarView>(
              style: SegmentedButton.styleFrom(
                backgroundColor: AppTheme.background,
                selectedBackgroundColor: AppTheme.primary,
                selectedForegroundColor: Colors.white,
                foregroundColor: AppTheme.textSecondary,
                textStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              segments: const [
                ButtonSegment(value: _CalendarView.day,   label: Text('Jour')),
                ButtonSegment(value: _CalendarView.week,  label: Text('Sem.')),
                ButtonSegment(value: _CalendarView.month, label: Text('Mois')),
              ],
              selected: {_view},
              onSelectionChanged: (s) => setState(() => _view = s.first),
            ),
          ),
        ],
      ),
      body: switch (_view) {
        _CalendarView.day   => _DayView(selectedDay: _selectedDay, members: members, events: events,
            onDayChanged: (d) => setState(() => _selectedDay = d)),
        _CalendarView.week  => _WeekView(selectedDay: _selectedDay, focusedDay: _focusedDay, members: members, events: events,
            onDaySelected: (s, f) => setState(() { _selectedDay = s; _focusedDay = f; }),
            onPageChanged: (f) => setState(() => _focusedDay = f)),
        _CalendarView.month => _MonthView(selectedDay: _selectedDay, focusedDay: _focusedDay, members: members, events: events,
            onDaySelected: (s, f) => setState(() { _selectedDay = s; _focusedDay = f; }),
            onPageChanged: (f) => setState(() => _focusedDay = f)),
      },
      floatingActionButton: FloatingActionButton(
        heroTag: 'addEvent',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEventScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================
// VUE MOIS
// ============================================================

class _MonthView extends StatelessWidget {
  final DateTime selectedDay, focusedDay;
  final List<Member> members;
  final List<FamilyEvent> events;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(DateTime) onPageChanged;

  const _MonthView({
    required this.selectedDay, required this.focusedDay,
    required this.members, required this.events,
    required this.onDaySelected, required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dayEvents = events.where((e) => e.isOnDay(selectedDay)).toList();

    return Column(
      children: [
        TableCalendar<FamilyEvent>(
          firstDay: DateTime(2024, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          locale: 'fr_FR',
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: GoogleFonts.quicksand(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.3), shape: BoxShape.circle),
            selectedDecoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            markerDecoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
            markerSize: 6,
            markersMaxCount: 3,
          ),
          eventLoader: (day) => events.where((e) => e.isOnDay(day)).toList(),
          onDaySelected: onDaySelected,
          onPageChanged: onPageChanged,
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Text(
                DateFormat('EEEE d MMMM', 'fr_FR').format(selectedDay),
                style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 8),
              if (dayEvents.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(color: AppTheme.secondary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Text('${dayEvents.length}', style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        Expanded(child: _EventList(events: dayEvents, members: members)),
      ],
    );
  }
}

// ============================================================
// VUE SEMAINE
// ============================================================

class _WeekView extends StatelessWidget {
  final DateTime selectedDay, focusedDay;
  final List<Member> members;
  final List<FamilyEvent> events;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(DateTime) onPageChanged;

  const _WeekView({
    required this.selectedDay, required this.focusedDay,
    required this.members, required this.events,
    required this.onDaySelected, required this.onPageChanged,
  });

  List<DateTime> _weekDays(DateTime day) {
    final monday = day.subtract(Duration(days: day.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final days = _weekDays(selectedDay);
    final dayEvents = events.where((e) => e.isOnDay(selectedDay)).toList();

    return Column(
      children: [
        TableCalendar<FamilyEvent>(
          firstDay: DateTime(2024, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          calendarFormat: CalendarFormat.week,
          startingDayOfWeek: StartingDayOfWeek.monday,
          locale: 'fr_FR',
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: GoogleFonts.quicksand(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.3), shape: BoxShape.circle),
            selectedDecoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            markerDecoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
            markerSize: 6,
            markersMaxCount: 3,
          ),
          eventLoader: (day) => events.where((e) => e.isOnDay(day)).toList(),
          onDaySelected: onDaySelected,
          onPageChanged: onPageChanged,
        ),
        const Divider(height: 1),
        // Résumé de la semaine — points colorés par jour
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: days.map((d) {
              final count = events.where((e) => e.isOnDay(d)).length;
              final isSelected = isSameDay(d, selectedDay);
              final isToday = isSameDay(d, DateTime.now());
              return GestureDetector(
                onTap: () => onDaySelected(d, d),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : isToday ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('E', 'fr_FR').format(d),
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withValues(alpha: 0.3) : AppTheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('$count', style: GoogleFonts.nunito(fontSize: 10, color: isSelected ? Colors.white : Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              DateFormat('EEEE d MMMM', 'fr_FR').format(selectedDay),
              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        Expanded(child: _EventList(events: dayEvents, members: members)),
      ],
    );
  }
}

// ============================================================
// VUE JOUR
// ============================================================

class _DayView extends StatelessWidget {
  final DateTime selectedDay;
  final List<Member> members;
  final List<FamilyEvent> events;
  final void Function(DateTime) onDayChanged;

  const _DayView({
    required this.selectedDay,
    required this.members,
    required this.events,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dayEvents = events.where((e) => e.isOnDay(selectedDay)).toList()
      ..sort((a, b) {
        if (a.allDay && !b.allDay) return -1;
        if (!a.allDay && b.allDay) return 1;
        return a.dateStart.compareTo(b.dateStart);
      });

    final isToday = isSameDay(selectedDay, DateTime.now());

    return Column(
      children: [
        // Navigation jour
        Container(
          color: AppTheme.cardColor,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onDayChanged(selectedDay.subtract(const Duration(days: 1))),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onDayChanged(DateTime.now()),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEEE', 'fr_FR').format(selectedDay),
                        style: GoogleFonts.nunito(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('d MMMM yyyy', 'fr_FR').format(selectedDay),
                            style: GoogleFonts.quicksand(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isToday ? AppTheme.primary : AppTheme.textPrimary,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                              child: Text('Aujourd\'hui', style: GoogleFonts.nunito(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onDayChanged(selectedDay.add(const Duration(days: 1))),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: dayEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('Aucun événement ce jour',
                          style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 15)),
                      const SizedBox(height: 8),
                      Text('Appuie sur + pour en créer un',
                          style: GoogleFonts.nunito(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Toute la journée en premier
                    if (dayEvents.any((e) => e.allDay)) ...[
                      Text('Toute la journée',
                          style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      ...dayEvents.where((e) => e.allDay).map((e) => _EventCard(event: e, members: members)),
                      const SizedBox(height: 12),
                    ],
                    // Événements horaires
                    if (dayEvents.any((e) => !e.allDay)) ...[
                      Text('Horaires',
                          style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      ...dayEvents.where((e) => !e.allDay).map((e) => _EventCard(event: e, members: members, showTime: true)),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

// ============================================================
// COMPOSANTS PARTAGÉS
// ============================================================

class _EventList extends StatelessWidget {
  final List<FamilyEvent> events;
  final List<Member> members;

  const _EventList({required this.events, required this.members});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Text('Aucun événement ce jour',
            style: GoogleFonts.nunito(color: AppTheme.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (_, i) => _EventCard(event: events[i], members: members, showTime: true),
    );
  }
}

class _EventCard extends StatelessWidget {
  final FamilyEvent event;
  final List<Member> members;
  final bool showTime;

  const _EventCard({required this.event, required this.members, this.showTime = false});

  String _formatTime(FamilyEvent e) {
    final start = DateFormat('HH:mm').format(e.dateStart);
    if (e.dateEnd != null) return '$start – ${DateFormat('HH:mm').format(e.dateEnd!)}';
    return start;
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.memberColors[event.colorIndex % AppTheme.memberColors.length];
    final participants = members.where((m) => event.participantIds.contains(m.id)).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 4, height: 36,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(event.title,
                                style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                          if (event.recurrence != EventRecurrence.none) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: AppTheme.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(event.recurrence.shortLabel,
                                  style: GoogleFonts.nunito(fontSize: 10, color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        event.allDay ? 'Toute la journée' : (showTime ? _formatTime(event) : ''),
                        style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (event.location != null && event.location!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(event.location!, style: GoogleFonts.nunito(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
            ],
            if (participants.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: participants.map((m) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: MemberAvatar(member: m, size: 28),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
