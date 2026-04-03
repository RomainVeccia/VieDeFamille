import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// === Les 8 compétences classiques ===
enum LemmingSkill {
  none,
  climber,
  floater,
  bomber,
  blocker,
  builder,
  basher,
  miner,
  digger,
}

enum LemmingState {
  walking,
  falling,
  climbing,
  building,
  bashing,
  mining,
  digging,
  blocking,
  floating,
  bombing,
  splatting,
  exiting,
}

class Lemming {
  double x, y;
  int dir; // 1=droite, -1=gauche
  LemmingSkill skill;
  LemmingState state;
  bool alive;
  bool exited;
  double fallDist;
  double animFrame; // frame d'animation continue
  double bomberTimer;
  int buildCount;
  double actionCD;
  bool permClimber;
  bool permFloater;

  Lemming({required this.x, required this.y, this.dir = 1})
      : skill = LemmingSkill.none,
        state = LemmingState.falling,
        alive = true,
        exited = false,
        fallDist = 0,
        animFrame = 0,
        bomberTimer = 5.0,
        buildCount = 0,
        actionCD = 0,
        permClimber = false,
        permFloater = false;
}

/// Moteur Lemmings — rendu haute fidélité
class LemmingsGame {
  static const int tw = 400; // terrain width
  static const int th = 200; // terrain height

  // Terrain pixel — 0=vide, 1=terre, 2=acier, 3=terre sombre
  late Uint8List terrain;
  // Couleur de chaque pixel de terrain (pour un rendu riche)
  late Uint32List terrainColor;

  double trapX = 0, trapY = 0;
  double exitX = 0, exitY = 0;

  final List<Lemming> lemmings = [];
  int totalToSpawn = 0;
  int spawned = 0;
  int saved = 0;
  int dead = 0;
  int required_ = 0;
  double spawnTimer = 0;
  double spawnRate = 1.2;

  final Map<LemmingSkill, int> skills = {};
  LemmingSkill selectedSkill = LemmingSkill.none;

  static const double walkSpd = 15.0;
  static const double fallSpd = 50.0;
  static const double climbSpd = 12.0;
  static const double safeFall = 35.0;

  int score = 0;
  int currentLevel = 0;
  bool gameOver = false;
  bool won = false;
  double timer = 0;
  bool nuked = false;
  double trapAnim = 0;
  bool trapOpen = false;

  final VoidCallback onStateChanged;
  final void Function(int finalScore) onGameOver;
  final Random _rng = Random(42);

  LemmingsGame({
    required this.onStateChanged,
    required this.onGameOver,
  }) {
    _loadLevel(0);
  }

  // === Terrain helpers ===
  int tget(int x, int y) {
    if (x < 0 || x >= tw || y < 0 || y >= th) return 0;
    return terrain[y * tw + x];
  }

  void _tset(int x, int y, int v, [int? color]) {
    if (x < 0 || x >= tw || y < 0 || y >= th) return;
    terrain[y * tw + x] = v;
    if (color != null) terrainColor[y * tw + x] = color;
  }

  bool solid(int x, int y) => tget(x, y) > 0;
  bool _steel(int x, int y) => tget(x, y) == 2;

  void _digCircle(int cx, int cy, int r) {
    for (int dy = -r; dy <= r; dy++) {
      for (int dx = -r; dx <= r; dx++) {
        if (dx * dx + dy * dy <= r * r) {
          final px = cx + dx, py = cy + dy;
          if (!_steel(px, py)) _tset(px, py, 0);
        }
      }
    }
  }

  /// Remplir un rectangle avec couleur naturelle
  void _fill(int x, int y, int w, int h, int type, {bool isSteel = false}) {
    for (int dy = 0; dy < h; dy++) {
      for (int dx = 0; dx < w; dx++) {
        final px = x + dx, py = y + dy;
        if (px < 0 || px >= tw || py < 0 || py >= th) continue;
        final t = isSteel ? 2 : type;
        int c;
        if (isSteel) {
          c = ((px + py) % 2 == 0) ? 0xFF7788AA : 0xFF667799;
        } else {
          final n = ((px * 7 + py * 13) % 6);
          c = switch (n) {
            0 => 0xFF2D8B2D,
            1 => 0xFF1E7A1E,
            2 => 0xFF339933,
            3 => 0xFF267826,
            4 => 0xFF3BA53B,
            _ => 0xFF2A8A2A,
          };
        }
        _tset(px, py, t, c);
      }
    }
  }

