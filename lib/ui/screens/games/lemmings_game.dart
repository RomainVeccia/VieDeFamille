import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// === Compétences ===
enum LemmingSkill {
  none, climber, floater, bomber, blocker, builder, basher, miner, digger,
}

enum LemState {
  walk, fall, climb, build, bash, mine, dig, block, float_, bomb, splat, exit_,
}

class Lemming {
  double x, y;
  int dir; // 1=droite, -1=gauche
  LemmingSkill skill;
  LemState state;
  bool alive, exited;
  double fallDist, frame, bombTimer, cd;
  int buildN;
  bool pClimb, pFloat; // skills permanentes

  Lemming(this.x, this.y, [this.dir = 1])
      : skill = LemmingSkill.none,
        state = LemState.fall,
        alive = true, exited = false,
        fallDist = 0, frame = 0, bombTimer = 5, cd = 0,
        buildN = 0, pClimb = false, pFloat = false;
}

/// Moteur Lemmings haute fidélité
class LemmingsGame {
  static const int W = 400, H = 200;
  late Uint8List ter;       // 0=air, 1=dirt, 2=steel
  late Uint32List terCol;   // couleur ARGB de chaque pixel

  double trapX = 0, trapY = 0, exitX = 0, exitY = 0;
  final List<Lemming> lems = [];
  int toSpawn = 0, spawned = 0, saved = 0, dead = 0, need = 0;
  double spawnT = 0, spawnRate = 1.0;
  final Map<LemmingSkill, int> sk = {};
  LemmingSkill selSkill = LemmingSkill.none;

  int score = 0, lvl = 0;
  bool over = false, won = false, nuked = false;
  double timer = 0, trapAnim = 0;
  bool trapOpen = false;

  final VoidCallback onChanged;
  final void Function(int) onOver;

  LemmingsGame({required this.onChanged, required this.onOver}) {
    _load(0);
  }

  // --- terrain access ---
  int tg(int x, int y) =>
      (x < 0 || x >= W || y < 0 || y >= H) ? 0 : ter[y * W + x];
  void ts(int x, int y, int v, [int? c]) {
    if (x < 0 || x >= W || y < 0 || y >= H) return;
    ter[y * W + x] = v;
    if (c != null) terCol[y * W + x] = c;
  }
  bool sol(int x, int y) => tg(x, y) > 0;
  bool stl(int x, int y) => tg(x, y) == 2;

  void _digC(int cx, int cy, int r) {
    for (int dy = -r; dy <= r; dy++) {
      for (int dx = -r; dx <= r; dx++) {
        if (dx * dx + dy * dy <= r * r && !stl(cx + dx, cy + dy)) {
          ts(cx + dx, cy + dy, 0);
        }
      }
    }
  }

  // --- terrain builders ---
  int _dirtCol(int x, int y) {
    // Palette de terre riche et variée comme l'original
    final n = ((x * 7 + y * 13 + x * y) % 12);
    return switch (n) {
      0 => 0xFF2D7A2D, 1 => 0xFF1E6B1E, 2 => 0xFF338833,
      3 => 0xFF267226, 4 => 0xFF3B953B, 5 => 0xFF2A822A,
      6 => 0xFF347A34, 7 => 0xFF1F721F, 8 => 0xFF2E8E2E,
      9 => 0xFF258525, 10 => 0xFF3A903A, _ => 0xFF2C7C2C,
    };
  }

  int _steelCol(int x, int y) =>
      ((x + y) % 2 == 0) ? 0xFF7788AA : 0xFF6677A0;

  void _rect(int x, int y, int w, int h, int t) {
    for (int dy = 0; dy < h; dy++) {
      for (int dx = 0; dx < w; dx++) {
        final px = x + dx, py = y + dy;
        ts(px, py, t, t == 2 ? _steelCol(px, py) : _dirtCol(px, py));
      }
    }
  }

  /// Colline irrégulière (plus naturel qu'un oval)
  void _hill(int cx, int cy, int rx, int ry, int t) {
    final rng = Random(cx * 100 + cy);
    for (int dy = -ry; dy <= ry; dy++) {
      for (int dx = -rx; dx <= rx; dx++) {
        final noise = (rng.nextDouble() - 0.5) * 0.15;
        final d = (dx * dx) / (rx * rx + 0.1) + (dy * dy) / (ry * ry + 0.1) + noise;
        if (d <= 1.0) {
          final px = cx + dx, py = cy + dy;
          ts(px, py, t, t == 2 ? _steelCol(px, py) : _dirtCol(px, py));
        }
      }
    }
  }

