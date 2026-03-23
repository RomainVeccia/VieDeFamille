import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vie_de_famille/core/models/family_event.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/screens/add_event_screen.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/member_avatar.dart';

/// Écran calendrier — TableCalendar + liste d'événements du jour
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final members = ref.watch(membersProvider);
    final dayEvents = ref.watch(eventsForDayProvider(_selectedDay));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Planning',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Calendrier
          TableCalendar<FamilyEvent>(
            firstDay: DateTime(2024, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            locale: 'fr_FR',
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppTheme.secondary,
                shape: BoxShape.circle,
              ),
              markerSize: 6,
              markersMaxCount: 3,
            ),
            eventLoader: (day) =>
                events.where((e) => e.isOnDay(day)).toList(),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) => _focusedDay = focused,
          ),

          const Divider(height: 1),

          // Liste des événements du jour sélectionné
          Expanded(
            child: dayEvents.isEmpty
                ? Center(
                    child: Text(
                      'Aucun événement ce jour',
                      style:
                          GoogleFonts.nunito(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: dayEvents.length,
                    itemBuilder: (context, index) {
                      final event = dayEvents[index];
                      final color = AppTheme.memberColors[
                          event.colorIndex % AppTheme.memberColors.length];

                      // Chercher les avatars des participants
                      final participants = members
                          .where((m) =>
                              event.participantIds.contains(m.id))
                          .toList();

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: color, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Titre + heure
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius:
                                          BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: GoogleFonts.nunito(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (!event.allDay)
                                          Text(
                                            _formatTime(event),
                                            style: GoogleFonts.nunito(
                                              fontSize: 12,
                                              color:
                                                  AppTheme.textSecondary,
                                            ),
                                          )
                                        else
                                          Text(
                                            'Toute la journée',
                                            style: GoogleFonts.nunito(
                                              fontSize: 12,
                                              color:
                                                  AppTheme.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // Lieu
                              if (event.location != null &&
                                  event.location!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 14,
                                        color: AppTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      event.location!,
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              // Participants
                              if (participants.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: participants
                                      .map((m) => Padding(
                                            padding:
                                                const EdgeInsets.only(right: 4),
                                            child: MemberAvatar(
                                                member: m, size: 28),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddEventScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatTime(FamilyEvent event) {
    final start = DateFormat('HH:mm').format(event.dateStart);
    if (event.dateEnd != null) {
      final end = DateFormat('HH:mm').format(event.dateEnd!);
      return '$start - $end';
    }
    return start;
  }
}