  /// Remplir un ovale (pour des formes organiques)
  void _fillOval(int cx, int cy, int rx, int ry, int type) {
    for (int dy = -ry; dy <= ry; dy++) {
      for (int dx = -rx; dx <= rx; dx++) {
        if ((dx * dx) / (rx * rx + 0.01) + (dy * dy) / (ry * ry + 0.01) <= 1) {
          final px = cx + dx, py = cy + dy;
          final n = ((px * 7 + py * 13) % 6);
          final c = switch (n) {
            0 => 0xFF2D8B2D,
            1 => 0xFF1E7A1E,
            2 => 0xFF339933,
            3 => 0xFF267826,
            4 => 0xFF3BA53B,
            _ => 0xFF2A8A2A,
          };
          _tset(px, py, type, c);
        }
      }
    }
  }

  /// Ajouter de l'herbe sur la surface
  void _addGrass() {
    for (int x = 0; x < tw; x++) {
      for (int y = 1; y < th; y++) {
        if (tget(x, y) == 1 && tget(x, y - 1) == 0) {
          // Surface ! herbe vert clair
          final n = (x * 3 + y * 7) % 4;
          final c = switch (n) {
            0 => 0xFF55EE55,
            1 => 0xFF44DD44,
            2 => 0xFF66FF66,
            _ => 0xFF33CC33,
          };
          terrainColor[y * tw + x] = c;
          // Brins d'herbe au-dessus
          if (y >= 2 && tget(x, y - 2) == 0 && (x % 3 == 0)) {
            _tset(x, y - 1, 1, 0xFF44DD44);
          }
        }
      }
    }
  }

  // === Chargement de niveaux ===
  void _loadLevel(int lvl) {
    currentLevel = lvl;
    terrain = Uint8List(tw * th);
    terrainColor = Uint32List(tw * th);
    lemmings.clear();
    spawned = saved = dead = 0;
    spawnTimer = 0;
    nuked = false;
    trapOpen = false;
    trapAnim = 0;

    switch (lvl) {
      case 0:
        _level1();
      case 1:
        _level2();
      case 2:
        _level3();
    }
    _addGrass();
  }

  // Niveau 1 — "Just dig!" — apprendre à creuser
  void _level1() {
    totalToSpawn = 10;
    required_ = 7;
    timer = 120;
    trapX = 60;
    trapY = 30;
    exitX = 340;
    exitY = 168;

    skills.clear();
    skills[LemmingSkill.digger] = 10;
    skills[LemmingSkill.basher] = 3;
    skills[LemmingSkill.builder] = 3;

    // Grande île de départ
    _fillOval(80, 50, 60, 15, 1);
    // Colonne de descente
    _fill(120, 50, 20, 90, 1);
    // Plateforme intermédiaire
    _fillOval(180, 100, 50, 12, 1);
    // Pont vers la droite
    _fill(210, 100, 80, 8, 1);
    // Mur à basher
    _fill(290, 80, 10, 28, 1);
    // Plateforme de sortie
    _fillOval(330, 110, 30, 10, 1);
    // Pilier vers le sol
    _fill(320, 110, 25, 60, 1);
    // Sol principal
    _fill(0, 170, tw, 30, 1);
    // Acier sous la sortie
    _fill(320, 170, 50, 8, 2);
  }

  // Niveau 2 — "Build the bridge" — construction + floater
  void _level2() {
    totalToSpawn = 15;
    required_ = 10;
    timer = 180;
    trapX = 40;
    trapY = 20;
    exitX = 360;
    exitY = 168;

    skills.clear();
    skills[LemmingSkill.builder] = 8;
    skills[LemmingSkill.floater] = 5;
    skills[LemmingSkill.blocker] = 3;
    skills[LemmingSkill.digger] = 4;
    skills[LemmingSkill.miner] = 2;
    skills[LemmingSkill.basher] = 2;

    // Plateforme de départ
    _fillOval(60, 35, 35, 10, 1);
    // Gouffre — faut construire un pont !
    // Île flottante
    _fillOval(155, 50, 25, 8, 1);
    // Autre île
    _fillOval(240, 65, 30, 10, 1);
    // Mur épais
    _fill(280, 40, 12, 40, 1);
    // Plateforme après le mur
    _fillOval(320, 75, 35, 10, 1);
    // Descente
    _fill(340, 75, 12, 95, 1);
    // Sol
    _fill(0, 170, tw, 30, 1);
    // Trou mortel dans le sol
    for (int x = 130; x < 180; x++) {
      for (int y = 170; y < 200; y++) {
        _tset(x, y, 0);
      }
    }
    _fill(340, 170, 60, 8, 2); // acier sortie
  }