  /// Pilier (colonne verticale)
  void _pillar(int x, int y, int w, int h) => _rect(x, y, w, h, 1);

  /// Pont fin
  void _bridge(int x, int y, int len) => _rect(x, y, len, 3, 1);

  /// Surface herbeuse
  void _grass() {
    for (int x = 0; x < W; x++) {
      for (int y = 1; y < H; y++) {
        if (tg(x, y) == 1 && tg(x, y - 1) == 0) {
          // Surface → herbe vert vif
          final n = (x * 3 + y * 7) % 5;
          final c = switch (n) {
            0 => 0xFF55EE44, 1 => 0xFF44DD33, 2 => 0xFF66FF55,
            3 => 0xFF33CC22, _ => 0xFF4AE83A,
          };
          terCol[y * W + x] = c;
          // Brins d'herbe (1 sur 2)
          if (x % 2 == 0 && y > 1 && tg(x, y - 1) == 0) {
            ts(x, y - 1, 1, 0xFF44DD33);
          }
        }
      }
    }
  }

  // --- Niveaux ---
  void _load(int l) {
    lvl = l;
    ter = Uint8List(W * H);
    terCol = Uint32List(W * H);
    lems.clear();
    spawned = saved = dead = 0;
    spawnT = 0; nuked = false; trapOpen = false; trapAnim = 0;

    switch (l) { case 0: _lv1(); case 1: _lv2(); case 2: _lv3(); }
    _grass();
  }

  // Nv1 — "Just Dig!" : apprendre creuser + basher
  void _lv1() {
    toSpawn = 10; need = 7; timer = 120;
    trapX = 55; trapY = 28; exitX = 340; exitY = 162;
    sk.clear();
    sk[LemmingSkill.digger] = 10;
    sk[LemmingSkill.basher] = 5;
    sk[LemmingSkill.builder] = 3;

    // Grande colline de départ
    _hill(70, 48, 55, 18, 1);
    // Pilier de descente
    _pillar(115, 48, 15, 65);
    // Plateau intermédiaire
    _hill(175, 95, 45, 12, 1);
    // Pont vers la droite
    _bridge(205, 95, 70);
    // Mur épais (il faut basher)
    _rect(275, 72, 12, 30, 1);
    // Plateforme de sortie
    _hill(325, 108, 35, 12, 1);
    // Pilier vers le sol
    _pillar(315, 108, 25, 57);
    // Sol
    _rect(0, 165, W, 35, 1);
    // Acier sous sortie
    _rect(310, 165, 60, 8, 2);
  }

  // Nv2 — "Build to Survive" : construire des ponts au-dessus du vide
  void _lv2() {
    toSpawn = 15; need = 10; timer = 180;
    trapX = 35; trapY = 18; exitX = 365; exitY = 162;
    sk.clear();
    sk[LemmingSkill.builder] = 10;
    sk[LemmingSkill.floater] = 5;
    sk[LemmingSkill.blocker] = 3;
    sk[LemmingSkill.digger] = 4;
    sk[LemmingSkill.miner] = 3;
    sk[LemmingSkill.basher] = 3;

    // Île de départ
    _hill(55, 35, 35, 10, 1);
    // --- Grand gouffre --- (faut construire !)
    // Petite île au milieu du gouffre
    _hill(130, 48, 15, 6, 1);
    // Île flottante 2
    _hill(195, 58, 18, 7, 1);
    // Grande plateforme après le gouffre
    _hill(270, 68, 40, 10, 1);
    // Mur (basher)
    _rect(310, 48, 10, 30, 1);
    // Plateforme finale
    _hill(345, 72, 30, 8, 1);
    // Descente vers sol
    _pillar(345, 72, 15, 93);
    // Sol avec trou mortel
    _rect(0, 165, 110, 35, 1);
    _rect(160, 165, W - 160, 35, 1);
    // Acier sortie
    _rect(340, 165, 60, 8, 2);
  }

