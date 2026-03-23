import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';

/// Écran d'accueil — dashboard du jour
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'VieDeFamille',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          _buildPlaceholder('Tâches', Icons.check_circle_outline),
          _buildPlaceholder('Planning', Icons.calendar_month),
          _buildPlaceholder('Courses', Icons.shopping_cart_outlined),
          _buildPlaceholder('Budget', Icons.account_balance_wallet_outlined),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            'Bonjour ! 👋',
            style: GoogleFonts.quicksand(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Voici le résumé de la journée',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Cards résumé
          _buildSummaryCard(
            icon: Icons.check_circle_outline,
            title: 'Tâches du jour',
            subtitle: 'Aucune tâche pour le moment',
            color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            icon: Icons.calendar_today,
            title: 'Événements',
            subtitle: 'Aucun événement prévu',
            color: AppTheme.secondary,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            icon: Icons.shopping_cart_outlined,
            title: 'Courses',
            subtitle: 'Aucune liste en cours',
            color: AppTheme.accent,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Budget du mois',
            subtitle: 'Pas encore de dépenses',
            color: AppTheme.budgetPositive,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildPlaceholder(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.quicksand(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bientôt disponible...',
            style: GoogleFonts.nunito(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