  // Niveau 3 — "The hard way" — tout utiliser
  void _level3() {
    totalToSpawn = 20;
    required_ = 15;
    timer = 300;
    trapX = 30;
    trapY = 15;
    exitX = 370;
    exitY = 168;

    skills.clear();
    skills[LemmingSkill.climber] = 4;
    skills[LemmingSkill.floater] = 5;
    skills[LemmingSkill.bomber] = 3;
    skills[LemmingSkill.blocker] = 4;
    skills[LemmingSkill.builder] = 6;
    skills[LemmingSkill.basher] = 5;
    skills[LemmingSkill.miner] = 4;
    skills[LemmingSkill.digger] = 5;

    // Départ en hauteur
    _fillOval(50, 28, 30, 8, 1);
    // Grand mur (faut climber ou basher)
    _fill(85, 0, 10, 60, 1);
    // Plateforme cachée derrière le mur
    _fillOval(130, 50, 40, 10, 1);
    // Stalactites / piliers
    _fill(160, 0, 8, 35, 1);
    _fill(185, 0, 8, 25, 1);
    // Plateforme milieu
    _fillOval(200, 80, 35, 10, 1);
    // Acier (pas creusable — faut contourner)
    _fill(235, 60, 8, 30, 2);
    // Terrain ondulé
    _fillOval(280, 90, 40, 12, 1);
    // Mur final
    _fill(330, 70, 10, 30, 1);
    // Plateforme de sortie
    _fillOval(360, 100, 25, 8, 1);
    _fill(350, 100, 30, 70, 1);
    // Sol
    _fill(0, 170, tw, 30, 1);
    // Trous mortels
    for (int x = 0; x < 40; x++) {
      for (int y = 170; y < 200; y++) {
        _tset(x, y, 0);
      }
    }
    for (int x = 100; x < 140; x++) {
      for (int y = 170; y < 200; y++) {
        _tset(x, y, 0);
      }
    }
    _fill(350, 170, 50, 8, 2);
  }

  // === Boucle de jeu ===
  void update(double dt) {
    if (gameOver) return;

    timer -= dt;
    if (timer <= 0) {
      timer = 0;
      _endLevel();
      return;
    }

    // Trappe
    trapAnim += dt;
    if (trapAnim > 0.8 && !trapOpen) trapOpen = true;

    // Spawn
    if (trapOpen) {
      spawnTimer += dt;
      if (spawnTimer >= spawnRate && spawned < totalToSpawn) {
        spawnTimer = 0;
        spawned++;
        lemmings.add(Lemming(x: trapX, y: trapY));
      }
    }

    // Update lemmings
    for (final l in lemmings) {
      if (!l.alive || l.exited) continue;
      l.animFrame += dt * 10;
      l.actionCD = max(0, l.actionCD - dt);
      _updateLem(l, dt);
    }

    // Nuke
    if (nuked) {
      for (final l in lemmings) {
        if (l.alive && !l.exited && l.state != LemmingState.bombing) {
          l.state = LemmingState.bombing;
          l.bomberTimer = 0.3 + _rng.nextDouble() * 2.5;
        }
      }
    }

    // Fin ?
    if (spawned >= totalToSpawn && lemmings.every((l) => !l.alive || l.exited)) {
      _endLevel();
    }

    onStateChanged();
  }

