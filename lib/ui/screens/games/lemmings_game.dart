import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// === Les 8 compétences classiques ===
enum LemmingSkill {
  none,
  climber, // escalade les murs verticaux
  floater, // parapluie, survit aux chutes
  bomber, // explose après 5s, creuse un trou
  blocker, // bras écartés, bloque les autres
  builder, // construit un escalier diagonal (12 marches)
  basher, // creuse horizontalement
  miner, // creuse en diagonale vers le bas
  digger, // creuse droit vers le bas
}

// === États d'animation ===
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
  bombing, // compte à rebours avant explosion
  dying,
  exiting, // animation de sortie
  splat, // mort par chute
}

/// Un lemming individuel
class Lemming {
  double x, y;
  int dir; // 1 droite, -1 gauche
  LemmingSkill skill;
  LemmingState state;
  bool alive;
  bool exited;
  double fallDist;
  double animTimer; // timer d'animation
  double bomberTimer; // compte à rebours bombe (5s)
  int buildCount; // marches construites (max 12)
  double actionCooldown;
  bool hasFloater; // le floater est permanent
  bool hasClimber; // le climber est permanent

  Lemming({
    required this.x,
    required this.y,
    this.dir = 1,
  })  : skill = LemmingSkill.none,
        state = LemmingState.falling,
        alive = true,
        exited = false,
        fallDist = 0,
        animTimer = 0,
        bomberTimer = 5.0,
        buildCount = 0,
        actionCooldown = 0,
        hasFloater = false,
        hasClimber = false;
}

/// Moteur de jeu Lemmings fidèle à l'original
class LemmingsGame {
  // Résolution du terrain (pixel-based comme l'original)
  static const int terrainW = 320;
  static const int terrainH = 160;

  // Le terrain — chaque pixel est solide (true) ou vide (false)
  late Uint8List terrain; // 0 = vide, 1 = terre, 2 = acier (indestructible)

  // Positions clés
  double trapX = 0, trapY = 0; // trappe d'entrée
  double exitX = 0, exitY = 0; // sortie

  // Lemmings
  final List<Lemming> lemmings = [];
  int totalToSpawn = 0;
  int spawned = 0;
  int saved = 0;
  int dead = 0;
  int required_ = 0;
  double spawnTimer = 0;
  double spawnRate = 1.5; // secondes entre chaque spawn

  // Compétences disponibles
  final Map<LemmingSkill, int> skills = {};
  LemmingSkill selectedSkill = LemmingSkill.none;

  // Paramètres physique
  static const double walkSpeed = 18.0;
  static const double fallSpeed = 40.0;
  static const double climbSpeed = 16.0;
  static const double maxSafeFall = 30.0; // pixels
  static const int buildMax = 12;

  // État
  int score = 0;
  int currentLevel = 0;
  bool gameOver = false;
  bool won = false;
  double timer = 0;
  bool nuked = false;
  double trapAnimTimer = 0;
  bool trapOpen = false;

  final VoidCallback onStateChanged;
  final void Function(int finalScore) onGameOver;

  LemmingsGame({
    required this.onStateChanged,
    required this.onGameOver,
  }) {
    _loadLevel(0);
  }

  // === Accès terrain ===
  int _tget(int x, int y) {
    if (x < 0 || x >= terrainW || y < 0 || y >= terrainH) return 0;
    return terrain[y * terrainW + x];
  }

  void _tset(int x, int y, int v) {
    if (x < 0 || x >= terrainW || y < 0 || y >= terrainH) return;
    terrain[y * terrainW + x] = v;
  }

  bool _solid(int x, int y) => _tget(x, y) > 0;
  bool _steel(int x, int y) => _tget(x, y) == 2;

