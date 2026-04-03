import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

enum LemmingSkill { none, climber, floater, bomber, blocker, builder, basher, miner, digger }
enum LemS { walk, fall, climb, build, bash, mine, dig, block, float_, bomb, splat, exit_, drown }

class Lem {
  double x, y;
  int dir;
  LemmingSkill skill;
  LemS state;
  bool alive, exited;
  double fallD, fr, bombT, cd;
  int buildN;
  bool pClimb, pFloat;
  Lem(this.x, this.y, [this.dir = 1])
      : skill = LemmingSkill.none, state = LemS.fall,
        alive = true, exited = false, fallD = 0, fr = 0,
        bombT = 5, cd = 0, buildN = 0, pClimb = false, pFloat = false;
}

/// Particule visuelle (debris, eau, explosion)
class _Particle {
  double x, y, vx, vy, life;
  int color;
  _Particle(this.x, this.y, this.vx, this.vy, this.life, this.color);
}

class LemmingsGame {
  static const int W = 480, H = 220;
  late Uint8List ter;     // 0=air,1=dirt,2=steel,3=crystal,4=brick,5=rock
  late Uint32List terCol;
  // Eau (niveau Y en dessous duquel c'est de l'eau)
  int waterLevel = H - 8;

  double trapX = 0, trapY = 0, exitX = 0, exitY = 0;
  final List<Lem> lems = [];
  final List<_Particle> particles = [];
  int toSpawn = 0, spawned = 0, saved = 0, dead = 0, need = 0;
  double spawnT = 0, spawnRate = 0.8;
  final Map<LemmingSkill, int> sk = {};
  LemmingSkill selSkill = LemmingSkill.none;

  int score = 0, lvl = 0;
  bool over = false, won = false, nuked = false;
  double timer = 0, trapAnim = 0, globalTime = 0;
  bool trapOpen = false;

  final VoidCallback onChanged;
  final void Function(int) onOver;
  final Random _r = Random();

  LemmingsGame({required this.onChanged, required this.onOver}) { _load(0); }

  // --- terrain ---
  int tg(int x, int y) => (x < 0 || x >= W || y < 0 || y >= H) ? 0 : ter[y * W + x];
  void ts(int x, int y, int v, [int? c]) {
    if (x < 0 || x >= W || y < 0 || y >= H) return;
    ter[y * W + x] = v;
    if (c != null) terCol[y * W + x] = c;
  }
  bool sol(int x, int y) => tg(x, y) > 0;
  bool stl(int x, int y) { final t = tg(x, y); return t == 2; }
  bool isWater(int x, int y) => y >= waterLevel;

  void _digC(int cx, int cy, int r) {
    for (int dy = -r; dy <= r; dy++) for (int dx = -r; dx <= r; dx++) {
      if (dx * dx + dy * dy <= r * r && !stl(cx + dx, cy + dy)) {
        // Particules de debris
        if (sol(cx + dx, cy + dy)) {
          particles.add(_Particle(
            (cx + dx).toDouble(), (cy + dy).toDouble(),
            (_r.nextDouble() - 0.5) * 40, -_r.nextDouble() * 60,
            0.5 + _r.nextDouble() * 0.5,
            terCol[(cy + dy) * W + (cx + dx)]));
        }
        ts(cx + dx, cy + dy, 0);
      }
    }
  }

  // Couleurs par type de terrain
  int _col(int x, int y, int type) {
    final n = ((x * 7 + y * 13 + x * y) % 8);
    return switch (type) {
      1 => [0xFF2D7A2D, 0xFF1E6B1E, 0xFF338833, 0xFF267226,
            0xFF3B953B, 0xFF2A822A, 0xFF347A34, 0xFF1F721F][n], // terre verte
      3 => [0xFF6644AA, 0xFF7755BB, 0xFF5533AA, 0xFF8866CC,
            0xFF7744BB, 0xFF6655AA, 0xFF9977DD, 0xFF5544BB][n], // cristal violet
      4 => [0xFFAA7744, 0xFF996633, 0xFFBB8855, 0xFF885522,
            0xFFCC9966, 0xFF997744, 0xFFAA8855, 0xFF886633][n], // brique
      5 => [0xFF667788, 0xFF556677, 0xFF778899, 0xFF445566,
            0xFF889999, 0xFF6677AA, 0xFF557788, 0xFF668888][n], // roche grise
      2 => ((x + y) % 2 == 0) ? 0xFF7788AA : 0xFF6677A0, // acier
      _ => 0xFF2D7A2D,
    };
  }

  void _fill(int x, int y, int w, int h, int t) {
    for (int dy = 0; dy < h; dy++) for (int dx = 0; dx < w; dx++) {
      ts(x + dx, y + dy, t, _col(x + dx, y + dy, t));
    }
  }