  // Nv3 — "The Hard Way" : tout utiliser !
  void _lv3() {
    toSpawn = 20; need = 15; timer = 300;
    trapX = 25; trapY = 12; exitX = 375; exitY = 162;
    sk.clear();
    sk[LemmingSkill.climber] = 4;
    sk[LemmingSkill.floater] = 5;
    sk[LemmingSkill.bomber] = 3;
    sk[LemmingSkill.blocker] = 4;
    sk[LemmingSkill.builder] = 8;
    sk[LemmingSkill.basher] = 5;
    sk[LemmingSkill.miner] = 4;
    sk[LemmingSkill.digger] = 6;

    // Départ haut
    _hill(45, 25, 28, 8, 1);
    // Grand mur (climber ou basher)
    _rect(78, 0, 10, 55, 1);
    // Caverne derrière le mur
    _hill(120, 48, 35, 10, 1);
    // Stalactites
    _rect(150, 0, 6, 30, 1);
    _rect(175, 0, 6, 22, 1);
    // Plateforme mid
    _hill(200, 75, 30, 10, 1);
    // Mur d'acier (indestructible — contourner !)
    _rect(235, 55, 8, 30, 2);
    // Terrain ondulé droit
    _hill(275, 85, 35, 12, 1);
    // Dernier mur
    _rect(320, 65, 10, 28, 1);
    // Sortie
    _hill(360, 95, 25, 8, 1);
    _pillar(350, 95, 28, 70);
    // Sol avec trous mortels
    _rect(50, 165, W - 50, 35, 1);
    // Trous
    for (int x = 0; x < 45; x++) {
      for (int y = 165; y < H; y++) { ts(x, y, 0); }
    }
    for (int x = 95; x < 140; x++) {
      for (int y = 165; y < H; y++) { ts(x, y, 0); }
    }
    _rect(348, 165, 52, 8, 2);
  }

  // --- Update ---
  void update(double dt) {
    if (over) return;
    timer -= dt;
    if (timer <= 0) { timer = 0; _end(); return; }

    trapAnim += dt;
    if (trapAnim > 0.6 && !trapOpen) trapOpen = true;

    if (trapOpen) {
      spawnT += dt;
      if (spawnT >= spawnRate && spawned < toSpawn) {
        spawnT = 0; spawned++;
        lems.add(Lemming(trapX, trapY));
      }
    }

    for (final l in lems) {
      if (!l.alive || l.exited) continue;
      l.frame += dt * 10;
      l.cd = max(0, l.cd - dt);
      _upd(l, dt);
    }

    if (nuked) {
      for (final l in lems) {
        if (l.alive && !l.exited && l.state != LemState.bomb) {
          l.state = LemState.bomb;
          l.bombTimer = 0.2 + Random().nextDouble() * 2.5;
        }
      }
    }

    if (spawned >= toSpawn && lems.every((l) => !l.alive || l.exited)) _end();
    onChanged();
  }

