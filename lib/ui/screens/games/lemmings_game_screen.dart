import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/game_score.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/screens/games/lemmings_game.dart';

/// Écran Lemmings — fidèle à l'original !
class LemmingsGameScreen extends ConsumerStatefulWidget {
  final String playerId;
  const LemmingsGameScreen({super.key, required this.playerId});

  @override
  ConsumerState<LemmingsGameScreen> createState() =>
      _LemmingsGameScreenState();
}

class _LemmingsGameScreenState extends ConsumerState<LemmingsGameScreen>
    with SingleTickerProviderStateMixin {
  late LemmingsGame _game;
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _game = LemmingsGame(
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
    ref.read(gameScoresProvider.notifier).add(
          GameScore.create(
            memberId: widget.playerId,
            gameType: GameType.lemmings,
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
        backgroundColor: const Color(0xFF000044),
        title: Text(
          _game.won ? 'Bravo !' : 'Game Over',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _game.won ? '🎉' : '💀',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              '$finalScore pts',
              style: GoogleFonts.quicksand(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF44FF44),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_game.saved} sauvés sur ${_game.required_} requis',
              style: GoogleFonts.nunito(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _restart();
            },
            child: const Text('Rejouer',
                style: TextStyle(color: Color(0xFF44FF44))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Quitter',
                style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _restart() {
    setState(() {
      _lastElapsed = Duration.zero;
      _game = LemmingsGame(
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000022),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000044),
        title: Text(
          'Lemmings',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF44FF44),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF44FF44)),
      ),
      body: Column(
        children: [
          // HUD supérieur — comme l'original
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: const Color(0xFF000044),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _hudText('OUT ${_game.spawned - _game.saved - _game.dead}'),
                _hudText('IN ${_game.saved}'),
                _hudText('NEED ${_game.required_}'),
                _hudText('Niv. ${_game.currentLevel + 1}'),
                _hudText('${_game.timer.toInt()}s'),
              ],
            ),
          ),

          // Zone de jeu
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    // Convertir tap en coordonnées terrain
                    final tapX = details.localPosition.dx /
                        constraints.maxWidth *
                        LemmingsGame.terrainW;
                    final tapY = details.localPosition.dy /
                        constraints.maxHeight *
                        LemmingsGame.terrainH;
                    _game.assignSkill(tapX, tapY);
                  },
                  child: CustomPaint(
                    painter: LemmingsPainter(_game),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                );
              },
            ),
          ),

          // Barre de compétences — style original
          Container(
            color: const Color(0xFF000044),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                // Les 8 compétences
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _skillBtn(LemmingSkill.climber, '🧗', 'Climb'),
                      _skillBtn(LemmingSkill.floater, '☂️', 'Float'),
                      _skillBtn(LemmingSkill.bomber, '💣', 'Bomb'),
                      _skillBtn(LemmingSkill.blocker, '✋', 'Block'),
                      _skillBtn(LemmingSkill.builder, '🔨', 'Build'),
                      _skillBtn(LemmingSkill.basher, '⛏️', 'Bash'),
                      _skillBtn(LemmingSkill.miner, '⚒️', 'Mine'),
                      _skillBtn(LemmingSkill.digger, '🕳️', 'Dig'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Contrôles : rate + nuke
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ctrlBtn('−', () => _game.decreaseRate()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Rate',
                        style: GoogleFonts.nunito(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    _ctrlBtn('+', () => _game.increaseRate()),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () => _game.nuke(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF880000),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Text(
                          '☢ NUKE',
                          style: GoogleFonts.quicksand(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _hudText(String text) {
    return Text(
      text,
      style: GoogleFonts.quicksand(
        color: const Color(0xFF44FF44),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _skillBtn(LemmingSkill skill, String emoji, String label) {
    final count = _game.skills[skill] ?? 0;
    final selected = _game.selectedSkill == skill;
    final disabled = count <= 0;

    return GestureDetector(
      onTap: disabled
          ? null
          : () => setState(() {
                _game.selectedSkill = selected ? LemmingSkill.none : skill;
              }),
      child: Container(
        width: 48,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF006600)
              : disabled
                  ? const Color(0xFF111133)
                  : const Color(0xFF222255),
          borderRadius: BorderRadius.circular(6),
          border: selected
              ? Border.all(color: const Color(0xFF44FF44), width: 2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            Text(
              '$count',
              style: GoogleFonts.quicksand(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: disabled ? Colors.grey : const Color(0xFF44FF44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctrlBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF222255),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF444477)),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