  void _hill(int cx, int cy, int rx, int ry, int t) {
    final rng = Random(cx * 100 + cy);
    for (int dy = -ry; dy <= ry; dy++) for (int dx = -rx; dx <= rx; dx++) {
      final noise = (rng.nextDouble() - 0.5) * 0.12;
      if ((dx * dx) / (rx * rx + 0.1) + (dy * dy) / (ry * ry + 0.1) + noise <= 1.0) {
        ts(cx + dx, cy + dy, t, _col(cx + dx, cy + dy, t));
      }
    }
  }

  void _arch(int cx, int cy, int rx, int ry) {
    // Arche (mur avec trou en arc)
    for (int dy = -ry; dy <= ry; dy++) for (int dx = -rx; dx <= rx; dx++) {
      final px = cx + dx, py = cy + dy;
      if (dy < 0) { // partie haute = plein
        ts(px, py, 1, _col(px, py, 1));
      } else { // partie basse = arc vide si dans le cercle
        final d = (dx * dx) / (rx * rx * 0.6) + (dy * dy) / (ry * ry * 0.8);
        if (d > 1.0) ts(px, py, 1, _col(px, py, 1));
      }
    }
  }

  void _grass() {
    for (int x = 0; x < W; x++) for (int y = 1; y < H; y++) {
      if (tg(x, y) > 0 && tg(x, y) != 2 && tg(x, y - 1) == 0 && !isWater(x, y)) {
        final n = (x * 3 + y * 7) % 5;
        terCol[y * W + x] = [0xFF55EE44, 0xFF44DD33, 0xFF66FF55, 0xFF33CC22, 0xFF4AE83A][n];
        // Brins
        if (x % 2 == 0 && y > 1 && tg(x, y - 1) == 0 && tg(x, y - 2) == 0) {
          ts(x, y - 1, 1, [0xFF44DD33, 0xFF55EE44, 0xFF33BB22][x % 3]);
        }
      }
    }
  }

  // --- Niveaux (5 niveaux, difficulté croissante) ---
  void _load(int l) {
    lvl = l; ter = Uint8List(W * H); terCol = Uint32List(W * H);
    lems.clear(); particles.clear();
    spawned = saved = dead = 0; spawnT = 0;
    nuked = false; trapOpen = false; trapAnim = 0;
    waterLevel = H - 10;
    switch (l) {
      case 0: _lv1(); case 1: _lv2(); case 2: _lv3();
      case 3: _lv4(); case 4: _lv5();
    }
    _grass();
  }

  // Nv1 — "Just Dig!" (Fun)
  void _lv1() {
    toSpawn = 10; need = 7; timer = 120; trapX = 60; trapY = 25; exitX = 410; exitY = waterLevel - 5;
    sk.clear();
    sk[LemmingSkill.digger] = 10; sk[LemmingSkill.basher] = 5; sk[LemmingSkill.builder] = 3;

    _hill(80, 45, 55, 16, 1);
    _fill(120, 45, 18, 80, 1); // pilier
    _hill(200, 95, 50, 12, 1);
    _fill(230, 95, 70, 6, 1); // pont
    _fill(300, 72, 12, 30, 1); // mur → basher
    _hill(370, 100, 35, 12, 1);
    _fill(355, 100, 30, waterLevel - 100, 1);
    _fill(0, waterLevel - 3, W, 3, 1); // bord eau
    _fill(380, waterLevel - 3, 50, 3, 2); // acier sortie
  }

  // Nv2 — "Bridge the Gap" (Tricky) — cristaux
  void _lv2() {
    toSpawn = 15; need = 10; timer = 180; trapX = 40; trapY = 15; exitX = 435; exitY = waterLevel - 5;
    sk.clear();
    sk[LemmingSkill.builder] = 10; sk[LemmingSkill.floater] = 6;
    sk[LemmingSkill.blocker] = 3; sk[LemmingSkill.digger] = 4;
    sk[LemmingSkill.basher] = 3; sk[LemmingSkill.miner] = 2;

    _hill(60, 32, 35, 10, 3); // cristal
    _hill(150, 48, 18, 7, 3);
    _hill(230, 60, 20, 8, 3);
    _hill(310, 72, 25, 9, 1);
    _fill(340, 48, 10, 32, 1); // mur
    _hill(380, 75, 30, 10, 1);
    _fill(375, 75, 20, waterLevel - 75, 1);
    // Trou mortel dans le sol
    _fill(0, waterLevel - 3, 160, 3, 1);
    _fill(200, waterLevel - 3, W - 200, 3, 1);
    _fill(410, waterLevel - 3, 50, 3, 2);
  }