  void _upd(Lemming l, double dt) {
    final ix = l.x.round(), iy = l.y.round();

    // Sortie
    if ((l.x - exitX).abs() < 6 && (l.y - exitY).abs() < 6) {
      l.state = LemState.exit_; l.exited = true; saved++; score += 50; return;
    }
    // Hors limites
    if (l.y > H + 5 || l.x < -5 || l.x > W + 5) {
      l.alive = false; dead++; return;
    }

    // Bomber
    if (l.state == LemState.bomb) {
      l.bombTimer -= dt;
      if (l.bombTimer <= 0) { _digC(ix, iy, 12); l.alive = false; dead++; }
      return;
    }
    // Blocker
    if (l.state == LemState.block) return;

    // Sol ?
    final gnd = sol(ix, iy + 1) || sol(ix - 1, iy + 1) || sol(ix + 1, iy + 1);

    if (!gnd && l.state != LemState.climb) {
      if (l.pFloat && l.fallDist > 12) {
        l.state = LemState.float_;
        l.y += 50 * 0.22 * dt;
        l.fallDist += 50 * 0.22 * dt;
      } else {
        l.state = LemState.fall;
        l.y += 50 * dt;
        l.fallDist += 50 * dt;
      }
      return;
    }

    // Atterrissage
    if (l.state == LemState.fall || l.state == LemState.float_) {
      // snap
      for (int i = 0; i < 6; i++) {
        if (sol(l.x.round(), l.y.round())) { l.y -= 1; } else { break; }
      }
      if (l.fallDist > 35 && !l.pFloat) {
        l.state = LemState.splat; l.alive = false; dead++; return;
      }
      l.fallDist = 0; l.state = LemState.walk;
    }

    // Digger
    if (l.state == LemState.dig) {
      l.cd -= dt;
      if (l.cd <= 0) {
        l.cd = 0.1;
        final dy = l.y.round() + 1;
        if (stl(ix, dy)) { l.state = LemState.walk; l.skill = LemmingSkill.none; return; }
        for (int dx = -3; dx <= 3; dx++) {
          for (int d = 0; d < 2; d++) { if (!stl(ix + dx, dy + d)) ts(ix + dx, dy + d, 0); }
        }
        l.y += 2;
      }
      return;
    }

    // Basher
    if (l.state == LemState.bash) {
      l.cd -= dt;
      if (l.cd <= 0) {
        l.cd = 0.08;
        bool hitS = false, hitT = false;
        for (int dy = -5; dy <= 1; dy++) {
          for (int dx = 1; dx <= 4; dx++) {
            final px = ix + l.dir * dx, py = iy + dy;
            if (stl(px, py)) { hitS = true; }
            else if (sol(px, py)) { hitT = true; ts(px, py, 0); }
          }
        }
        if (hitS || !hitT) { l.state = LemState.walk; l.skill = LemmingSkill.none; }
        else { l.x += l.dir * 2; }
      }
      return;
    }

    // Miner
    if (l.state == LemState.mine) {
      l.cd -= dt;
      if (l.cd <= 0) {
        l.cd = 0.1;
        bool hitS = false;
        for (int dy = -1; dy <= 3; dy++) {
          for (int dx = -2; dx <= 2; dx++) {
            final px = ix + l.dir * 3 + dx, py = iy + 2 + dy;
            if (stl(px, py)) { hitS = true; } else { ts(px, py, 0); }
          }
        }
        if (hitS) { l.state = LemState.walk; l.skill = LemmingSkill.none; }
        else { l.x += l.dir * 2; l.y += 2; }
      }
      return;
    }

    // Builder
    if (l.state == LemState.build) {
      l.cd -= dt;
      if (l.cd <= 0) {
        l.cd = 0.18;
        if (l.buildN >= 12) {
          l.state = LemState.walk; l.skill = LemmingSkill.none; l.dir *= -1; return;
        }
        for (int dx = 0; dx < 5; dx++) {
          ts(ix + l.dir * dx, iy, 1, 0xFF998866);
        }
        l.x += l.dir * 3; l.y -= 1; l.buildN++;
        if (sol((l.x + l.dir * 4).round(), l.y.round() - 3)) {
          l.state = LemState.walk; l.skill = LemmingSkill.none; l.dir *= -1;
        }
      }
      return;
    }

    // Climber
    if (l.state == LemState.climb) {
      l.y -= 12 * dt;
      if (!sol(ix + l.dir, l.y.round()) && !sol(ix + l.dir, l.y.round() + 1)) {
        l.x += l.dir * 3; l.state = LemState.walk;
      }
      if (sol(ix, l.y.round() - 1)) { l.state = LemState.fall; l.dir *= -1; }
      return;
    }

    // === Marche ===
    l.state = LemState.walk;
    final nx = l.x + l.dir * 15 * dt;
    final nix = nx.round();

    // Mur ?
    if (sol(nix + l.dir, iy) && sol(nix + l.dir, iy - 1) && sol(nix + l.dir, iy - 2)) {
      if (l.pClimb) { l.state = LemState.climb; return; }
      l.dir *= -1; return;
    }
    // Montée marche
    int step = 0;
    while (sol(nix, (l.y - step).round()) && step < 4) { step++; }
    if (step > 0 && step <= 3) { l.y -= step; }
    else if (step > 3) {
      if (l.pClimb) { l.state = LemState.climb; return; }
      l.dir *= -1; return;
    }
    l.x = nx;

    // Collision blockers
    for (final o in lems) {
      if (o == l || !o.alive || o.exited || o.state != LemState.block) continue;
      if ((l.x - o.x).abs() < 5 && (l.y - o.y).abs() < 5) {
        l.dir *= -1; l.x += l.dir * 6;
      }
    }
  }

