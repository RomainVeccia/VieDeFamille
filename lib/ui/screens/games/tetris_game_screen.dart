import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/game_score.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/screens/games/tetris_game.dart';
import 'package:vie_de_famille/ui/theme/app_theme.dart';

/// Écran Tetris — wrapper avec contrôles et score
class TetrisGameScreen extends ConsumerStatefulWidget {
  final String playerId;
  const TetrisGameScreen({super.key, required this.playerId});

  @override
  ConsumerState<TetrisGameScreen> createState() => _TetrisGameScreenState();
}

class _TetrisGameScreenState extends ConsumerState<TetrisGameScreen>
    with SingleTickerProviderStateMixin {
  late TetrisGame _game;
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _game = TetrisGame(
      onStateChanged: () => setState(() {}),
      onGameOver: _handleGameOver,
    );
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    _game.update(dt);
  }

  void _handleGameOver(int finalScore) {
    _ticker.stop();
    // Sauvegarder le score du joueur sélectionné
    ref.read(gameScoresProvider.notifier).add(
          GameScore.create(
            memberId: widget.playerId,
            gameType: GameType.tetris,
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
          'Game Over !',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧱', style: TextStyle(fontSize: 48)),
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
              'Niveau ${_game.level} — ${_game.linesCleared} lignes',
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
      _game = TetrisGame(
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

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _game.moveLeft();
      case LogicalKeyboardKey.arrowRight:
        _game.moveRight();
      case LogicalKeyboardKey.arrowUp:
        _game.rotate();
      case LogicalKeyboardKey.arrowDown:
        _game.softDrop();
      case LogicalKeyboardKey.space:
        _game.hardDrop();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Tetris',
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
        onKeyEvent: _handleKey,
        child: Column(
          children: [
            // Score / Level / Next
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1A1A1A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoLabel('Score', '${_game.score}'),
                  _infoLabel('Niveau', '${_game.level}'),
                  _infoLabel('Lignes', '${_game.linesCleared}'),
                  // Preview prochaine pièce
                  Column(
                    children: [
                      Text(
                        'Suivant',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CustomPaint(
                          painter: NextPiecePainter(_game),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Plateau de jeu
            Expanded(
              child: GestureDetector(
                onTap: () => _game.rotate(),
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < 0) {
                    _game.moveLeft();
                  } else {
                    _game.moveRight();
                  }
                },
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! > 0) {
                    _game.hardDrop();
                  }
                },
                child: CustomPaint(
                  painter: TetrisPainter(_game),
                  size: Size.infinite,
                ),
              ),
            ),
            // Boutons tactiles
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF1A1A1A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(Icons.arrow_left, _game.moveLeft),
                  _controlButton(Icons.rotate_right, _game.rotate),
                  _controlButton(Icons.arrow_drop_down, _game.softDrop),
                  _controlButton(Icons.keyboard_double_arrow_down,
                      _game.hardDrop),
                  _controlButton(Icons.arrow_right, _game.moveRight),
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

  Widget _controlButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF444444)),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