  // Nv3 — "The Hard Way" (Taxing) — briques
  void _lv3() {
    toSpawn = 20; need = 15; timer = 240; trapX = 30; trapY = 10; exitX = 445; exitY = waterLevel - 5;
    sk.clear();
    sk[LemmingSkill.climber] = 4; sk[LemmingSkill.floater] = 5;
    sk[LemmingSkill.bomber] = 3; sk[LemmingSkill.blocker] = 4;
    sk[LemmingSkill.builder] = 8; sk[LemmingSkill.basher] = 5;
    sk[LemmingSkill.miner] = 4; sk[LemmingSkill.digger] = 6;

    _hill(50, 28, 30, 8, 4); // brique
    _fill(85, 0, 10, 55, 4); // grand mur
    _hill(130, 48, 35, 10, 1);
    _fill(158, 0, 8, 32, 5); // stalactite roche
    _hill(210, 75, 30, 10, 1);
    _fill(245, 55, 8, 28, 2); // acier !
    _hill(290, 85, 35, 12, 4);
    _fill(335, 65, 10, 25, 4); // mur brique
    _hill(380, 92, 25, 8, 1);
    _fill(370, 92, 28, waterLevel - 92, 1);
    _fill(0, waterLevel - 3, 40, 3, 1);
    _fill(60, waterLevel - 3, W - 60, 3, 1);
    // Trous
    for (int x = 100; x < 145; x++) for (int y = waterLevel - 3; y < waterLevel; y++) ts(x, y, 0);
    _fill(420, waterLevel - 3, 60, 3, 2);
  }

  // Nv4 — "Crystal Cavern" (Taxing) — grottes cristallines
  void _lv4() {
    toSpawn = 20; need = 14; timer = 270; trapX = 45; trapY = 12; exitX = 440; exitY = waterLevel - 5;
    sk.clear();
    sk[LemmingSkill.climber] = 5; sk[LemmingSkill.floater] = 4;
    sk[LemmingSkill.bomber] = 4; sk[LemmingSkill.blocker] = 3;
    sk[LemmingSkill.builder] = 6; sk[LemmingSkill.basher] = 6;
    sk[LemmingSkill.miner] = 5; sk[LemmingSkill.digger] = 5;

    // Plafond de la grotte
    _fill(0, 0, W, 6, 5);
    _hill(60, 28, 30, 8, 3);
    // Stalactites cristallines
    _fill(100, 6, 6, 25, 3); _fill(140, 6, 5, 18, 3); _fill(200, 6, 7, 30, 3);
    _fill(280, 6, 5, 20, 3); _fill(350, 6, 6, 15, 3);
    // Plateformes flottantes
    _hill(120, 55, 25, 7, 5);
    _hill(190, 45, 20, 6, 5);
    _arch(260, 70, 20, 15); // arche
    _hill(330, 55, 22, 7, 3);
    _hill(400, 65, 25, 8, 5);
    _fill(395, 65, 20, waterLevel - 65, 5);
    // Sol avec passages
    _fill(0, waterLevel - 3, W, 3, 5);
    for (int x = 80; x < 115; x++) for (int y = waterLevel - 3; y < waterLevel; y++) ts(x, y, 0);
    for (int x = 220; x < 250; x++) for (int y = waterLevel - 3; y < waterLevel; y++) ts(x, y, 0);
    _fill(420, waterLevel - 3, 60, 3, 2);
  }

  // Nv5 — "Mayhem" — tout combiné, très dur
  void _lv5() {
    toSpawn = 25; need = 20; timer = 360; trapX = 25; trapY = 8; exitX = 450; exitY = waterLevel - 5;
    sk.clear();
    sk[LemmingSkill.climber] = 5; sk[LemmingSkill.floater] = 6;
    sk[LemmingSkill.bomber] = 5; sk[LemmingSkill.blocker] = 5;
    sk[LemmingSkill.builder] = 10; sk[LemmingSkill.basher] = 8;
    sk[LemmingSkill.miner] = 6; sk[LemmingSkill.digger] = 8;

    _hill(45, 22, 25, 7, 4);
    _fill(75, 0, 8, 45, 2); // MUR ACIER
    _fill(95, 30, 50, 6, 3); // cristal
    _fill(145, 6, 6, 30, 5);
    _hill(180, 50, 20, 6, 1);
    _fill(205, 35, 8, 22, 4);
    _hill(240, 55, 15, 5, 3);
    _fill(260, 40, 6, 20, 2); // acier
    _fill(275, 55, 40, 6, 1);
    _fill(315, 40, 8, 21, 4);
    _hill(345, 50, 18, 6, 5);
    _fill(370, 35, 8, 20, 4);
    _hill(400, 48, 20, 7, 1);
    _fill(405, 48, 15, waterLevel - 48, 1);
    // Sol complexe avec trous multiples
    _fill(0, waterLevel - 3, W, 3, 5);
    for (final range in [(0, 30), (90, 130), (170, 200), (290, 320)]) {
      for (int x = range.$1; x < range.$2; x++) {
        for (int y = waterLevel - 3; y < waterLevel; y++) { ts(x, y, 0); }
      }
    }
    _fill(430, waterLevel - 3, 50, 3, 2);
  }