  /// Creuser un cercle dans le terrain
  void _dig(int cx, int cy, int radius) {
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        if (dx * dx + dy * dy <= radius * radius) {
          final px = cx + dx;
          final py = cy + dy;
          if (!_steel(px, py)) _tset(px, py, 0);
        }
      }
    }
  }

  /// Creuser un rectangle
  void _digRect(int x, int y, int w, int h) {
    for (int dy = 0; dy < h; dy++) {
      for (int dx = 0; dx < w; dx++) {
        if (!_steel(x + dx, y + dy)) _tset(x + dx, y + dy, 0);
      }
    }
  }

  // === Chargement de niveau ===
  void _loadLevel(int level) {
    currentLevel = level;
    terrain = Uint8List(terrainW * terrainH);
    lemmings.clear();
    spawned = 0;
    saved = 0;
    dead = 0;
    spawnTimer = 0;
    nuked = false;
    trapOpen = false;
    trapAnimTimer = 0;

    switch (level) {
      case 0:
        _buildLevel1();
      case 1:
        _buildLevel2();
      case 2:
        _buildLevel3();
    }
  }

  // Niveau 1 — "Just dig!" (facile, creuser pour descendre)
  void _buildLevel1() {
    totalToSpawn = 10;
    required_ = 7;
    timer = 120;
    trapX = 50;
    trapY = 15;
    exitX = 260;
    exitY = 138;
    skills.clear();
    skills[LemmingSkill.digger] = 10;
    skills[LemmingSkill.builder] = 5;
    skills[LemmingSkill.basher] = 3;
    skills[LemmingSkill.blocker] = 2;

    // Sol principal en haut
    _fillRect(0, 30, 140, 10, 1);
    // Pilier de soutien
    _fillRect(130, 30, 10, 50, 1);
    // Plateforme milieu
    _fillRect(100, 80, 120, 8, 1);
    // Descente vers la sortie
    _fillRect(180, 88, 10, 52, 1);
    // Sol du bas
    _fillRect(0, 140, terrainW, 20, 1);
    // Plateforme de la sortie
    _fillRect(230, 140, 60, 5, 2); // acier
    // Mur gauche de la sortie
    _fillRect(228, 100, 5, 40, 1);
    // Petit obstacle à basher
    _fillRect(70, 30, 8, 0, 1);
  }

  // Niveau 2 — "Build to survive" (construire des ponts)
  void _buildLevel2() {
    totalToSpawn = 15;
    required_ = 10;
    timer = 180;
    trapX = 30;
    trapY = 10;
    exitX = 280;
    exitY = 138;
    skills.clear();
    skills[LemmingSkill.builder] = 8;
    skills[LemmingSkill.blocker] = 3;
    skills[LemmingSkill.digger] = 4;
    skills[LemmingSkill.basher] = 3;
    skills[LemmingSkill.floater] = 5;
    skills[LemmingSkill.miner] = 2;

    // Plateforme de départ
    _fillRect(10, 25, 60, 8, 1);
    // Trou — il faut construire !
    // Plateforme 2
    _fillRect(100, 45, 50, 8, 1);
    // Trou
    // Plateforme 3
    _fillRect(170, 65, 50, 8, 1);
    // Mur à basher
    _fillRect(220, 45, 8, 28, 1);
    // Plateforme 4
    _fillRect(228, 65, 50, 8, 1);
    // Descente
    _fillRect(270, 73, 8, 30, 1);
    // Plateforme avant sortie
    _fillRect(240, 100, 70, 8, 1);
    // Sol
    _fillRect(0, 140, terrainW, 20, 1);
    // Acier sous la sortie
    _fillRect(260, 140, 30, 5, 2);
    // Piège — trou dans le sol
    for (int x = 120; x < 160; x++) {
      _tset(x, 140, 0);
      _tset(x, 141, 0);
      _tset(x, 142, 0);
    }
  }

  // Niveau 3 — "The hard way" (combinaison de tout)
  void _buildLevel3() {
    totalToSpawn = 20;
    required_ = 15;
    timer = 240;
    trapX = 20;
    trapY = 8;
    exitX = 290;
    exitY = 138;
    skills.clear();
    skills[LemmingSkill.climber] = 3;
    skills[LemmingSkill.floater] = 5;
    skills[LemmingSkill.bomber] = 3;
    skills[LemmingSkill.blocker] = 4;
    skills[LemmingSkill.builder] = 6;
    skills[LemmingSkill.basher] = 5;
    skills[LemmingSkill.miner] = 3;
    skills[LemmingSkill.digger] = 5;

    // Plateforme départ
    _fillRect(5, 22, 50, 8, 1);
    // Grand mur
    _fillRect(55, 0, 8, 50, 1);
    // Plateforme après le mur
    _fillRect(55, 42, 80, 8, 1);
    // Trou mortel
    // Plateforme îlot
    _fillRect(155, 55, 30, 6, 1);
    // Descente en acier (pas creusable)
    _fillRect(185, 55, 5, 40, 2);
    // Grande plateforme
    _fillRect(120, 90, 100, 8, 1);
    // Mur à miner
    _fillRect(220, 80, 8, 18, 1);
    // Plateforme haute droite
    _fillRect(228, 80, 60, 8, 1);
    // Pilier
    _fillRect(260, 88, 8, 52, 1);
    // Sol
    _fillRect(0, 140, terrainW, 20, 1);
    _fillRect(270, 140, 40, 5, 2); // acier sortie
    // Piège à gauche
    for (int x = 0; x < 30; x++) {
      _tset(x, 140, 0);
      _tset(x, 141, 0);
    }
  }

  void _fillRect(int x, int y, int w, int h, int val) {
    for (int dy = 0; dy < h; dy++) {
      for (int dx = 0; dx < w; dx++) {
        _tset(x + dx, y + dy, val);
      }
    }
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

    // Animation trappe
    trapAnimTimer += dt;
    if (trapAnimTimer > 1.0 && !trapOpen) trapOpen = true;

    // Spawn
    if (trapOpen) {
      spawnTimer += dt;
      if (spawnTimer >= spawnRate && spawned < totalToSpawn) {
        spawnTimer = 0;
        spawned++;
        lemmings.add(Lemming(x: trapX, y: trapY));
      }
    }

    // Update chaque lemming
    for (final lem in lemmings) {
      if (!lem.alive || lem.exited) continue;
      lem.animTimer += dt;
      lem.actionCooldown = max(0, lem.actionCooldown - dt);
      _updateLemming(lem, dt);
    }

    // Nuke — tous les lemmings explosent
    if (nuked) {
      for (final lem in lemmings) {
        if (lem.alive && !lem.exited && lem.state != LemmingState.bombing) {
          lem.state = LemmingState.bombing;
          lem.bomberTimer = 0.5 + Random().nextDouble() * 2;
        }
      }
    }

    // Vérifier fin
    final allProcessed = spawned >= totalToSpawn &&
        lemmings.every((l) => !l.alive || l.exited);
    if (allProcessed) _endLevel();

    onStateChanged();
  }

  void _updateLemming(Lemming lem, double dt) {
    final ix = lem.x.round();
    final iy = lem.y.round();

    // Vérifier la sortie
    if ((lem.x - exitX).abs() < 6 && (lem.y - exitY).abs() < 6) {
      lem.state = LemmingState.exiting;
      lem.exited = true;
      saved++;
      score += 50;
      return;
    }

    // Hors limites
    if (lem.y > terrainH + 5 || lem.x < -5 || lem.x > terrainW + 5) {
      lem.alive = false;
      dead++;
      return;
    }

    // === Bomber — compte à rebours ===
    if (lem.state == LemmingState.bombing) {
      lem.bomberTimer -= dt;
      if (lem.bomberTimer <= 0) {
        _dig(ix, iy, 8); // explosion
        lem.alive = false;
        dead++;
      }
      return;
    }

    // === Blocker ===
    if (lem.state == LemmingState.blocking) return;

    // === Vérifier le sol ===
    final onGround = _solid(ix, iy + 1) || _solid(ix + 1, iy + 1);

    if (!onGround && lem.state != LemmingState.climbing) {
      // Tomber
      if (lem.hasFloater && lem.fallDist > 10) {
        lem.state = LemmingState.floating;
        lem.y += fallSpeed * 0.3 * dt;
        lem.fallDist += fallSpeed * 0.3 * dt;
      } else {
        lem.state = LemmingState.falling;
        lem.y += fallSpeed * dt;
        lem.fallDist += fallSpeed * dt;
      }
      return;
    }

    // Atterrissage
    if (lem.state == LemmingState.falling ||
        lem.state == LemmingState.floating) {
      // Ajuster Y pour être pile sur le sol
      while (_solid(ix, lem.y.round() + 1)) {
        lem.y -= 0.5;
        if (lem.y < 0) break;
      }
      if (lem.fallDist > maxSafeFall && !lem.hasFloater) {
        lem.state = LemmingState.splat;
        lem.alive = false;
        dead++;
        return;
      }
      lem.fallDist = 0;
      lem.state = LemmingState.walking;
    }

    // === Digger — creuse vers le bas ===
    if (lem.state == LemmingState.digging) {
      lem.actionCooldown -= dt;
      if (lem.actionCooldown <= 0) {
        lem.actionCooldown = 0.15;
        final dy = lem.y.round() + 1;
        if (_steel(ix, dy) || _steel(ix + 1, dy)) {
          lem.state = LemmingState.walking;
          lem.skill = LemmingSkill.none;
          return;
        }
        _digRect(ix - 2, dy, 6, 2);
        lem.y += 2;
      }
      return;
    }

    // === Basher — creuse horizontalement ===
    if (lem.state == LemmingState.bashing) {
      lem.actionCooldown -= dt;
      if (lem.actionCooldown <= 0) {
        lem.actionCooldown = 0.12;
        final fx = ix + lem.dir * 3;
        bool hitSteel = false;
        bool hitSomething = false;
        for (int dy = -4; dy <= 1; dy++) {
          for (int dx = 0; dx < 3; dx++) {
            final px = fx + dx * lem.dir;
            final py = iy + dy;
            if (_steel(px, py)) {
              hitSteel = true;
            } else if (_solid(px, py)) {
              hitSomething = true;
              _tset(px, py, 0);
            }
          }
        }
        if (hitSteel || !hitSomething) {
          lem.state = LemmingState.walking;
          lem.skill = LemmingSkill.none;
        } else {
          lem.x += lem.dir * 2;
        }
      }
      return;
    }

    // === Miner — creuse en diagonale ===
    if (lem.state == LemmingState.mining) {
      lem.actionCooldown -= dt;
      if (lem.actionCooldown <= 0) {
        lem.actionCooldown = 0.15;
        final fx = ix + lem.dir * 2;
        final fy = iy + 2;
        bool hitSteel = false;
        for (int dy = -1; dy <= 2; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            if (_steel(fx + dx, fy + dy)) {
              hitSteel = true;
            } else {
              _tset(fx + dx, fy + dy, 0);
            }
          }
        }
        if (hitSteel) {
          lem.state = LemmingState.walking;
          lem.skill = LemmingSkill.none;
        } else {
          lem.x += lem.dir * 2;
          lem.y += 2;
        }
      }
      return;
    }

    // === Builder — construit un escalier ===
    if (lem.state == LemmingState.building) {
      lem.actionCooldown -= dt;
      if (lem.actionCooldown <= 0) {
        lem.actionCooldown = 0.25;
        if (lem.buildCount >= buildMax) {
          // Fin de construction → demi-tour
          lem.state = LemmingState.walking;
          lem.skill = LemmingSkill.none;
          lem.dir *= -1;
          return;
        }
        // Poser une marche : 3 pixels de large, avancer + monter
        final bx = ix + lem.dir * 2;
        final by = iy;
        for (int dx = 0; dx < 4; dx++) {
          _tset(bx + dx * lem.dir, by, 1);
        }
        lem.x += lem.dir * 2;
        lem.y -= 1;
        lem.buildCount++;

        // Collision avec le plafond ?
        if (_solid((lem.x + lem.dir * 2).round(), lem.y.round() - 2)) {
          lem.state = LemmingState.walking;
          lem.skill = LemmingSkill.none;
          lem.dir *= -1;
        }
      }
      return;
    }

    // === Climber — escalade les murs ===
    if (lem.state == LemmingState.climbing) {
      lem.y -= climbSpeed * dt;
      // Arrivé en haut du mur ?
      if (!_solid(ix + lem.dir, lem.y.round())) {
        lem.x += lem.dir * 2;
        lem.state = LemmingState.walking;
      }
      // Plafond ?
      if (_solid(ix, lem.y.round() - 1)) {
        lem.state = LemmingState.falling;
        lem.dir *= -1;
      }
      return;
    }

    // === Marche normale ===
    lem.state = LemmingState.walking;
    final nextX = lem.x + lem.dir * walkSpeed * dt;
    final nix = nextX.round();

    // Mur devant ?
    if (_solid(nix + lem.dir, iy) && _solid(nix + lem.dir, iy - 1)) {
      // Climber ?
      if (lem.hasClimber) {
        lem.state = LemmingState.climbing;
        return;
      }
      // Demi-tour
      lem.dir *= -1;
      return;
    }

    // Monter une marche (max 2 pixels)
    if (_solid(nix, iy) && !_solid(nix, iy - 1)) {
      lem.y -= 1;
    } else if (_solid(nix, iy) && _solid(nix, iy - 1) && !_solid(nix, iy - 2)) {
      lem.y -= 2;
    }

    lem.x = nextX;

    // Collision avec les blockers
    for (final other in lemmings) {
      if (other == lem || !other.alive || other.exited) continue;
      if (other.state != LemmingState.blocking) continue;
      if ((lem.x - other.x).abs() < 4 && (lem.y - other.y).abs() < 4) {
        lem.dir *= -1;
        lem.x += lem.dir * 5;
      }
    }
  }

  // === Assigner compétence ===
  void assignSkill(double tapX, double tapY) {
    if (selectedSkill == LemmingSkill.none) return;
    final count = skills[selectedSkill] ?? 0;
    if (count <= 0) return;

    Lemming? closest;
    double bestDist = 10.0;
    for (final lem in lemmings) {
      if (!lem.alive || lem.exited) continue;
      // Climber et floater sont permanents, on peut les ajouter même si déjà une autre skill
      if (selectedSkill != LemmingSkill.climber &&
          selectedSkill != LemmingSkill.floater) {
        if (lem.skill != LemmingSkill.none &&
            lem.state != LemmingState.walking &&
            lem.state != LemmingState.falling) {
          continue;
        }
      }
      final d = sqrt(pow(lem.x - tapX, 2) + pow(lem.y - tapY, 2));
      if (d < bestDist) {
        closest = lem;
        bestDist = d;
      }
    }

    if (closest == null) return;

    skills[selectedSkill] = count - 1;

    switch (selectedSkill) {
      case LemmingSkill.climber:
        closest.hasClimber = true;
      case LemmingSkill.floater:
        closest.hasFloater = true;
      case LemmingSkill.bomber:
        closest.state = LemmingState.bombing;
        closest.bomberTimer = 5.0;
      case LemmingSkill.blocker:
        closest.skill = selectedSkill;
        closest.state = LemmingState.blocking;
      case LemmingSkill.builder:
        closest.skill = selectedSkill;
        closest.state = LemmingState.building;
        closest.buildCount = 0;
        closest.actionCooldown = 0;
      case LemmingSkill.basher:
        closest.skill = selectedSkill;
        closest.state = LemmingState.bashing;
        closest.actionCooldown = 0;
      case LemmingSkill.miner:
        closest.skill = selectedSkill;
        closest.state = LemmingState.mining;
        closest.actionCooldown = 0;
      case LemmingSkill.digger:
        closest.skill = selectedSkill;
        closest.state = LemmingState.digging;
        closest.actionCooldown = 0;
      case LemmingSkill.none:
        break;
    }
  }

  /// Nuke ! Tous les lemmings explosent
  void nuke() {
    nuked = true;
  }

  /// Augmenter le taux de spawn
  void increaseRate() {
    spawnRate = max(0.3, spawnRate - 0.2);
  }

  void decreaseRate() {
    spawnRate = min(3.0, spawnRate + 0.2);
  }

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

  static const totalLevels = 3;
}