  void _updateLem(Lemming l, double dt) {
    final ix = l.x.round(), iy = l.y.round();

    // Sortie
    if ((l.x - exitX).abs() < 5 && (l.y - exitY).abs() < 5) {
      l.state = LemmingState.exiting;
      l.exited = true;
      saved++;
      score += 50;
      return;
    }

    // Hors limites
    if (l.y > th + 5 || l.x < -5 || l.x > tw + 5) {
      l.alive = false;
      dead++;
      return;
    }

    // Bomber
    if (l.state == LemmingState.bombing) {
      l.bomberTimer -= dt;
      if (l.bomberTimer <= 0) {
        _digCircle(ix, iy, 10);
        l.alive = false;
        dead++;
      }
      return;
    }

    // Blocker
    if (l.state == LemmingState.blocking) return;

    // Sol ?
    final onGround = solid(ix, iy + 1) || solid(ix - 1, iy + 1) || solid(ix + 1, iy + 1);

    if (!onGround && l.state != LemmingState.climbing) {
      if (l.permFloater && l.fallDist > 15) {
        l.state = LemmingState.floating;
        l.y += fallSpd * 0.25 * dt;
        l.fallDist += fallSpd * 0.25 * dt;
      } else {
        l.state = LemmingState.falling;
        l.y += fallSpd * dt;
        l.fallDist += fallSpd * dt;
      }
      return;
    }

    // Atterrissage
    if (l.state == LemmingState.falling || l.state == LemmingState.floating) {
      // Snap au sol
      for (int i = 0; i < 5; i++) {
        if (solid(l.x.round(), l.y.round())) {
          l.y -= 1;
        } else {
          break;
        }
      }
      if (l.fallDist > safeFall && !l.permFloater) {
        l.state = LemmingState.splatting;
        l.alive = false;
        dead++;
        return;
      }
      l.fallDist = 0;
      l.state = LemmingState.walking;
    }

    // === Compétences actives ===

    // Digger
    if (l.state == LemmingState.digging) {
      l.actionCD -= dt;
      if (l.actionCD <= 0) {
        l.actionCD = 0.12;
        final dy = l.y.round() + 1;
        if (_steel(ix, dy)) {
          l.state = LemmingState.walking;
          l.skill = LemmingSkill.none;
          return;
        }
        for (int dx2 = -3; dx2 <= 3; dx2++) {
          for (int dy2 = 0; dy2 < 2; dy2++) {
            if (!_steel(ix + dx2, dy + dy2)) _tset(ix + dx2, dy + dy2, 0);
          }
        }
        l.y += 2;
      }
      return;
    }

    // Basher
    if (l.state == LemmingState.bashing) {
      l.actionCD -= dt;
      if (l.actionCD <= 0) {
        l.actionCD = 0.1;
        bool hitSteel = false, hitTerrain = false;
        for (int dy2 = -5; dy2 <= 1; dy2++) {
          for (int dx2 = 1; dx2 <= 4; dx2++) {
            final px = ix + l.dir * dx2, py = iy + dy2;
            if (_steel(px, py)) {
              hitSteel = true;
            } else if (solid(px, py)) {
              hitTerrain = true;
              _tset(px, py, 0);
            }
          }
        }
        if (hitSteel || !hitTerrain) {
          l.state = LemmingState.walking;
          l.skill = LemmingSkill.none;
        } else {
          l.x += l.dir * 2;
        }
      }
      return;
    }

    // Miner
    if (l.state == LemmingState.mining) {
      l.actionCD -= dt;
      if (l.actionCD <= 0) {
        l.actionCD = 0.12;
        bool hitSteel = false;
        for (int dy2 = -1; dy2 <= 3; dy2++) {
          for (int dx2 = -2; dx2 <= 2; dx2++) {
            final px = ix + l.dir * 3 + dx2, py = iy + 2 + dy2;
            if (_steel(px, py)) {
              hitSteel = true;
            } else {
              _tset(px, py, 0);
            }
          }
        }
        if (hitSteel) {
          l.state = LemmingState.walking;
          l.skill = LemmingSkill.none;
        } else {
          l.x += l.dir * 2;
          l.y += 2;
        }
      }
      return;
    }

    // Builder
    if (l.state == LemmingState.building) {
      l.actionCD -= dt;
      if (l.actionCD <= 0) {
        l.actionCD = 0.2;
        if (l.buildCount >= 12) {
          l.state = LemmingState.walking;
          l.skill = LemmingSkill.none;
          l.dir *= -1;
          return;
        }
        // Poser 4 pixels de marche
        for (int dx2 = 0; dx2 < 5; dx2++) {
          final bx = ix + l.dir * dx2;
          final by = iy;
          if (bx >= 0 && bx < tw && by >= 0 && by < th) {
            _tset(bx, by, 1, 0xFF998866);
          }
        }
        l.x += l.dir * 3;
        l.y -= 1;
        l.buildCount++;
        // Plafond ?
        if (solid((l.x + l.dir * 3).round(), l.y.round() - 3)) {
          l.state = LemmingState.walking;
          l.skill = LemmingSkill.none;
          l.dir *= -1;
        }
      }
      return;
    }

    // Climber
    if (l.state == LemmingState.climbing) {
      l.y -= climbSpd * dt;
      // Haut du mur atteint ?
      if (!solid(ix + l.dir, l.y.round()) && !solid(ix + l.dir, l.y.round() + 1)) {
        l.x += l.dir * 3;
        l.state = LemmingState.walking;
      }
      // Plafond ?
      if (solid(ix, l.y.round() - 1)) {
        l.state = LemmingState.falling;
        l.dir *= -1;
      }
      return;
    }

    // === Marche ===
    l.state = LemmingState.walking;
    final nx = l.x + l.dir * walkSpd * dt;
    final nix = nx.round();

    // Mur ?
    if (solid(nix + l.dir, iy) && solid(nix + l.dir, iy - 1) && solid(nix + l.dir, iy - 2)) {
      if (l.permClimber) {
        l.state = LemmingState.climbing;
        return;
      }
      l.dir *= -1;
      return;
    }

    // Montée de marche (max 3 pixels)
    int stepUp = 0;
    while (solid(nix, (l.y - stepUp).round()) && stepUp < 4) {
      stepUp++;
    }
    if (stepUp > 0 && stepUp <= 3) {
      l.y -= stepUp;
    } else if (stepUp > 3) {
      // Mur trop haut
      if (l.permClimber) {
        l.state = LemmingState.climbing;
        return;
      }
      l.dir *= -1;
      return;
    }

    l.x = nx;

    // Collision blockers
    for (final other in lemmings) {
      if (other == l || !other.alive || other.exited) continue;
      if (other.state != LemmingState.blocking) continue;
      if ((l.x - other.x).abs() < 5 && (l.y - other.y).abs() < 5) {
        l.dir *= -1;
        l.x += l.dir * 6;
      }
    }
  }