  // --- Update ---
  void update(double dt) {
    if (over) return;
    globalTime += dt;
    timer -= dt;
    if (timer <= 0) { timer = 0; _end(); return; }

    trapAnim += dt;
    if (trapAnim > 0.6 && !trapOpen) trapOpen = true;

    if (trapOpen) {
      spawnT += dt;
      if (spawnT >= spawnRate && spawned < toSpawn) {
        spawnT = 0; spawned++;
        lems.add(Lem(trapX, trapY));
      }
    }

    for (final l in lems) {
      if (!l.alive || l.exited) continue;
      l.fr += dt * 10;
      l.cd = max(0, l.cd - dt);
      _upd(l, dt);
    }

    // Particules
    for (final p in particles) {
      p.vy += 120 * dt; // gravité
      p.x += p.vx * dt; p.y += p.vy * dt;
      p.life -= dt;
    }
    particles.removeWhere((p) => p.life <= 0 || p.y > H);

    if (nuked) {
      for (final l in lems) {
        if (l.alive && !l.exited && l.state != LemS.bomb) {
          l.state = LemS.bomb; l.bombT = 0.2 + _r.nextDouble() * 2.5;
        }
      }
    }
    if (spawned >= toSpawn && lems.every((l) => !l.alive || l.exited)) _end();
    onChanged();
  }