// === PAINTER — rendu fidèle à l'original ===
class LemmingsPainter extends CustomPainter {
  final LemmingsGame game;

  LemmingsPainter(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / LemmingsGame.terrainW;
    final scaleY = size.height / LemmingsGame.terrainH;

    // Fond — ciel bleu nuit (comme l'original)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF000044),
    );

    // Terrain — rendu pixel par pixel avec couleurs variées
    for (int y = 0; y < LemmingsGame.terrainH; y++) {
      for (int x = 0; x < LemmingsGame.terrainW; x++) {
        final t = game._tget(x, y);
        if (t == 0) continue;
        Color color;
        if (t == 2) {
          // Acier — gris métallique
          color = ((x + y) % 2 == 0)
              ? const Color(0xFF888899)
              : const Color(0xFF777788);
        } else {
          // Terre — palette verte/brune comme l'original
          final noise = ((x * 7 + y * 13) % 5);
          color = switch (noise) {
            0 => const Color(0xFF228822),
            1 => const Color(0xFF117711),
            2 => const Color(0xFF2B9A2B),
            3 => const Color(0xFF1A881A),
            _ => const Color(0xFF339933),
          };
          // Surface du terrain (1er pixel solide depuis le haut) → herbe claire
          if (y > 0 && game._tget(x, y - 1) == 0) {
            color = const Color(0xFF44DD44);
          }
        }
        canvas.drawRect(
          Rect.fromLTWH(x * scaleX, y * scaleY, scaleX + 0.5, scaleY + 0.5),
          Paint()..color = color,
        );
      }
    }