  // --- Assign ---
  void assign(double tx, double ty) {
    if (selSkill == LemmingSkill.none) return;
    final c = sk[selSkill] ?? 0;
    if (c <= 0) return;

    Lemming? best; double bestD = 15;
    for (final l in lems) {
      if (!l.alive || l.exited) continue;
      if (selSkill != LemmingSkill.climber && selSkill != LemmingSkill.floater) {
        if (l.skill != LemmingSkill.none && l.state != LemState.walk && l.state != LemState.fall) {
          continue;
        }
      }
      final d = sqrt(pow(l.x - tx, 2) + pow(l.y - ty, 2));
      if (d < bestD) { best = l; bestD = d; }
    }
    if (best == null) return;
    sk[selSkill] = c - 1;

    switch (selSkill) {
      case LemmingSkill.climber: best.pClimb = true;
      case LemmingSkill.floater: best.pFloat = true;
      case LemmingSkill.bomber: best.state = LemState.bomb; best.bombTimer = 5;
      case LemmingSkill.blocker: best.skill = selSkill; best.state = LemState.block;
      case LemmingSkill.builder: best.skill = selSkill; best.state = LemState.build; best.buildN = 0; best.cd = 0;
      case LemmingSkill.basher: best.skill = selSkill; best.state = LemState.bash; best.cd = 0;
      case LemmingSkill.miner: best.skill = selSkill; best.state = LemState.mine; best.cd = 0;
      case LemmingSkill.digger: best.skill = selSkill; best.state = LemState.dig; best.cd = 0;
      case LemmingSkill.none: break;
    }
  }

  void nuke() => nuked = true;
  void faster() => spawnRate = max(0.15, spawnRate - 0.12);
  void slower() => spawnRate = min(3.0, spawnRate + 0.12);

  void _end() {
    if (saved >= need) {
      score += (timer * 3).toInt();
      if (lvl < 2) { _load(lvl + 1); return; }
      else { won = true; score += 500; }
    }
    over = true; onOver(score);
  }
}

// ============================================================
// PAINTER haute fidélité
// ============================================================
class LemmingsPainter extends CustomPainter {
  final LemmingsGame g;
  LemmingsPainter(this.g);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / LemmingsGame.W;
    final sy = size.height / LemmingsGame.H;

