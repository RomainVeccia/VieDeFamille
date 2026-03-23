import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/screens/family_view_screen.dart';
import 'package:vie_de_famille/ui/screens/tasks_screen.dart';
import 'package:vie_de_famille/ui/screens/calendar_screen.dart';
import 'package:vie_de_famille/ui/screens/messages_screen.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';
import 'package:vie_de_famille/ui/widgets/member_avatar.dart';

/// Écran principal — navigation bottom tabs + dashboard
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(onNavigate: (i) => setState(() => _currentIndex = i)),
          const TasksScreen(),
          const CalendarScreen(),
          const MessagesScreen(),
          const FamilyViewScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            activeIcon: Icon(Icons.check_circle),
            label: 'Tâches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Planning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Onglet dashboard — résumé de la journée
class _DashboardTab extends ConsumerWidget {
  final ValueChanged<int> onNavigate;

  const _DashboardTab({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMember = ref.watch(currentMemberDataProvider);
    final members = ref.watch(membersProvider);
    final todayTasks = ref.watch(todayTasksProvider);
    final events = ref.watch(eventsProvider);
    final messages = ref.watch(messagesProvider);

    // Événements du jour
    final now = DateTime.now();
    final todayEvents = events.where((e) => e.isOnDay(now)).toList();

    // Tâches terminées aujourd'hui
    final doneToday = todayTasks.where((t) => t.completed).length;

    final greeting = currentMember != null
        ? 'Bonjour ${currentMember.name} !'
        : 'Bonjour !';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'VieDeFamille',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Salutation
            Text(
              greeting,
              style: GoogleFonts.quicksand(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE d MMMM', 'fr_FR').format(now),
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Avatars famille (scroll horizontal)
            if (members.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final m = members[index];
                    return MemberAvatar(
                      member: m,
                      size: 52,
                      showName: true,
                      showPoints: true,
                      onTap: () => onNavigate(4),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Carte tâches du jour
            _buildSummaryCard(
              icon: Icons.check_circle_outline,
              title: 'Tâches du jour',
              subtitle: todayTasks.isEmpty
                  ? 'Aucune tâche pour aujourd\'hui'
                  : '$doneToday/${todayTasks.length} terminées',
              color: AppTheme.primary,
              onTap: () => onNavigate(1),
            ),
            const SizedBox(height: 12),

            // Carte événements du jour
            _buildSummaryCard(
              icon: Icons.calendar_today,
              title: 'Événements',
              subtitle: todayEvents.isEmpty
                  ? 'Aucun événement prévu'
                  : '${todayEvents.length} événement(s) aujourd\'hui',
              color: AppTheme.secondary,
              onTap: () => onNavigate(2),
            ),
            const SizedBox(height: 12),

            // Carte messages récents
            _buildSummaryCard(
              icon: Icons.chat_bubble_outline,
              title: 'Messages',
              subtitle: messages.isEmpty
                  ? 'Aucun message'
                  : '${messages.length} message(s)',
              color: AppTheme.accent,
              onTap: () => onNavigate(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