  void _upd(Lem l, double dt) {
    final ix = l.x.round(), iy = l.y.round();

    // Eau → noyade
    if (isWater(ix, iy)) {
      l.state = LemS.drown; l.alive = false; dead++;
      // Splash
      for (int i = 0; i < 8; i++) {
        particles.add(_Particle(l.x, l.y, (_r.nextDouble() - 0.5) * 30,
          -_r.nextDouble() * 40, 0.6, 0xFF4488FF));
      }
      return;
    }

    // Sortie
    if ((l.x - exitX).abs() < 6 && (l.y - exitY).abs() < 6) {
      l.state = LemS.exit_; l.exited = true; saved++; score += 50; return;
    }
    if (l.y > H + 5 || l.x < -5 || l.x > W + 5) { l.alive = false; dead++; return; }

    // Bomber
    if (l.state == LemS.bomb) {
      l.bombT -= dt;
      if (l.bombT <= 0) {
        _digC(ix, iy, 14);
        l.alive = false; dead++;
        // Particules explosion
        for (int i = 0; i < 20; i++) {
          final a = _r.nextDouble() * pi * 2;
          final spd = 20 + _r.nextDouble() * 50;
          particles.add(_Particle(l.x, l.y, cos(a) * spd, sin(a) * spd - 20,
            0.4 + _r.nextDouble() * 0.4,
            [0xFFFF4400, 0xFFFFAA00, 0xFFFFFF00, 0xFFFF6600][_r.nextInt(4)]));
        }
      }
      return;
    }
    if (l.state == LemS.block) return;

    final gnd = sol(ix, iy + 1) || sol(ix - 1, iy + 1) || sol(ix + 1, iy + 1);

    if (!gnd && l.state != LemS.climb) {
      if (l.pFloat && l.fallD > 12) {
        l.state = LemS.float_; l.y += 50 * 0.2 * dt; l.fallD += 50 * 0.2 * dt;
      } else {
        l.state = LemS.fall; l.y += 55 * dt; l.fallD += 55 * dt;
      }
      return;
    }

    if (l.state == LemS.fall || l.state == LemS.float_) {
      for (int i = 0; i < 6; i++) { if (sol(l.x.round(), l.y.round())) l.y -= 1; else break; }
      if (l.fallD > 38 && !l.pFloat) { l.state = LemS.splat; l.alive = false; dead++; return; }
      l.fallD = 0; l.state = LemS.walk;
    }

    // Digger
    if (l.state == LemS.dig) {
      l.cd -= dt;
      if (l.cd <= 0) {
        l.cd = 0.09;
        final dy = l.y.round() + 1;
        if (stl(ix, dy)) { l.state = LemS.walk; l.skill = LemmingSkill.none; return; }
        for (int dx = -4; dx <= 4; dx++) for (int d = 0; d < 2; d++) {
          if (!stl(ix + dx, dy + d)) {
            if (sol(ix + dx, dy + d)) particles.add(_Particle(
              (ix + dx).toDouble(), (dy + d).toDouble(), (_r.nextDouble() - 0.5) * 15,
              -_r.nextDouble() * 20, 0.3, terCol[(dy + d) * W + (ix + dx)]));
            ts(ix + dx, dy + d, 0);
          }
        }
        l.y += 2;
      }
      return;
    }

    // Basher
    if (l.state == LemS.bash) {
      l.cd -= dt;
      if (l.cd <= 0) {
        l.cd = 0.07;
        bool hitS = false, hitT = false;
        for (int dy = -6; dy <= 1; dy++) for (int dx = 1; dx <= 5; dx++) {
          final px = ix + l.dir * dx, py = iy + dy;
          if (stl(px, py)) hitS = true;
          else if (sol(px, py)) {
            hitT = true;
            particles.add(_Particle(px.toDouble(), py.toDouble(),
              l.dir * (10 + _r.nextDouble() * 20), -_r.nextDouble() * 15, 0.3, terCol[py * W + px]));
            ts(px, py, 0);
          }
        }
        if (hitS || !hitT) { l.state = LemS.walk; l.skill = LemmingSkill.none; }
        else { l.x += l.dir * 2; }
      }
      return;
    }

    // Miner
    if (l.state == LemS.mine) {
      l.cd -= dt;
      if (l.cd <= 0) {
        l.cd = 0.09;
        bool hitS = false;
        for (int dy = -1; dy <= 3; dy++) for (int dx = -2; dx <= 2; dx++) {
          final px = ix + l.dir * 4 + dx, py = iy + 2 + dy;
          if (stl(px, py)) hitS = true;
          else { if (sol(px, py)) particles.add(_Particle(px.toDouble(), py.toDouble(),
            l.dir * 10.0, -5.0, 0.3, terCol[py * W + px])); ts(px, py, 0); }
        }
        if (hitS) { l.state = LemS.walk; l.skill = LemmingSkill.none; } else { l.x += l.dir * 2; l.y += 2; }
      }
      return;
    }

    // Builder
    if (l.state == LemS.build) {
      l.cd -= dt;
      if (l.cd <= 0) {
        l.cd = 0.16;
        if (l.buildN >= 12) { l.state = LemS.walk; l.skill = LemmingSkill.none; l.dir *= -1; return; }
        for (int dx = 0; dx < 6; dx++) ts(ix + l.dir * dx, iy, 1, 0xFFAA9977);
        l.x += l.dir * 3; l.y -= 1; l.buildN++;
        if (sol((l.x + l.dir * 4).round(), l.y.round() - 3)) {
          l.state = LemS.walk; l.skill = LemmingSkill.none; l.dir *= -1;
        }
      }
      return;
    }

    // Climber
    if (l.state == LemS.climb) {
      l.y -= 14 * dt;
      if (!sol(ix + l.dir, l.y.round()) && !sol(ix + l.dir, l.y.round() + 1)) {
        l.x += l.dir * 3; l.state = LemS.walk;
      }
      if (sol(ix, l.y.round() - 1)) { l.state = LemS.fall; l.dir *= -1; }
      return;
    }

    // Marche
    l.state = LemS.walk;
    final nx = l.x + l.dir * 18 * dt;
    final nix = nx.round();
    if (sol(nix + l.dir, iy) && sol(nix + l.dir, iy - 1) && sol(nix + l.dir, iy - 2)) {
      if (l.pClimb) { l.state = LemS.climb; return; }
      l.dir *= -1; return;
    }
    int step = 0;
    while (sol(nix, (l.y - step).round()) && step < 4) step++;
    if (step > 0 && step <= 3) l.y -= step;
    else if (step > 3) { if (l.pClimb) { l.state = LemS.climb; return; } l.dir *= -1; return; }
    l.x = nx;

    for (final o in lems) {
      if (o == l || !o.alive || o.exited || o.state != LemS.block) continue;
      if ((l.x - o.x).abs() < 5 && (l.y - o.y).abs() < 5) { l.dir *= -1; l.x += l.dir * 6; }
    }
  }

  void assign(double tx, double ty) {
    if (selSkill == LemmingSkill.none) return;
    final c = sk[selSkill] ?? 0; if (c <= 0) return;
    Lem? best; double bestD = 15;
    for (final l in lems) {
      if (!l.alive || l.exited) continue;
      if (selSkill != LemmingSkill.climber && selSkill != LemmingSkill.floater) {
        if (l.skill != LemmingSkill.none && l.state != LemS.walk && l.state != LemS.fall) continue;
      }
      final d = sqrt(pow(l.x - tx, 2) + pow(l.y - ty, 2));
      if (d < bestD) { best = l; bestD = d; }
    }
    if (best == null) return;
    sk[selSkill] = c - 1;
    switch (selSkill) {
      case LemmingSkill.climber: best.pClimb = true;
      case LemmingSkill.floater: best.pFloat = true;
      case LemmingSkill.bomber: best.state = LemS.bomb; best.bombT = 5;
      case LemmingSkill.blocker: best.skill = selSkill; best.state = LemS.block;
      case LemmingSkill.builder: best.skill = selSkill; best.state = LemS.build; best.buildN = 0; best.cd = 0;
      case LemmingSkill.basher: best.skill = selSkill; best.state = LemS.bash; best.cd = 0;
      case LemmingSkill.miner: best.skill = selSkill; best.state = LemS.mine; best.cd = 0;
      case LemmingSkill.digger: best.skill = selSkill; best.state = LemS.dig; best.cd = 0;
      case LemmingSkill.none: break;
    }
  }

