import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vie_de_famille/core/models/game_score.dart';
import 'package:vie_de_famille/core/providers.dart';
import 'package:vie_de_famille/ui/screens/games/lemmings_game.dart';

class LemmingsGameScreen extends ConsumerStatefulWidget {
  final String playerId;
  const LemmingsGameScreen({super.key, required this.playerId});

  @override
  ConsumerState<LemmingsGameScreen> createState() => _LemmingsGameScreenState();
}

class _LemmingsGameScreenState extends ConsumerState<LemmingsGameScreen>
    with SingleTickerProviderStateMixin {
  late LemmingsGame _g;
  late Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _g = LemmingsGame(onChanged: () => setState(() {}), onOver: _onOver);
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration e) {
    final dt = (e - _last).inMicroseconds / 1e6;
    _last = e;
    _g.update(dt);
  }

  void _onOver(int score) {
    _ticker.stop();
    ref.read(gameScoresProvider.notifier).add(
      GameScore.create(memberId: widget.playerId, gameType: GameType.lemmings, score: score));
    _dlg(score);
  }

  void _dlg(int score) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF000038),
        title: Text(_g.won ? 'Bravo !' : 'Game Over',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_g.won ? '🎉' : '💀', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('$score pts', style: GoogleFonts.quicksand(fontSize: 32,
            fontWeight: FontWeight.bold, color: const Color(0xFF44FF44))),
          const SizedBox(height: 4),
          Text('${_g.saved} sauvés / ${_g.need} requis',
            style: GoogleFonts.nunito(color: Colors.white70)),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.of(ctx).pop(); _restart(); },
            child: const Text('Rejouer', style: TextStyle(color: Color(0xFF44FF44)))),
          TextButton(onPressed: () { Navigator.of(ctx).pop(); Navigator.of(context).pop(); },
            child: const Text('Quitter', style: TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  void _restart() {
    setState(() {
      _last = Duration.zero;
      _g = LemmingsGame(onChanged: () => setState(() {}), onOver: _onOver);
      _ticker.stop();
      _ticker = createTicker(_tick)..start();
    });
  }

  @override
  void dispose() { _ticker.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000022),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000038),
        title: Text('Lemmings', style: GoogleFonts.quicksand(
          fontWeight: FontWeight.bold, color: const Color(0xFF44FF44))),
        iconTheme: const IconThemeData(color: Color(0xFF44FF44)),
      ),
      body: Column(children: [
        // HUD
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          color: const Color(0xFF000038),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _hud('OUT ${_g.spawned - _g.saved - _g.dead}'),
            _hud('IN ${_g.saved}/${_g.need}'),
            _hud('LV ${_g.lvl + 1}/5'),
            _hud('${_g.timer.toInt()}s'),
          ]),
        ),

        // Jeu
        Expanded(child: LayoutBuilder(builder: (ctx, box) {
          return GestureDetector(
            onTapDown: (d) {
              _g.assign(
                d.localPosition.dx / box.maxWidth * LemmingsGame.W,
                d.localPosition.dy / box.maxHeight * LemmingsGame.H);
            },
            child: CustomPaint(painter: LemmingsPainter(_g),
              size: Size(box.maxWidth, box.maxHeight)),
          );
        })),

        // Skills
        Container(
          color: const Color(0xFF000038),
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _sk(LemmingSkill.climber, '🧗', 'Climb'),
                _sk(LemmingSkill.floater, '☂️', 'Float'),
                _sk(LemmingSkill.bomber, '💣', 'Bomb'),
                _sk(LemmingSkill.blocker, '✋', 'Block'),
                _sk(LemmingSkill.builder, '🔨', 'Build'),
                _sk(LemmingSkill.basher, '⛏️', 'Bash'),
                _sk(LemmingSkill.miner, '⚒️', 'Mine'),
                _sk(LemmingSkill.digger, '🕳️', 'Dig'),
              ]),
            ),
            const SizedBox(height: 3),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _btn('−', () => _g.slower()),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('Rate', style: GoogleFonts.nunito(color: Colors.white38, fontSize: 10))),
              _btn('+', () => _g.faster()),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _g.nuke(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF770000), borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.red)),
                  child: Text('☢ NUKE', style: GoogleFonts.quicksand(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _hud(String t) => Text(t, style: GoogleFonts.quicksand(
    color: const Color(0xFF44FF44), fontSize: 12, fontWeight: FontWeight.bold));

  Widget _sk(LemmingSkill skill, String emoji, String label) {
    final n = _g.sk[skill] ?? 0;
    final sel = _g.selSkill == skill;
    final dis = n <= 0;
    return GestureDetector(
      onTap: dis ? null : () => setState(() {
        _g.selSkill = sel ? LemmingSkill.none : skill;
      }),
      child: Container(
        width: 46, margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF005500)
              : dis ? const Color(0xFF0A0A25) : const Color(0xFF1A1A45),
          borderRadius: BorderRadius.circular(5),
          border: sel ? Border.all(color: const Color(0xFF44FF44), width: 2) : null),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          Text('$n', style: GoogleFonts.quicksand(fontSize: 10,
            fontWeight: FontWeight.bold, color: dis ? Colors.grey : const Color(0xFF44FF44))),
        ]),
      ),
    );
  }

  Widget _btn(String t, VoidCallback f) => GestureDetector(
    onTap: f,
    child: Container(
      width: 28, height: 24,
      decoration: BoxDecoration(color: const Color(0xFF1A1A45),
        borderRadius: BorderRadius.circular(3), border: Border.all(color: const Color(0xFF333366))),
      alignment: Alignment.center,
      child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
    ),
  );
}