  // === Assignation de skill ===
  void assignSkill(double tapX, double tapY) {
    if (selectedSkill == LemmingSkill.none) return;
    final count = skills[selectedSkill] ?? 0;
    if (count <= 0) return;

    Lemming? best;
    double bestD = 12.0;
    for (final l in lemmings) {
      if (!l.alive || l.exited) continue;
      if (selectedSkill != LemmingSkill.climber &&
          selectedSkill != LemmingSkill.floater) {
        if (l.skill != LemmingSkill.none &&
            l.state != LemmingState.walking &&
            l.state != LemmingState.falling) {
          continue;
        }
      }
      final d = sqrt(pow(l.x - tapX, 2) + pow(l.y - tapY, 2));
      if (d < bestD) {
        best = l;
        bestD = d;
      }
    }
    if (best == null) return;

    skills[selectedSkill] = count - 1;
    switch (selectedSkill) {
      case LemmingSkill.climber:
        best.permClimber = true;
      case LemmingSkill.floater:
        best.permFloater = true;
      case LemmingSkill.bomber:
        best.state = LemmingState.bombing;
        best.bomberTimer = 5.0;
      case LemmingSkill.blocker:
        best.skill = selectedSkill;
        best.state = LemmingState.blocking;
      case LemmingSkill.builder:
        best.skill = selectedSkill;
        best.state = LemmingState.building;
        best.buildCount = 0;
        best.actionCD = 0;
      case LemmingSkill.basher:
        best.skill = selectedSkill;
        best.state = LemmingState.bashing;
        best.actionCD = 0;
      case LemmingSkill.miner:
        best.skill = selectedSkill;
        best.state = LemmingState.mining;
        best.actionCD = 0;
      case LemmingSkill.digger:
        best.skill = selectedSkill;
        best.state = LemmingState.digging;
        best.actionCD = 0;
      case LemmingSkill.none:
        break;
    }
  }