    // Trappe d'entrée
    _drawTrap(canvas, game.trapX * scaleX, game.trapY * scaleY,
        scaleX, scaleY);

    // Sortie
    _drawExit(canvas, game.exitX * scaleX, game.exitY * scaleY,
        scaleX, scaleY);

    // Lemmings
    for (final lem in game.lemmings) {
      if (!lem.alive && lem.state != LemmingState.splat) continue;
      if (lem.exited) continue;
      _drawLemming(canvas, lem, scaleX, scaleY);
    }
  }

  void _drawTrap(Canvas canvas, double x, double y, double sx, double sy) {
    final w = 14 * sx;
    final h = 8 * sy;
    // Corps de la trappe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y - h / 2), width: w, height: h),
        Radius.circular(2 * sx),
      ),
      Paint()..color = const Color(0xFF8888AA),
    );
    // Porte
    if (game.trapOpen) {
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(x, y + 1 * sy), width: 6 * sx, height: 3 * sy),
        Paint()..color = const Color(0xFF444466),
      );
    }
    // Texte "IN"
    final tp = TextPainter(
      text: TextSpan(
        text: 'IN',
        style: TextStyle(
          color: Colors.white,
          fontSize: 4 * sx,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - h / 2 - 5 * sy));
  }

  void _drawExit(Canvas canvas, double x, double y, double sx, double sy) {
    final w = 12 * sx;
    final h = 14 * sy;
    // Arche de sortie
    final archPath = Path()
      ..moveTo(x - w / 2, y + 2 * sy)
      ..lineTo(x - w / 2, y - h)
      ..quadraticBezierTo(x, y - h - 4 * sy, x + w / 2, y - h)
      ..lineTo(x + w / 2, y + 2 * sy)
      ..close();
    canvas.drawPath(archPath, Paint()..color = const Color(0xFF0000AA));
    canvas.drawPath(
      archPath,
      Paint()
        ..color = const Color(0xFF4444FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Flèche
    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(x, y - 3 * sy),
      Offset(x, y - h + 3 * sy),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(x - 3 * sx, y - h + 6 * sy),
      Offset(x, y - h + 3 * sy),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(x + 3 * sx, y - h + 6 * sy),
      Offset(x, y - h + 3 * sy),
      arrowPaint,
    );
  }

  void _drawLemming(Canvas canvas, Lemming lem, double sx, double sy) {
    final x = lem.x * sx;
    final y = lem.y * sy;
    final w = 3 * sx; // largeur du lemming
    final h = 6 * sy; // hauteur

    // Splat — juste une tache
    if (lem.state == LemmingState.splat) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: w * 3, height: h * 0.4),
        Paint()..color = const Color(0xFF00CC00),
      );
      return;
    }

    // Couleur du corps — bleu comme l'original
    const bodyColor = Color(0xFF4444FF);
    // Cheveux verts — la signature !
    const hairColor = Color(0xFF00FF00);
    // Peau
    const skinColor = Color(0xFFFFCC88);

    // Bomber — clignotement rouge + compteur
    if (lem.state == LemmingState.bombing) {
      final blink = (lem.bomberTimer * 4).floor() % 2 == 0;
      // Compteur au-dessus
      final tp = TextPainter(
        text: TextSpan(
          text: '${lem.bomberTimer.ceil()}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 4 * sx,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - h - 4 * sy));
      // Corps clignotant
      _drawBody(canvas, x, y, w, h, blink ? Colors.red : bodyColor,
          hairColor, skinColor, lem);
      return;
    }

    _drawBody(canvas, x, y, w, h, bodyColor, hairColor, skinColor, lem);

    // Floater — parapluie ouvert
    if (lem.state == LemmingState.floating) {
      final umbrellaPath = Path()
        ..moveTo(x - 6 * sx, y - h - 1 * sy)
        ..quadraticBezierTo(x, y - h - 8 * sy, x + 6 * sx, y - h - 1 * sy);
      canvas.drawPath(
        umbrellaPath,
        Paint()
          ..color = const Color(0xFFFF44FF)
          ..style = PaintingStyle.fill,
      );
      canvas.drawLine(
        Offset(x, y - h),
        Offset(x, y - h - 4 * sy),
        Paint()
          ..color = const Color(0xFF884400)
          ..strokeWidth = sx,
      );
    }

    // Climber — petites mains accrochées
    if (lem.state == LemmingState.climbing) {
      canvas.drawLine(
        Offset(x + lem.dir * w, y - h * 0.8),
        Offset(x + lem.dir * w * 1.5, y - h),
        Paint()
          ..color = skinColor
          ..strokeWidth = sx
          ..strokeCap = StrokeCap.round,
      );
    }

    // Builder — marteau
    if (lem.state == LemmingState.building) {
      final phase = (lem.animTimer * 6).floor() % 2;
      final hammerY = y - h * 0.5 - (phase == 0 ? 3 * sy : 0);
      canvas.drawLine(
        Offset(x + lem.dir * w, y - h * 0.5),
        Offset(x + lem.dir * w * 2, hammerY),
        Paint()
          ..color = const Color(0xFF884400)
          ..strokeWidth = sx * 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Indicateurs permanents
    if (lem.hasClimber) {
      canvas.drawCircle(
        Offset(x - 3 * sx, y - h - 2 * sy),
        sx,
        Paint()..color = Colors.cyan,
      );
    }
    if (lem.hasFloater) {
      canvas.drawCircle(
        Offset(x + 3 * sx, y - h - 2 * sy),
        sx,
        Paint()..color = Colors.pink,
      );
    }
  }

  void _drawBody(Canvas canvas, double x, double y, double w, double h,
      Color body, Color hair, Color skin, Lemming lem) {
    final dir = lem.dir;
    // Animation de marche
    final walkPhase = (lem.animTimer * 8).floor() % 4;
    final legOffset = (walkPhase < 2 ? 1.0 : -1.0) *
        (lem.state == LemmingState.walking ? 1.0 : 0.0);
    final sx = w / 3;
    final sy = h / 6;

    // Pieds
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(x - sx + legOffset * sx, y + sy),
        width: sx * 1.5,
        height: sy * 1.5,
      ),
      Paint()..color = body,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(x + sx - legOffset * sx, y + sy),
        width: sx * 1.5,
        height: sy * 1.5,
      ),
      Paint()..color = body,
    );

    // Corps (tunique bleue)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(x, y - h * 0.35),
        width: w * 1.2,
        height: h * 0.45,
      ),
      Paint()..color = body,
    );

    // Tête (peau)
    canvas.drawCircle(
      Offset(x, y - h * 0.7),
      w * 0.6,
      Paint()..color = skin,
    );

    // Cheveux verts — la marque de fabrique !
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(x, y - h * 0.75),
        width: w * 1.4,
        height: w * 1.2,
      ),
      -pi * 0.9,
      pi * 0.8,
      true,
      Paint()..color = hair,
    );

    // Yeux
    canvas.drawCircle(
      Offset(x + dir * w * 0.2, y - h * 0.72),
      sx * 0.4,
      Paint()..color = Colors.black,
    );

    // Bras du blocker
    if (lem.state == LemmingState.blocking) {
      final armPaint = Paint()
        ..color = body
        ..strokeWidth = sx * 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, y - h * 0.4),
        Offset(x - w * 2, y - h * 0.6),
        armPaint,
      );
      canvas.drawLine(
        Offset(x, y - h * 0.4),
        Offset(x + w * 2, y - h * 0.6),
        armPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
