import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/game_score.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/screens/games/marble_game.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';

/// Écran Marble Madness — guide la bille !
class MarbleGameScreen extends ConsumerStatefulWidget {
  final String playerId;
  const MarbleGameScreen({super.key, required this.playerId});

  @override
  ConsumerState<MarbleGameScreen> createState() => _MarbleGameScreenState();
}

class _MarbleGameScreenState extends ConsumerState<MarbleGameScreen>
    with SingleTickerProviderStateMixin {
  late MarbleGame _game;
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  @override
  void initState() {
    super.initState();
    _game = MarbleGame(
      onStateChanged: () => setState(() {}),
      onGameOver: _handleGameOver,
    );
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    // Clavier → force
    double fx = 0, fy = 0;
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyA)) {
      fx -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyD)) {
      fx += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyW)) {
      fy -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyS)) {
      fy += 1;
    }
    _game.setForce(fx, fy);

    _game.update(dt);
  }

  void _handleGameOver(int finalScore) {
    _ticker.stop();
    ref.read(gameScoresProvider.notifier).add(
          GameScore.create(
            memberId: widget.playerId,
            gameType: GameType.marble,
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
          _game.won ? 'Bravo !' : 'Game Over !',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_game.won ? '🔮🎉' : '🔮💥',
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
            if (_game.won)
              Text(
                'Tous les niveaux terminés !',
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
      _game = MarbleGame(
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
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          'Marble Madness',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF16213E),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoLabel('Score', '${_game.score}'),
                  _infoLabel(
                      'Niveau', '${_game.currentLevel + 1}/${MarbleGame.levels.length}'),
                  _infoLabel('Temps', '${_game.timer.toInt()}s'),
                ],
              ),
            ),
            // Zone de jeu isométrique
            Expanded(
              child: GestureDetector(
                onPanUpdate: (details) {
                  // Contrôle tactile : glisser pour diriger la bille
                  _game.setForce(
                    details.delta.dx / 10,
                    details.delta.dy / 10,
                  );
                },
                onPanEnd: (_) => _game.setForce(0, 0),
                child: CustomPaint(
                  painter: MarblePainter(_game),
                  size: Size.infinite,
                ),
              ),
            ),
            // Contrôles tactiles
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF16213E),
              child: Column(
                children: [
                  // Haut
                  _dirButton(Icons.arrow_upward, 0, -1),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _dirButton(Icons.arrow_back, -1, 0),
                      const SizedBox(width: 52),
                      _dirButton(Icons.arrow_forward, 1, 0),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _dirButton(Icons.arrow_downward, 0, 1),
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
          style: GoogleFonts.nunito(fontSize: 11, color: Colors.grey),
        ),
        Text(
          value,
          style: GoogleFonts.quicksand(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _dirButton(IconData icon, double fx, double fy) {
    return GestureDetector(
      onTapDown: (_) => _game.setForce(fx, fy),
      onTapUp: (_) => _game.setForce(0, 0),
      onTapCancel: () => _game.setForce(0, 0),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A4A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF444466)),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