    // Fond bleu nuit profond (comme l'original Amiga)
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF000038));

    // Étoiles scintillantes
    final sp = Paint();
    for (int i = 0; i < 50; i++) {
      final stx = ((i * 97 + 31) % LemmingsGame.W).toDouble();
      final sty = ((i * 53 + 17) % (LemmingsGame.H * 0.6)).toDouble();
      final bri = 0.3 + 0.7 * ((sin(g.trapAnim * 2 + i) + 1) / 2);
      sp.color = Color.fromRGBO(100, 120, 180, bri);
      canvas.drawCircle(Offset(stx * sx, sty * sy), 0.6 * sx, sp);
    }

    // Terrain pixel par pixel
    for (int y = 0; y < LemmingsGame.H; y++) {
      for (int x = 0; x < LemmingsGame.W; x++) {
        if (g.tg(x, y) == 0) continue;
        canvas.drawRect(
          Rect.fromLTWH(x * sx, y * sy, sx + 0.5, sy + 0.5),
          Paint()..color = Color(g.terCol[y * LemmingsGame.W + x] | 0xFF000000),
        );
      }
    }

    // Trappe (style original — boîte métallique avec porte battante)
    _trap(canvas, g.trapX * sx, g.trapY * sy, sx, sy);
    // Sortie (arche bleue lumineuse)
    _exit(canvas, g.exitX * sx, g.exitY * sy, sx, sy);

    // Lemmings
    for (final l in g.lems) {
      if (l.exited || (!l.alive && l.state != LemState.splat)) continue;
      _lem(canvas, l, sx, sy);
    }
  }

  void _trap(Canvas c, double x, double y, double sx, double sy) {
    final w = 18 * sx, h = 8 * sy;
    // Boîte métallique
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y - h * 0.5), width: w, height: h),
        Radius.circular(sx * 2),
      ),
      Paint()..color = const Color(0xFF6A6A9A),
    );
    // Rivets
    for (final dx in [-w * 0.35, w * 0.35]) {
      c.drawCircle(Offset(x + dx, y - h * 0.5), sx, Paint()..color = const Color(0xFF9999CC));
    }
    // Bande sombre
    c.drawRect(
      Rect.fromCenter(center: Offset(x, y - h * 0.5), width: w * 0.8, height: h * 0.15),
      Paint()..color = const Color(0xFF444477),
    );
    // Porte ouverte
    if (g.trapOpen) {
      c.drawRect(
        Rect.fromLTWH(x - 4 * sx, y - 2 * sy, 8 * sx, 5 * sy),
        Paint()..color = const Color(0xFF222244),
      );
      // Rebord
      c.drawRect(
        Rect.fromLTWH(x - 4 * sx, y - 2 * sy, 8 * sx, 5 * sy),
        Paint()..color = const Color(0xFF5555AA)..style = PaintingStyle.stroke..strokeWidth = sx * 0.5,
      );
    }
  }

  void _exit(Canvas c, double x, double y, double sx, double sy) {
    final w = 16 * sx, h = 18 * sy;
    // Piliers bleus lumineux
    c.drawRect(Rect.fromLTWH(x - w * 0.5, y - h, 3 * sx, h), Paint()..color = const Color(0xFF1A1AAA));
    c.drawRect(Rect.fromLTWH(x + w * 0.5 - 3 * sx, y - h, 3 * sx, h), Paint()..color = const Color(0xFF1A1AAA));
    // Piliers highlight
    c.drawRect(Rect.fromLTWH(x - w * 0.5 + sx, y - h, sx, h), Paint()..color = const Color(0xFF3333CC));
    c.drawRect(Rect.fromLTWH(x + w * 0.5 - 2 * sx, y - h, sx, h), Paint()..color = const Color(0xFF3333CC));
    // Arc
    c.drawArc(
      Rect.fromCenter(center: Offset(x, y - h), width: w, height: h * 0.5),
      pi, pi, false,
      Paint()..color = const Color(0xFF4444FF)..style = PaintingStyle.stroke..strokeWidth = 3 * sx,
    );
    // Halo lumineux
    c.drawCircle(Offset(x, y - h * 0.5), 5 * sx,
      Paint()..color = const Color(0xFF4488FF).withValues(alpha: 0.3));
    c.drawCircle(Offset(x, y - h * 0.5), 3 * sx,
      Paint()..color = const Color(0xFF88BBFF).withValues(alpha: 0.4));
    // Flèche d'entrée
    final ap = Paint()..color = Colors.white..strokeWidth = sx..strokeCap = StrokeCap.round;
    c.drawLine(Offset(x, y - 3 * sy), Offset(x, y - h + 4 * sy), ap);
    c.drawLine(Offset(x - 3 * sx, y - h + 8 * sy), Offset(x, y - h + 4 * sy), ap);
    c.drawLine(Offset(x + 3 * sx, y - h + 8 * sy), Offset(x, y - h + 4 * sy), ap);
  }

  void _lem(Canvas c, Lemming l, double sx, double sy) {
    final x = l.x * sx, y = l.y * sy;
    final lw = 2.5 * sx; // demi-largeur
    final lh = 5.5 * sy; // hauteur

    // Splat
    if (l.state == LemState.splat) {
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: lw * 5, height: sy * 2),
        Paint()..color = const Color(0xFF00BB00));
      // Particules
      for (int i = 0; i < 4; i++) {
        c.drawCircle(
          Offset(x + (i * 7 - 10) * sx, y - (i * 3) * sy),
          sx * 0.8,
          Paint()..color = const Color(0xFF00AA00));
      }
      return;
    }

    // Couleurs fidèles à l'original
    const blue = Color(0xFF3333DD);  // tunique
    const green = Color(0xFF00EE00); // cheveux
    const skin = Color(0xFFFFBB77);  // peau

    // Animation marche
    final fr = l.frame.floor() % 8;
    final walkSin = sin(fr / 8 * pi * 2);

    // === Pieds/jambes ===
    if (l.state == LemState.walk) {
      final legOff = walkSin * lw * 0.7;
      // Jambe gauche
      c.drawLine(Offset(x - lw * 0.2, y - lh * 0.15), Offset(x - lw * 0.3 + legOff, y),
        Paint()..color = blue..strokeWidth = sx * 1.3..strokeCap = StrokeCap.round);
      // Jambe droite
      c.drawLine(Offset(x + lw * 0.2, y - lh * 0.15), Offset(x + lw * 0.3 - legOff, y),
        Paint()..color = blue..strokeWidth = sx * 1.3..strokeCap = StrokeCap.round);
      // Pieds
      c.drawCircle(Offset(x - lw * 0.3 + legOff, y), sx * 0.7, Paint()..color = blue);
      c.drawCircle(Offset(x + lw * 0.3 - legOff, y), sx * 0.7, Paint()..color = blue);
    } else {
      // Jambes droites
      c.drawRect(Rect.fromLTRB(x - lw * 0.5, y - lh * 0.15, x + lw * 0.5, y),
        Paint()..color = blue);
    }

    // === Corps (tunique bleue) ===
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x - lw, y - lh * 0.72, x + lw, y - lh * 0.12),
        Radius.circular(sx * 0.5)),
      Paint()..color = blue);
    // Reflet sur la tunique
    c.drawRect(
      Rect.fromLTRB(x - lw * 0.3, y - lh * 0.7, x - lw * 0.1, y - lh * 0.2),
      Paint()..color = const Color(0xFF4444EE));

    // === Tête ===
    final headY = y - lh * 0.82;
    final headR = lw * 0.7;
    c.drawCircle(Offset(x, headY), headR, Paint()..color = skin);

    // === Cheveux verts (la signature !) ===
    // Touffe volumineuse comme l'original
    final hp = Path();
    hp.moveTo(x - lw * 0.9, headY - headR * 0.2);
    hp.quadraticBezierTo(x - lw * 0.5, headY - lh * 0.4, x, headY - lh * 0.35);
    hp.quadraticBezierTo(x + lw * 0.5, headY - lh * 0.4, x + lw * 0.9, headY - headR * 0.2);
    hp.quadraticBezierTo(x + lw * 0.3, headY - lh * 0.15, x, headY - lh * 0.12);
    hp.quadraticBezierTo(x - lw * 0.3, headY - lh * 0.15, x - lw * 0.9, headY - headR * 0.2);
    hp.close();
    c.drawPath(hp, Paint()..color = green);
    // Mèches plus claires
    c.drawPath(hp, Paint()..color = const Color(0xFF44FF44).withValues(alpha: 0.3));

    // === Yeux ===
    final eyeX = x + l.dir * lw * 0.2;
    c.drawCircle(Offset(eyeX, headY + headR * 0.1), sx * 0.55, Paint()..color = Colors.white);
    c.drawCircle(Offset(eyeX + l.dir * sx * 0.15, headY + headR * 0.1), sx * 0.3, Paint()..color = Colors.black);

    // === Effets des skills ===
    _skillFx(c, l, x, y, lw, lh, sx, sy, skin, blue);
  }

  void _skillFx(Canvas c, Lemming l, double x, double y,
      double lw, double lh, double sx, double sy, Color skin, Color blue) {
    // Blocker — bras écartés style croix
    if (l.state == LemState.block) {
      final ap = Paint()..color = skin..strokeWidth = sx * 1.1..strokeCap = StrokeCap.round;
      c.drawLine(Offset(x, y - lh * 0.5), Offset(x - lw * 2.8, y - lh * 0.6), ap);
      c.drawLine(Offset(x, y - lh * 0.5), Offset(x + lw * 2.8, y - lh * 0.6), ap);
      // Mains ouvertes
      c.drawCircle(Offset(x - lw * 2.8, y - lh * 0.6), sx * 1.2, Paint()..color = skin);
      c.drawCircle(Offset(x + lw * 2.8, y - lh * 0.6), sx * 1.2, Paint()..color = skin);
    }

    // Floater — parapluie violet
    if (l.state == LemState.float_) {
      c.drawLine(Offset(x, y - lh * 0.85), Offset(x, y - lh * 1.3),
        Paint()..color = const Color(0xFF663300)..strokeWidth = sx * 0.8);
      final up = Path()
        ..moveTo(x - lw * 3.5, y - lh * 1.1)
        ..quadraticBezierTo(x, y - lh * 1.8, x + lw * 3.5, y - lh * 1.1);
      c.drawPath(up, Paint()..color = const Color(0xFFCC44CC)..style = PaintingStyle.stroke..strokeWidth = sx * 2);
      c.drawPath(up, Paint()..color = const Color(0xFFDD66DD).withValues(alpha: 0.3));
      // Baleines
      for (final dx in [-2.5, 0.0, 2.5]) {
        c.drawLine(Offset(x + dx * lw, y - lh * 1.3), Offset(x + dx * lw * 1.1, y - lh * 1.1),
          Paint()..color = const Color(0xFF663300)..strokeWidth = sx * 0.5);
      }
    }

    // Builder — bras + brique
    if (l.state == LemState.build) {
      final phase = (l.frame * 2).floor() % 2;
      final armX = x + l.dir * lw * 2.5;
      final armY = y - lh * 0.5 - (phase == 0 ? lh * 0.1 : 0);
      c.drawLine(Offset(x + l.dir * lw, y - lh * 0.5), Offset(armX, armY),
        Paint()..color = skin..strokeWidth = sx..strokeCap = StrokeCap.round);
      c.drawRect(Rect.fromCenter(center: Offset(armX, armY), width: 4 * sx, height: 2 * sy),
        Paint()..color = const Color(0xFF998866));
    }

    // Digger — pioche
    if (l.state == LemState.dig) {
      final ph = (l.frame * 3).floor() % 2;
      c.drawLine(Offset(x + lw, y - lh * 0.5), Offset(x + lw * 2, y + (ph == 0 ? 0 : lh * 0.15)),
        Paint()..color = Colors.grey..strokeWidth = sx..strokeCap = StrokeCap.round);
    }

    // Basher — poing
    if (l.state == LemState.bash) {
      final ph = (l.frame * 4).floor() % 2;
      final fx = x + l.dir * (lw * 2.5 + (ph == 0 ? lw : 0));
      c.drawLine(Offset(x + l.dir * lw, y - lh * 0.5), Offset(fx, y - lh * 0.5),
        Paint()..color = skin..strokeWidth = sx * 1.2..strokeCap = StrokeCap.round);
      // Poing
      c.drawCircle(Offset(fx, y - lh * 0.5), sx * 1.2, Paint()..color = skin);
    }

    // Miner — pioche diagonale
    if (l.state == LemState.mine) {
      final ph = (l.frame * 3).floor() % 2;
      c.drawLine(
        Offset(x + l.dir * lw, y - lh * 0.4),
        Offset(x + l.dir * lw * 3, y + (ph == 0 ? lh * 0.1 : lh * 0.3)),
        Paint()..color = Colors.grey..strokeWidth = sx..strokeCap = StrokeCap.round);
    }

    // Climber — mains accrochées
    if (l.state == LemState.climb) {
      c.drawLine(Offset(x + l.dir * lw, y - lh * 0.7), Offset(x + l.dir * lw * 2, y - lh * 0.9),
        Paint()..color = skin..strokeWidth = sx..strokeCap = StrokeCap.round);
      c.drawLine(Offset(x + l.dir * lw, y - lh * 0.3), Offset(x + l.dir * lw * 2, y - lh * 0.2),
        Paint()..color = skin..strokeWidth = sx..strokeCap = StrokeCap.round);
    }

    // Bomber — compteur clignotant
    if (l.state == LemState.bomb) {
      final blink = (l.bombTimer * 5).floor() % 2 == 0;
      final tp = TextPainter(
        text: TextSpan(text: '${l.bombTimer.ceil()}',
          style: TextStyle(color: blink ? Colors.red : Colors.white,
            fontSize: 5 * sx, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)..layout();
      tp.paint(c, Offset(x - tp.width / 2, y - lh - 6 * sy));
      if (blink) {
        c.drawCircle(Offset(x, y - lh * 0.4), lw * 1.5,
          Paint()..color = Colors.red.withValues(alpha: 0.35));
      }
    }

    // Indicateurs permanents
    if (l.pClimb) {
      c.drawCircle(Offset(x - lw * 1.5, y - lh - 2 * sy), sx * 0.7,
        Paint()..color = Colors.cyan);
    }
    if (l.pFloat) {
      c.drawCircle(Offset(x + lw * 1.5, y - lh - 2 * sy), sx * 0.7,
        Paint()..color = const Color(0xFFDD44DD));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
