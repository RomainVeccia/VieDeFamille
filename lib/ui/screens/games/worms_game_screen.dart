import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/game_score.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/screens/games/worms_game.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';

/// Écran Worms — artillerie tour par tour !
class WormsGameScreen extends ConsumerStatefulWidget {
  final String playerId;
  const WormsGameScreen({super.key, required this.playerId});

  @override
  ConsumerState<WormsGameScreen> createState() => _WormsGameScreenState();
}

class _WormsGameScreenState extends ConsumerState<WormsGameScreen>
    with SingleTickerProviderStateMixin {
  late WormsGame _game;
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  @override
  void initState() {
    super.initState();
    _game = WormsGame(
      onStateChanged: () => setState(() {}),
      onGameOver: _handleGameOver,
    );
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    // Contrôles clavier continus
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      _game.moveLeft(dt);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      _game.moveRight(dt);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      _game.aimUp(dt);
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      _game.aimDown(dt);
    }

    _game.update(dt);
  }

  void _handleGameOver(int finalScore) {
    _ticker.stop();
    ref.read(gameScoresProvider.notifier).add(
          GameScore.create(
            memberId: widget.playerId,
            gameType: GameType.worms,
            score: finalScore,
          ),
        );
    _showGameOverDialog(finalScore);
  }

  void _showGameOverDialog(int finalScore) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          _game.won ? 'Victoire !' : 'Défaite...',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_game.won ? '🪱🎉' : '🪱💀',
                style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              '$finalScore pts',
              style: GoogleFonts.quicksand(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _restart();
            },
            child: const Text('Rejouer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  void _restart() {
    setState(() {
      _lastElapsed = Duration.zero;
      _pressedKeys.clear();
      _game = WormsGame(
        onStateChanged: () => setState(() {}),
        onGameOver: _handleGameOver,
      );
      _ticker.stop();
      _ticker = createTicker(_onTick)..start();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (!_game.charging) {
          _game.startCharge();
        }
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
      if (event.logicalKey == LogicalKeyboardKey.space) {
        _game.fire();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2A2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Worms',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Column(
          children: [
            // HUD
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: const Color(0xFF1A1A1A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _hudLabel(
                    _game.isPlayerTurn ? 'TON TOUR' : 'TOUR IA',
                    _game.isPlayerTurn ? Colors.green : Colors.red,
                  ),
                  _hudText(_game.activeWorm.name),
                  _hudText('Tour: ${_game.turnTimer.toInt()}s'),
                  _hudText('Score: ${_game.score}'),
                ],
              ),
            ),

            // Barre de puissance
            if (_game.charging)
              Container(
                height: 8,
                color: const Color(0xFF1A1A1A),
                child: LinearProgressIndicator(
                  value: _game.power / WormsGame.maxPower,
                  backgroundColor: const Color(0xFF333333),
                  valueColor: AlwaysStoppedAnimation(
                    _game.power < 100 ? Colors.green : Colors.red,
                  ),
                ),
              ),

            // Zone de jeu
            Expanded(
              child: CustomPaint(
                painter: WormsPainter(_game),
                size: Size.infinite,
              ),
            ),

            // Armes + contrôles
            Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFF1A1A1A),
              child: Column(
                children: [
                  // Sélection d'arme
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _weaponBtn(WormWeapon.bazooka, '🚀', 'Bazooka'),
                      _weaponBtn(WormWeapon.grenade, '💣', 'Grenade'),
                      _weaponBtn(WormWeapon.shotgun, '🔫', 'Shotgun'),
                      _weaponBtn(WormWeapon.dynamite, '🧨', 'TNT'),
                      _weaponBtn(WormWeapon.airstrike, '✈️', 'Airstrike'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Contrôles tactiles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Déplacement
                      Row(
                        children: [
                          _ctrlBtn(Icons.arrow_back,
                              () => _game.moveLeft(0.04)),
                          const SizedBox(width: 8),
                          _ctrlBtn(Icons.arrow_forward,
                              () => _game.moveRight(0.04)),
                        ],
                      ),
                      // Visée
                      Row(
                        children: [
                          _ctrlBtn(Icons.arrow_upward,
                              () => _game.aimUp(0.06)),
                          const SizedBox(width: 8),
                          _ctrlBtn(Icons.arrow_downward,
                              () => _game.aimDown(0.06)),
                        ],
                      ),
                      // Tir
                      GestureDetector(
                        onTapDown: (_) => _game.startCharge(),
                        onTapUp: (_) => _game.fire(),
                        onTapCancel: () => _game.fire(),
                        child: Container(
                          width: 60,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _game.charging
                                ? Colors.red
                                : const Color(0xFF4CAF50),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'FEU',
                            style: GoogleFonts.quicksand(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hudText(String text) {
    return Text(
      text,
      style: GoogleFonts.quicksand(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _hudLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: GoogleFonts.quicksand(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _weaponBtn(WormWeapon weapon, String emoji, String name) {
    final selected = _game.selectedWeapon == weapon;
    final count = _game.ammo[weapon] ?? 0;
    return GestureDetector(
      onTap: () => setState(() => _game.selectedWeapon = weapon),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4CAF50)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: selected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            Text(
              count > 90 ? '∞' : '$count',
              style: GoogleFonts.quicksand(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF444444)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