  void nuke() => nuked = true;
  void faster() => spawnRate = max(0.12, spawnRate - 0.1);
  void slower() => spawnRate = min(3.0, spawnRate + 0.1);

  void _end() {
    if (saved >= need) {
      score += (timer * 3).toInt();
      if (lvl < 4) { _load(lvl + 1); return; } else { won = true; score += 1000; }
    }
    over = true; onOver(score);
  }

  static const totalLevels = 5;
}

// ============================================================
// PAINTER
// ============================================================
class LemmingsPainter extends CustomPainter {
  final LemmingsGame g;
  LemmingsPainter(this.g);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / LemmingsGame.W;
    final sy = size.height / LemmingsGame.H;

    // Fond
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF000030));

    // Étoiles
    final sp = Paint();
    for (int i = 0; i < 60; i++) {
      final stx = ((i * 97 + 31) % LemmingsGame.W).toDouble();
      final sty = ((i * 53 + 17) % (g.waterLevel - 10)).toDouble();
      final bri = 0.2 + 0.8 * ((sin(g.globalTime * 1.5 + i * 0.7) + 1) / 2);
      sp.color = Color.fromRGBO(100, 130, 200, bri);
      canvas.drawCircle(Offset(stx * sx, sty * sy), 0.5 * sx, sp);
    }

    // Eau animée
    final waterY = g.waterLevel * sy;
    // Vagues
    final wavePath = Path()..moveTo(0, waterY);
    for (double wx = 0; wx <= size.width; wx += 2) {
      final wy = waterY + sin(wx / 15 + g.globalTime * 3) * 1.5 * sy;
      wavePath.lineTo(wx, wy);
    }
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();
    canvas.drawPath(wavePath, Paint()..color = const Color(0xFF1144AA));
    // Reflets
    canvas.drawPath(wavePath, Paint()
      ..color = const Color(0xFF2266CC).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke..strokeWidth = sy);

    // Terrain
    for (int y = 0; y < LemmingsGame.H; y++) {
      for (int x = 0; x < LemmingsGame.W; x++) {
        if (g.tg(x, y) == 0) continue;
        canvas.drawRect(
          Rect.fromLTWH(x * sx, y * sy, sx + 0.5, sy + 0.5),
          Paint()..color = Color(g.terCol[y * LemmingsGame.W + x] | 0xFF000000));
      }
    }

    // Particules
    for (final p in g.particles) {
      canvas.drawCircle(Offset(p.x * sx, p.y * sy), sx * 0.8,
        Paint()..color = Color(p.color | 0xFF000000).withValues(alpha: p.life.clamp(0, 1)));
    }

    // Trappe
    _trap(canvas, g.trapX * sx, g.trapY * sy, sx, sy);
    // Sortie
    _exit(canvas, g.exitX * sx, g.exitY * sy, sx, sy);

    // Lemmings
    for (final l in g.lems) {
      if (l.exited || (!l.alive && l.state != LemS.splat)) continue;
      _lem(canvas, l, sx, sy);
    }

    // Minimap
    _minimap(canvas, size);
  }

  void _minimap(Canvas c, Size size) {
    final mw = 80.0, mh = 36.0;
    final mx = size.width - mw - 4, my = 4.0;
    // Fond
    c.drawRect(Rect.fromLTWH(mx, my, mw, mh),
      Paint()..color = const Color(0xFF000030).withValues(alpha: 0.8));
    c.drawRect(Rect.fromLTWH(mx, my, mw, mh),
      Paint()..color = const Color(0xFF334488)..style = PaintingStyle.stroke..strokeWidth = 1);
    // Terrain miniaturisé
    final msx = mw / LemmingsGame.W, msy = mh / LemmingsGame.H;
    for (int y = 0; y < LemmingsGame.H; y += 3) {
      for (int x = 0; x < LemmingsGame.W; x += 3) {
        if (g.tg(x, y) > 0) {
          c.drawRect(Rect.fromLTWH(mx + x * msx, my + y * msy, msx * 3 + 0.5, msy * 3 + 0.5),
            Paint()..color = Color(g.terCol[y * LemmingsGame.W + x] | 0xFF000000).withValues(alpha: 0.7));
        }
      }
    }
    // Lemmings sur la minimap
    for (final l in g.lems) {
      if (!l.alive || l.exited) continue;
      c.drawCircle(Offset(mx + l.x * msx, my + l.y * msy), 1,
        Paint()..color = const Color(0xFF44FF44));
    }
    // Eau minimap
    c.drawRect(Rect.fromLTWH(mx, my + g.waterLevel * msy, mw, mh - g.waterLevel * msy),
      Paint()..color = const Color(0xFF1144AA).withValues(alpha: 0.5));
  }

  void _trap(Canvas c, double x, double y, double sx, double sy) {
    final w = 20 * sx, h = 8 * sy;
    c.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y - h * 0.5), width: w, height: h), Radius.circular(sx * 2)),
      Paint()..color = const Color(0xFF6A6A9A));
    for (final dx in [-w * 0.35, -w * 0.12, w * 0.12, w * 0.35]) {
      c.drawCircle(Offset(x + dx, y - h * 0.5), sx * 0.7, Paint()..color = const Color(0xFF9999CC));
    }
    if (g.trapOpen) {
      c.drawRect(Rect.fromLTWH(x - 4 * sx, y - sy, 8 * sx, 5 * sy), Paint()..color = const Color(0xFF222244));
    }
  }

  void _exit(Canvas c, double x, double y, double sx, double sy) {
    final w = 16 * sx, h = 18 * sy;
    c.drawRect(Rect.fromLTWH(x - w / 2, y - h, 3 * sx, h), Paint()..color = const Color(0xFF1A1AAA));
    c.drawRect(Rect.fromLTWH(x + w / 2 - 3 * sx, y - h, 3 * sx, h), Paint()..color = const Color(0xFF1A1AAA));
    c.drawRect(Rect.fromLTWH(x - w / 2 + sx, y - h, sx, h), Paint()..color = const Color(0xFF3333CC));
    c.drawArc(Rect.fromCenter(center: Offset(x, y - h), width: w, height: h * 0.5),
      pi, pi, false, Paint()..color = const Color(0xFF4444FF)..style = PaintingStyle.stroke..strokeWidth = 3 * sx);
    // Halo pulsant
    final pulse = 0.3 + 0.15 * sin(g.globalTime * 4);
    c.drawCircle(Offset(x, y - h * 0.5), 6 * sx, Paint()..color = Color.fromRGBO(68, 136, 255, pulse));
    c.drawCircle(Offset(x, y - h * 0.5), 3 * sx, Paint()..color = Color.fromRGBO(136, 187, 255, pulse + 0.1));
  }

  void _lem(Canvas c, Lem l, double sx, double sy) {
    final x = l.x * sx, y = l.y * sy;
    final lw = 2.5 * sx, lh = 5.5 * sy;

    if (l.state == LemS.splat) {
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: lw * 5, height: sy * 2),
        Paint()..color = const Color(0xFF00BB00));
      return;
    }

    const blue = Color(0xFF3333DD);
    const green = Color(0xFF00EE00);
    const skin = Color(0xFFFFBB77);

    final fr = l.fr.floor() % 8;
    final ws = sin(fr / 8 * pi * 2);

    // Jambes
    if (l.state == LemS.walk) {
      final lo = ws * lw * 0.7;
      c.drawLine(Offset(x - lw * 0.2, y - lh * 0.15), Offset(x - lw * 0.3 + lo, y),
        Paint()..color = blue..strokeWidth = sx * 1.3..strokeCap = StrokeCap.round);
      c.drawLine(Offset(x + lw * 0.2, y - lh * 0.15), Offset(x + lw * 0.3 - lo, y),
        Paint()..color = blue..strokeWidth = sx * 1.3..strokeCap = StrokeCap.round);
    } else {
      c.drawRect(Rect.fromLTRB(x - lw * 0.5, y - lh * 0.15, x + lw * 0.5, y), Paint()..color = blue);
    }

    // Corps
    c.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(x - lw, y - lh * 0.72, x + lw, y - lh * 0.12), Radius.circular(sx * 0.5)),
      Paint()..color = blue);
    c.drawRect(Rect.fromLTRB(x - lw * 0.3, y - lh * 0.7, x - lw * 0.1, y - lh * 0.2),
      Paint()..color = const Color(0xFF4444EE));

    // Tête
    final headY = y - lh * 0.82;
    c.drawCircle(Offset(x, headY), lw * 0.7, Paint()..color = skin);

    // Cheveux verts
    final hp = Path()
      ..moveTo(x - lw * 0.9, headY - lw * 0.7 * 0.2)
      ..quadraticBezierTo(x - lw * 0.5, headY - lh * 0.4, x, headY - lh * 0.35)
      ..quadraticBezierTo(x + lw * 0.5, headY - lh * 0.4, x + lw * 0.9, headY - lw * 0.7 * 0.2)
      ..quadraticBezierTo(x + lw * 0.2, headY - lh * 0.15, x, headY - lh * 0.12)
      ..quadraticBezierTo(x - lw * 0.2, headY - lh * 0.15, x - lw * 0.9, headY - lw * 0.7 * 0.2)
      ..close();
    c.drawPath(hp, Paint()..color = green);

    // Yeux
    final ex = x + l.dir * lw * 0.2;
    c.drawCircle(Offset(ex, headY + lw * 0.7 * 0.1), sx * 0.5, Paint()..color = Colors.white);
    c.drawCircle(Offset(ex + l.dir * sx * 0.15, headY + lw * 0.7 * 0.1), sx * 0.25, Paint()..color = Colors.black);

    // Skills FX
    if (l.state == LemS.block) {
      final ap = Paint()..color = skin..strokeWidth = sx..strokeCap = StrokeCap.round;
      c.drawLine(Offset(x, y - lh * 0.5), Offset(x - lw * 2.8, y - lh * 0.6), ap);
      c.drawLine(Offset(x, y - lh * 0.5), Offset(x + lw * 2.8, y - lh * 0.6), ap);
      c.drawCircle(Offset(x - lw * 2.8, y - lh * 0.6), sx, Paint()..color = skin);
      c.drawCircle(Offset(x + lw * 2.8, y - lh * 0.6), sx, Paint()..color = skin);
    }
    if (l.state == LemS.float_) {
      c.drawLine(Offset(x, headY - lh * 0.2), Offset(x, headY - lh * 0.6),
        Paint()..color = const Color(0xFF663300)..strokeWidth = sx * 0.8);
      final up = Path()..moveTo(x - lw * 3.5, headY - lh * 0.5)
        ..quadraticBezierTo(x, headY - lh * 1.3, x + lw * 3.5, headY - lh * 0.5);
      c.drawPath(up, Paint()..color = const Color(0xFFCC44CC)..style = PaintingStyle.stroke..strokeWidth = sx * 2);
    }
    if (l.state == LemS.build) {
      final ph = (l.fr * 2).floor() % 2;
      final ax = x + l.dir * lw * 2.5, ay = y - lh * 0.5 - (ph == 0 ? lh * 0.1 : 0);
      c.drawLine(Offset(x + l.dir * lw, y - lh * 0.5), Offset(ax, ay),
        Paint()..color = skin..strokeWidth = sx..strokeCap = StrokeCap.round);
      c.drawRect(Rect.fromCenter(center: Offset(ax, ay), width: 4 * sx, height: 2 * sy), Paint()..color = const Color(0xFFAA9977));
    }
    if (l.state == LemS.dig || l.state == LemS.mine) {
      final ph = (l.fr * 3).floor() % 2;
      c.drawLine(Offset(x + lw, y - lh * 0.5), Offset(x + lw * 2, y + (ph == 0 ? 0 : lh * 0.15)),
        Paint()..color = Colors.grey..strokeWidth = sx..strokeCap = StrokeCap.round);
    }
    if (l.state == LemS.bash) {
      final ph = (l.fr * 4).floor() % 2;
      final fx = x + l.dir * (lw * 2.5 + (ph == 0 ? lw : 0));
      c.drawLine(Offset(x + l.dir * lw, y - lh * 0.5), Offset(fx, y - lh * 0.5),
        Paint()..color = skin..strokeWidth = sx * 1.2..strokeCap = StrokeCap.round);
    }
    if (l.state == LemS.climb) {
      c.drawLine(Offset(x + l.dir * lw, y - lh * 0.7), Offset(x + l.dir * lw * 2, y - lh * 0.9),
        Paint()..color = skin..strokeWidth = sx..strokeCap = StrokeCap.round);
    }
    if (l.state == LemS.bomb) {
      final blink = (l.bombT * 5).floor() % 2 == 0;
      final tp = TextPainter(text: TextSpan(text: '${l.bombT.ceil()}',
        style: TextStyle(color: blink ? Colors.red : Colors.white, fontSize: 5 * sx, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr)..layout();
      tp.paint(c, Offset(x - tp.width / 2, y - lh - 6 * sy));
      if (blink) c.drawCircle(Offset(x, y - lh * 0.4), lw * 1.5, Paint()..color = Colors.red.withValues(alpha: 0.35));
    }
    if (l.pClimb) c.drawCircle(Offset(x - lw * 1.5, y - lh - 2 * sy), sx * 0.6, Paint()..color = Colors.cyan);
    if (l.pFloat) c.drawCircle(Offset(x + lw * 1.5, y - lh - 2 * sy), sx * 0.6, Paint()..color = const Color(0xFFDD44DD));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
