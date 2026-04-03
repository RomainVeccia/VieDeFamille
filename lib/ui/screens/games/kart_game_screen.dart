import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/game_score.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/screens/games/kart_game.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';

/// Écran Kart Racing — course pseudo-3D
class KartGameScreen extends ConsumerStatefulWidget {
  final String playerId;
  const KartGameScreen({super.key, required this.playerId});

  @override
  ConsumerState<KartGameScreen> createState() => _KartGameScreenState();
}

class _KartGameScreenState extends ConsumerState<KartGameScreen>
    with SingleTickerProviderStateMixin {
  late KartGame _game;
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  @override
  void initState() {
    super.initState();
    _game = KartGame(
      onStateChanged: () => setState(() {}),
      onGameOver: _handleGameOver,
    );
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    // Clavier
    _game.accelerating =
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
            _pressedKeys.contains(LogicalKeyboardKey.keyW);
    _game.braking_ =
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown) ||
            _pressedKeys.contains(LogicalKeyboardKey.keyS);

    double steer = 0;
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyA)) {
      steer -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyD)) {
      steer += 1;
    }
    _game.steerInput = steer;

    _game.update(dt);
  }

  void _handleGameOver(int finalScore) {
    _ticker.stop();
    ref.read(gameScoresProvider.notifier).add(
          GameScore.create(
            memberId: widget.playerId,
            gameType: GameType.kart,
            score: finalScore,
          ),
        );
    _showGameOverDialog(finalScore);
  }

  void _showGameOverDialog(int finalScore) {
    final rank = _game.playerRank;
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '🏎️',
    };
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          _game.won ? '$medal $rank${rank == 1 ? "er" : "e"} place !' : 'Course terminée',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(medal, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              '$finalScore pts',
              style: GoogleFonts.quicksand(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Temps : ${_game.raceTimer.toInt()}s',
              style: GoogleFonts.nunito(color: AppTheme.textSecondary),
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
      _game = KartGame(
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
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Kart Racing',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFF1A1A1A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoLabel('Position', '${_game.playerRank}/6'),
                  _infoLabel('Tour',
                      '${min(_game.currentLap + 1, _game.totalLaps)}/${_game.totalLaps}'),
                  _infoLabel('Vitesse',
                      '${_game.speed.toInt()} km/h'),
                  _infoLabel('Temps', '${_game.raceTimer.toInt()}s'),
                ],
              ),
            ),
            // Course
            Expanded(
              child: CustomPaint(
                painter: KartPainter(_game),
                size: Size.infinite,
              ),
            ),
            // Contrôles tactiles
            Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFF1A1A1A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Direction gauche/droite
                  Row(
                    children: [
                      _holdButton(Icons.arrow_back, () {
                        _game.steerInput = -1;
                      }, () {
                        _game.steerInput = 0;
                      }),
                      const SizedBox(width: 12),
                      _holdButton(Icons.arrow_forward, () {
                        _game.steerInput = 1;
                      }, () {
                        _game.steerInput = 0;
                      }),
                    ],
                  ),
                  // Accélérer / freiner
                  Row(
                    children: [
                      _holdButton(Icons.speed, () {
                        _game.braking_ = true;
                      }, () {
                        _game.braking_ = false;
                      }, color: const Color(0xFF8B0000)),
                      const SizedBox(width: 12),
                      _holdButton(Icons.local_fire_department, () {
                        _game.accelerating = true;
                      }, () {
                        _game.accelerating = false;
                      }, color: const Color(0xFF4CAF50)),
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

  Widget _infoLabel(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(fontSize: 10, color: Colors.grey),
        ),
        Text(
          value,
          style: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _holdButton(IconData icon, VoidCallback onDown, VoidCallback onUp,
      {Color? color}) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color ?? const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF444444)),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