  void nuke() => nuked = true;
  void fasterRate() => spawnRate = max(0.2, spawnRate - 0.15);
  void slowerRate() => spawnRate = min(3.0, spawnRate + 0.15);

  void _endLevel() {
    if (saved >= required_) {
      score += (timer * 3).toInt();
      if (currentLevel < 2) {
        _loadLevel(currentLevel + 1);
        return;
      } else {
        won = true;
        score += 500;
      }
    }
    gameOver = true;
    onGameOver(score);
  }
}

// =============================================================
// PAINTER — rendu fidèle Lemmings original
// =============================================================
class LemmingsPainter extends CustomPainter {
  final LemmingsGame game;
  LemmingsPainter(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / LemmingsGame.tw;
    final sy = size.height / LemmingsGame.th;

    // Fond bleu nuit
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF000033),
    );

    // Étoiles
    final starPaint = Paint()..color = const Color(0xFF445588);
    for (int i = 0; i < 40; i++) {
      final stx = ((i * 97 + 31) % LemmingsGame.tw).toDouble() * sx;
      final sty = ((i * 53 + 17) % (LemmingsGame.th ~/ 2)).toDouble() * sy;
      canvas.drawCircle(Offset(stx, sty), 0.5 * sx, starPaint);
    }

    // Terrain — rendu avec les couleurs stockées
    for (int y = 0; y < LemmingsGame.th; y++) {
      for (int x = 0; x < LemmingsGame.tw; x++) {
        final t = game.tget(x, y);
        if (t == 0) continue;
        final c = game.terrainColor[y * LemmingsGame.tw + x];
        canvas.drawRect(
          Rect.fromLTWH(x * sx, y * sy, sx + 0.5, sy + 0.5),
          Paint()..color = Color(c | 0xFF000000),
        );
      }
    }

    // Trappe
    _drawTrap(canvas, game.trapX * sx, game.trapY * sy, sx, sy);
    // Sortie
    _drawExit(canvas, game.exitX * sx, game.exitY * sy, sx, sy);

    // Lemmings
    for (final l in game.lemmings) {
      if (l.exited) continue;
      if (!l.alive && l.state != LemmingState.splatting) continue;
      _drawLem(canvas, l, sx, sy);
    }
  }

  void _drawTrap(Canvas canvas, double x, double y, double sx, double sy) {
    // Trappe métallique style original
    final w = 16 * sx, h = 6 * sy;
    final rect = Rect.fromCenter(center: Offset(x, y - h), width: w, height: h);
    // Corps
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(sx)),
      Paint()..color = const Color(0xFF8888BB),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(sx)),
      Paint()
        ..color = const Color(0xFFAAAADD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sx * 0.5,
    );
    // Ouverture
    if (game.trapOpen) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 6 * sx, height: 4 * sy),
        Paint()..color = const Color(0xFF333355),
      );
    }
  }

  void _drawExit(Canvas canvas, double x, double y, double sx, double sy) {
    // Arche bleue lumineuse (comme l'original)
    final w = 14 * sx, h = 16 * sy;
    // Piliers
    canvas.drawRect(
      Rect.fromLTWH(x - w / 2, y - h, 3 * sx, h),
      Paint()..color = const Color(0xFF2222AA),
    );
    canvas.drawRect(
      Rect.fromLTWH(x + w / 2 - 3 * sx, y - h, 3 * sx, h),
      Paint()..color = const Color(0xFF2222AA),
    );
    // Arc
    canvas.drawArc(
      Rect.fromCenter(center: Offset(x, y - h), width: w, height: h * 0.6),
      pi,
      pi,
      false,
      Paint()
        ..color = const Color(0xFF4444FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * sx,
    );
    // Lueur
    canvas.drawCircle(
      Offset(x, y - h * 0.5),
      4 * sx,
      Paint()..color = const Color(0xFF4488FF).withValues(alpha: 0.4),
    );
    // Bannière "HOME"
    final tp = TextPainter(
      text: TextSpan(
        text: 'HOME',
        style: TextStyle(
          color: const Color(0xFF88BBFF),
          fontSize: 3.5 * sx,
          fontWeight: FontWeight.bold,
          letterSpacing: sx,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - h - 5 * sy));
  }

  void _drawLem(Canvas canvas, Lemming l, double sx, double sy) {
    final x = l.x * sx;
    final y = l.y * sy;
    // Le lemming fait ~4px large x 8px haut dans l'original
    final lw = 2.5 * sx; // demi-largeur
    final lh = 5.0 * sy; // hauteur totale

    // Splat
    if (l.state == LemmingState.splatting) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: lw * 4, height: sy * 2),
        Paint()..color = const Color(0xFF00CC00),
      );
      return;
    }

    // Couleurs classiques
    const blue = Color(0xFF4444FF);
    const green = Color(0xFF00FF00);
    const skin = Color(0xFFFFCC88);

    // Animation de marche
    final frame = l.animFrame.floor() % 8;
    final walkCycle = sin(frame / 8 * pi * 2);

    // === Corps (tunique bleue) ===
    final bodyTop = y - lh * 0.7;
    final bodyBot = y - lh * 0.1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(x - lw, bodyTop, x + lw, bodyBot),
        Radius.circular(sx * 0.5),
      ),
      Paint()..color = blue,
    );

    // === Jambes (animation marche) ===
    if (l.state == LemmingState.walking) {
      final legOff = walkCycle * lw * 0.6;
      canvas.drawLine(
        Offset(x - lw * 0.3, bodyBot),
        Offset(x - lw * 0.3 + legOff, y),
        Paint()
          ..color = blue
          ..strokeWidth = sx * 1.2
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(x + lw * 0.3, bodyBot),
        Offset(x + lw * 0.3 - legOff, y),
        Paint()
          ..color = blue
          ..strokeWidth = sx * 1.2
          ..strokeCap = StrokeCap.round,
      );
      // Pieds
      canvas.drawCircle(Offset(x - lw * 0.3 + legOff, y), sx * 0.8,
          Paint()..color = blue);
      canvas.drawCircle(Offset(x + lw * 0.3 - legOff, y), sx * 0.8,
          Paint()..color = blue);
    } else {
      // Debout
      canvas.drawRect(
        Rect.fromLTRB(x - lw * 0.6, bodyBot, x + lw * 0.6, y),
        Paint()..color = blue,
      );
    }

    // === Tête (peau) ===
    final headY = y - lh * 0.8;
    final headR = lw * 0.7;
    canvas.drawCircle(Offset(x, headY), headR, Paint()..color = skin);

    // === Cheveux verts (la signature !) ===
    // Touffe de cheveux sur le dessus
    final hairPath = Path();
    hairPath.moveTo(x - lw * 0.8, headY);
    hairPath.quadraticBezierTo(x - lw * 0.3, headY - lh * 0.35, x, headY - lh * 0.28);
    hairPath.quadraticBezierTo(x + lw * 0.3, headY - lh * 0.35, x + lw * 0.8, headY);
    hairPath.quadraticBezierTo(x + lw * 0.2, headY - lh * 0.15, x - lw * 0.2, headY - lh * 0.15);
    hairPath.close();
    canvas.drawPath(hairPath, Paint()..color = green);

    // === Yeux ===
    final eyeX = x + l.dir * lw * 0.25;
    canvas.drawCircle(
      Offset(eyeX, headY),
      sx * 0.5,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(eyeX + l.dir * sx * 0.15, headY),
      sx * 0.25,
      Paint()..color = Colors.black,
    );

    // === Effets spéciaux des compétences ===

    // Blocker — bras écartés
    if (l.state == LemmingState.blocking) {
      final armPaint = Paint()
        ..color = skin
        ..strokeWidth = sx * 1.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, bodyTop + lh * 0.15),
        Offset(x - lw * 2.5, bodyTop),
        armPaint,
      );
      canvas.drawLine(
        Offset(x, bodyTop + lh * 0.15),
        Offset(x + lw * 2.5, bodyTop),
        armPaint,
      );
      // Mains
      canvas.drawCircle(Offset(x - lw * 2.5, bodyTop), sx, Paint()..color = skin);
      canvas.drawCircle(Offset(x + lw * 2.5, bodyTop), sx, Paint()..color = skin);
    }

    // Floater — parapluie
    if (l.state == LemmingState.floating) {
      // Manche
      canvas.drawLine(
        Offset(x, headY - lh * 0.2),
        Offset(x, headY - lh * 0.6),
        Paint()
          ..color = const Color(0xFF884422)
          ..strokeWidth = sx * 0.8,
      );
      // Toile du parapluie
      final umbPath = Path()
        ..moveTo(x - lw * 3, headY - lh * 0.5)
        ..quadraticBezierTo(x, headY - lh * 1.2, x + lw * 3, headY - lh * 0.5);
      canvas.drawPath(
        umbPath,
        Paint()
          ..color = const Color(0xFFFF44FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sx * 1.5,
      );
      canvas.drawPath(umbPath, Paint()..color = const Color(0xFFFF44FF).withValues(alpha: 0.3));
    }

    // Builder — bras avec brique
    if (l.state == LemmingState.building) {
      final brickPhase = (l.animFrame * 2).floor() % 2;
      final armEndX = x + l.dir * lw * 2;
      final armEndY = bodyTop - (brickPhase == 0 ? lh * 0.1 : 0);
      canvas.drawLine(
        Offset(x + l.dir * lw, bodyTop + lh * 0.1),
        Offset(armEndX, armEndY),
        Paint()
          ..color = skin
          ..strokeWidth = sx * 0.8,
      );
      // Brique
      canvas.drawRect(
        Rect.fromCenter(center: Offset(armEndX, armEndY), width: 3 * sx, height: 2 * sy),
        Paint()..color = const Color(0xFF998866),
      );
    }

    // Digger — pioche animée
    if (l.state == LemmingState.digging) {
      final pickPhase = (l.animFrame * 3).floor() % 2;
      canvas.drawLine(
        Offset(x + lw, bodyTop + lh * 0.1),
        Offset(x + lw * 2, y + (pickPhase == 0 ? 0 : lh * 0.2)),
        Paint()
          ..color = const Color(0xFF888888)
          ..strokeWidth = sx * 0.8
          ..strokeCap = StrokeCap.round,
      );
    }

    // Basher — poing animé
    if (l.state == LemmingState.bashing) {
      final bashPhase = (l.animFrame * 4).floor() % 2;
      final fistX = x + l.dir * (lw * 2 + (bashPhase == 0 ? lw : 0));
      canvas.drawLine(
        Offset(x + l.dir * lw, bodyTop + lh * 0.15),
        Offset(fistX, bodyTop + lh * 0.15),
        Paint()
          ..color = skin
          ..strokeWidth = sx * 1.2
          ..strokeCap = StrokeCap.round,
      );
    }

    // Bomber — compteur rouge
    if (l.state == LemmingState.bombing) {
      final blink = (l.bomberTimer * 5).floor() % 2 == 0;
      // Compte à rebours
      final tp = TextPainter(
        text: TextSpan(
          text: '${l.bomberTimer.ceil()}',
          style: TextStyle(
            color: blink ? Colors.red : Colors.white,
            fontSize: 4 * sx,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, headY - lh * 0.5));
      // Corps clignotant
      if (blink) {
        canvas.drawCircle(
          Offset(x, bodyTop + lh * 0.15),
          lw * 1.2,
          Paint()..color = Colors.red.withValues(alpha: 0.4),
        );
      }
    }

    // Climber — agrippé au mur
    if (l.state == LemmingState.climbing) {
      canvas.drawLine(
        Offset(x + l.dir * lw, bodyTop),
        Offset(x + l.dir * lw * 2, bodyTop - lh * 0.2),
        Paint()
          ..color = skin
          ..strokeWidth = sx
          ..strokeCap = StrokeCap.round,
      );
    }

    // Indicateurs permanents (petits dots)
    if (l.permClimber) {
      canvas.drawCircle(
        Offset(x - lw * 1.5, headY - lh * 0.3),
        sx * 0.6,
        Paint()..color = Colors.cyan,
      );
    }
    if (l.permFloater) {
      canvas.drawCircle(
        Offset(x + lw * 1.5, headY - lh * 0.3),
        sx * 0.6,
        Paint()..color = const Color(0xFFFF44FF),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
