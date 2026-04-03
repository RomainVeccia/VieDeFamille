import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vie_de_famille/core/models/family_message.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/core/services/budget_service.dart';
import 'package:vie_de_famille/core/services/points_service.dart';
import 'package:vie_de_famille/ui/screens/add_member_screen.dart';
import 'package:vie_de_famille/ui/screens/family_view_screen.dart';
import 'package:vie_de_famille/ui/screens/tasks_screen.dart';
import 'package:vie_de_famille/ui/screens/calendar_screen.dart';
import 'package:vie_de_famille/ui/screens/messages_screen.dart';
import 'package:vie_de_famille/ui/screens/rewards_screen.dart';
import 'package:vie_de_famille/ui/screens/game_selection_screen.dart';
import 'package:vie_de_famille/ui/screens/leaderboard_screen.dart';
import 'package:vie_de_famille/ui/screens/shopping_screen.dart';
import 'package:vie_de_famille/ui/screens/budget_screen.dart';
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
            label: 'Famille',
          ),
        ],
      ),
    );
  }
}

/// Onglet dashboard — grands boutons d'accès rapide
class _DashboardTab extends ConsumerWidget {
  final ValueChanged<int> onNavigate;

  const _DashboardTab({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMember = ref.watch(currentMemberDataProvider);
    final members = ref.watch(membersProvider);
    final todayTasks = ref.watch(todayTasksProvider);
    final allTasks = ref.watch(tasksProvider);
    final events = ref.watch(eventsProvider);
    final messages = ref.watch(messagesProvider);
    final shoppingLists = ref.watch(shoppingListsProvider);
    final shoppingItems = ref.watch(shoppingItemsProvider);
    final expenses = ref.watch(expensesProvider);

    final now = DateTime.now();
    final todayEvents = events.where((e) => e.isOnDay(now)).toList();
    final doneToday = todayTasks.where((t) => t.completed).length;
    final pendingTasks = allTasks.where((t) => !t.completed).length;
    final publicMessages = messages.where((m) => m.isPublic).length;

    final greeting = currentMember != null
        ? 'Bonjour ${currentMember.name} !'
        : 'Bienvenue !';

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
            // Salutation + date
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

            // Avatars famille + bouton ajouter
            if (members.isNotEmpty) ...[
              SizedBox(
                height: 95,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: members.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == members.length) {
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddMemberScreen(),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primary,
                                  width: 2,
                                ),
                                color: AppTheme.primary.withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.person_add,
                                color: AppTheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ajouter',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
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
              const SizedBox(height: 24),
            ],

            // Bouton ajouter un membre si aucun membre
            if (members.isEmpty) ...[
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddMemberScreen(),
                  ),
                ),
                icon: const Icon(Icons.person_add),
                label: const Text('Ajouter un membre'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // === GRANDS BOUTONS D'ACCÈS RAPIDE ===
              Row(
                children: [
                  Expanded(
                    child: _buildBigButton(
                      icon: Icons.calendar_month,
                      title: 'Agenda',
                      subtitle: todayEvents.isEmpty
                          ? 'Aucun événement'
                          : '${todayEvents.length} aujourd\'hui',
                      color: AppTheme.secondary,
                      onTap: () => onNavigate(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBigButton(
                      icon: Icons.check_circle,
                      title: 'Tâches',
                      subtitle: pendingTasks == 0
                          ? 'Tout est fait !'
                          : '$pendingTasks en attente',
                      color: AppTheme.primary,
                      onTap: () => onNavigate(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Deuxième ligne : 3 boutons
              Row(
                children: [
                  Expanded(
                    child: _buildBigButton(
                      icon: Icons.assignment_outlined,
                      title: 'Requêtes',
                      subtitle: _countPendingRequests(ref) == 0
                          ? 'Aucune requête'
                          : '${_countPendingRequests(ref)} en attente',
                      color: const Color(0xFFE67E22),
                      onTap: () => onNavigate(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBigButton(
                      icon: Icons.chat_bubble,
                      title: 'Messages',
                      subtitle: publicMessages == 0
                          ? 'Aucun message'
                          : '$publicMessages message(s)',
                      color: AppTheme.accent,
                      onTap: () => onNavigate(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Troisième ligne : Courses + Budget
              Row(
                children: [
                  Expanded(
                    child: _buildBigButton(
                      icon: Icons.shopping_cart,
                      title: 'Courses',
                      subtitle: () {
                        final totalLists = shoppingLists.length;
                        if (totalLists == 0) return 'Aucune liste';
                        final pendingItems = shoppingItems
                            .where((i) => !i.checked)
                            .length;
                        return pendingItems == 0
                            ? 'Tout coché !'
                            : '$pendingItems article${pendingItems > 1 ? 's' : ''} restant${pendingItems > 1 ? 's' : ''}';
                      }(),
                      color: const Color(0xFF26A69A),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ShoppingScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBigButton(
                      icon: Icons.account_balance_wallet,
                      title: 'Budget',
                      subtitle: () {
                        final total = BudgetService.totalCurrentMonth(expenses);
                        return total == 0
                            ? 'Ce mois : 0 €'
                            : 'Ce mois : ${total.toStringAsFixed(2)} €';
                      }(),
                      color: const Color(0xFF5C6BC0),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BudgetScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Quatrième ligne : Récompenses + Stats
              Row(
                children: [
                  Expanded(
                    child: _buildBigButton(
                      icon: Icons.emoji_events,
                      title: 'Récompenses',
                      subtitle: '${currentMember?.points ?? 0} pts dispo',
                      color: const Color(0xFFFF8F00),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RewardsScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBigButton(
                      icon: Icons.bar_chart,
                      title: 'Stats',
                      subtitle: todayTasks.isEmpty
                          ? 'Pas de données'
                          : '$doneToday/${todayTasks.length} faites',
                      color: const Color(0xFF7E57C2),
                      onTap: () => _showStats(context, ref),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Cinquième ligne : Chance du jour + Classement
              Row(
                children: [
                  Expanded(
                    child: _buildBigButton(
                      icon: Icons.casino,
                      title: 'Chance du jour',
                      subtitle: 'Jouer !',
                      color: const Color(0xFFE91E63),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const GameSelectionScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBigButton(
                      icon: Icons.leaderboard,
                      title: 'Classement',
                      subtitle: 'Scores jeux',
                      color: const Color(0xFF00BCD4),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const LeaderboardScreen()),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  int _countPendingRequests(WidgetRef ref) {
    final messages = ref.read(messagesProvider);
    final currentMember = ref.read(currentMemberDataProvider);
    if (currentMember == null) return 0;
    return messages
        .where((m) =>
            m.type == MessageType.request &&
            m.recipientId == currentMember.id &&
            !m.done)
        .length;
  }

  Widget _buildBigButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.quicksand(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Affiche un dialogue avec les stats de la famille
  void _showStats(BuildContext context, WidgetRef ref) {
    final members = ref.read(membersProvider);
    final allTasks = ref.read(tasksProvider);
    final completedTasks = allTasks.where((t) => t.completed).length;
    final ranked = PointsService.ranking(members);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Statistiques famille',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats globales
            _statRow('Membres', '${members.length}'),
            _statRow('Tâches créées', '${allTasks.length}'),
            _statRow('Tâches terminées', '$completedTasks'),
            const SizedBox(height: 16),

            // Classement
            Text(
              'Classement',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...ranked.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              final medal = i == 0
                  ? '🥇'
                  : i == 1
                      ? '🥈'
                      : i == 2
                          ? '🥉'
                          : '  ';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(medal, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    MemberAvatar(member: m, size: 32),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.name,
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${m.totalPointsEarned} pts',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(color: AppTheme.textSecondary),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
