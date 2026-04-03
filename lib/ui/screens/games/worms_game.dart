import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Armes disponibles dans Worms
enum WormWeapon {
  bazooka,
  grenade,
  shotgun,
  dynamite,
  airstrike,
}

/// Un ver individuel
class Worm {
  double x, y;
  double vx, vy;
  int health;
  String name;
  bool isPlayer; // true = joueur, false = IA
  bool alive;
  double aimAngle; // angle de visée en radians
  bool grounded;

  Worm({
    required this.x,
    required this.y,
    required this.name,
    required this.isPlayer,
    this.health = 100,
  })  : vx = 0,
        vy = 0,
        alive = true,
        aimAngle = -pi / 4,
        grounded = false;
}

/// Projectile en vol
class Projectile {
  double x, y, vx, vy;
  WormWeapon type;
  double timer; // pour grenade/dynamite
  bool active;
  double radius; // rayon d'explosion

  Projectile({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.type,
  })  : timer = type == WormWeapon.grenade
            ? 3.0
            : type == WormWeapon.dynamite
                ? 5.0
                : 0,
        active = true,
        radius = type == WormWeapon.dynamite
            ? 18
            : type == WormWeapon.bazooka
                ? 14
                : type == WormWeapon.grenade
                    ? 12
                    : 8;
}

/// Explosion visuelle
class Explosion {
  double x, y, radius;
  double timer;
  Explosion(this.x, this.y, this.radius) : timer = 0.4;
}

/// Moteur Worms — fidèle au premier opus
class WormsGame {
  static const int terrainW = 320;
  static const int terrainH = 200;
  static const double gravity = 120.0;
  static const double windMax = 30.0;

  // Terrain destructible
  late Uint8List terrain; // 0=vide, 1=terre, 2=eau(bas)

  // Équipes
  final List<Worm> playerWorms = [];
  final List<Worm> enemyWorms = [];
  List<Worm> get allWorms => [...playerWorms, ...enemyWorms];

  // Projectiles et explosions
  final List<Projectile> projectiles = [];
  final List<Explosion> explosions = [];

  // Tour par tour
  int turnIndex = 0;
  bool isPlayerTurn = true;
  int activeWormIndex = 0;
  double turnTimer = 30; // secondes par tour
  bool hasFired = false;
  bool waitingForProjectile = false;
  double turnTransitionTimer = 0;
  bool inTransition = false;

  // Vent
  double wind = 0;

  // Armes
  WormWeapon selectedWeapon = WormWeapon.bazooka;
  final Map<WormWeapon, int> ammo = {
    WormWeapon.bazooka: 99,
    WormWeapon.grenade: 5,
    WormWeapon.shotgun: 3,
    WormWeapon.dynamite: 1,
    WormWeapon.airstrike: 1,
  };

  // Power — puissance du tir (barre de charge)
  double power = 0;
  bool charging = false;
  static const double maxPower = 200;

  // État
  int score = 0;
  bool gameOver = false;
  bool won = false;

  Worm get activeWorm {
    final team = isPlayerTurn ? playerWorms : enemyWorms;
    final alive = team.where((w) => w.alive).toList();
    if (alive.isEmpty) return team.first;
    return alive[activeWormIndex % alive.length];
  }

  final VoidCallback onStateChanged;
  final void Function(int finalScore) onGameOver;
  final Random _rng = Random();

  WormsGame({
    required this.onStateChanged,
    required this.onGameOver,
  }) {
    _generateTerrain();
    _placeWorms();
    _newWind();
  }

  // === Terrain ===
  int _tget(int x, int y) {
    if (x < 0 || x >= terrainW || y < 0 || y >= terrainH) return 0;
    return terrain[y * terrainW + x];
  }

  void _tset(int x, int y, int v) {
    if (x < 0 || x >= terrainW || y < 0 || y >= terrainH) return;
    terrain[y * terrainW + x] = v;
  }

  bool _solid(int x, int y) => _tget(x, y) == 1;

  void _generateTerrain() {
    terrain = Uint8List(terrainW * terrainH);

    // Générer un terrain vallonné procédural
    final heightMap = List<int>.filled(terrainW, 0);
    double h = terrainH * 0.55;
    double slope = 0;

    for (int x = 0; x < terrainW; x++) {
      slope += (_rng.nextDouble() - 0.5) * 1.5;
      slope *= 0.95;
      h += slope;
      h = h.clamp(terrainH * 0.35, terrainH * 0.75);
      heightMap[x] = h.round();
    }

    // Remplir le terrain
    for (int x = 0; x < terrainW; x++) {
      for (int y = heightMap[x]; y < terrainH - 5; y++) {
        _tset(x, y, 1);
      }
      // Eau au fond
      for (int y = terrainH - 5; y < terrainH; y++) {
        _tset(x, y, 2);
      }
    }
  }

  void _placeWorms() {
    // Placer les vers sur le terrain
    final names1 = ['Romain', 'Lucas'];
    final names2 = ['Bot-1', 'Bot-2'];

    for (int i = 0; i < 2; i++) {
      final x = 40.0 + i * 40;
      final y = _findGround(x.round()) - 5.0;
      playerWorms.add(Worm(x: x, y: y, name: names1[i], isPlayer: true));
    }
    for (int i = 0; i < 2; i++) {
      final x = 200.0 + i * 40;
      final y = _findGround(x.round()) - 5.0;
      enemyWorms.add(Worm(x: x, y: y, name: names2[i], isPlayer: false));
    }
  }

  int _findGround(int x) {
    for (int y = 0; y < terrainH; y++) {
      if (_solid(x, y)) return y;
    }
    return terrainH - 10;
  }

  void _newWind() {
    wind = (_rng.nextDouble() - 0.5) * 2 * windMax;
  }

  void _explode(double ex, double ey, double radius) {
    // Creuser le terrain
    final r = radius.round();
    for (int dy = -r; dy <= r; dy++) {
      for (int dx = -r; dx <= r; dx++) {
        if (dx * dx + dy * dy <= r * r) {
          final px = ex.round() + dx;
          final py = ey.round() + dy;
          if (_tget(px, py) == 1) _tset(px, py, 0);
        }
      }
    }

    // Dégâts aux vers
    for (final w in allWorms) {
      if (!w.alive) continue;
      final dist = sqrt(pow(w.x - ex, 2) + pow(w.y - ey, 2));
      if (dist < radius * 1.5) {
        final dmg = ((1 - dist / (radius * 1.5)) * 40).round();
        w.health -= dmg;
        // Projeter le ver
        final angle = atan2(w.y - ey, w.x - ex);
        w.vx += cos(angle) * (radius - dist) * 3;
        w.vy += sin(angle) * (radius - dist) * 3 - 30;
        if (w.health <= 0) {
          w.health = 0;
          w.alive = false;
          if (!w.isPlayer) score += 100;
        }
      }
    }

    explosions.add(Explosion(ex, ey, radius));
  }

  // === Contrôles joueur ===
  void moveLeft(double dt) {
    if (hasFired || !isPlayerTurn || inTransition) return;
    final w = activeWorm;
    if (!w.alive) return;
    w.x -= 25 * dt;
    _applyGravityWorm(w, dt);
  }

  void moveRight(double dt) {
    if (hasFired || !isPlayerTurn || inTransition) return;
    final w = activeWorm;
    if (!w.alive) return;
    w.x += 25 * dt;
    _applyGravityWorm(w, dt);
  }

  void aimUp(double dt) {
    if (!isPlayerTurn || inTransition) return;
    activeWorm.aimAngle -= 1.5 * dt;
    activeWorm.aimAngle = activeWorm.aimAngle.clamp(-pi * 0.9, 0);
  }

  void aimDown(double dt) {
    if (!isPlayerTurn || inTransition) return;
    activeWorm.aimAngle += 1.5 * dt;
    activeWorm.aimAngle = activeWorm.aimAngle.clamp(-pi * 0.9, 0);
  }

  void startCharge() {
    if (hasFired || !isPlayerTurn || inTransition) return;
    charging = true;
    power = 0;
  }

  void fire() {
    if (!charging || hasFired) return;
    charging = false;
    _fireWeapon(activeWorm, power);
    hasFired = true;
    waitingForProjectile = true;
  }

  void _fireWeapon(Worm w, double pow) {
    final a = w.aimAngle;
    final speed = pow.clamp(30, maxPower);

    switch (selectedWeapon) {
      case WormWeapon.bazooka:
        projectiles.add(Projectile(
          x: w.x,
          y: w.y - 4,
          vx: cos(a) * speed,
          vy: sin(a) * speed,
          type: WormWeapon.bazooka,
        ));
      case WormWeapon.grenade:
        if ((ammo[WormWeapon.grenade] ?? 0) > 0) {
          ammo[WormWeapon.grenade] = (ammo[WormWeapon.grenade] ?? 1) - 1;
          projectiles.add(Projectile(
            x: w.x,
            y: w.y - 4,
            vx: cos(a) * speed * 0.8,
            vy: sin(a) * speed * 0.8,
            type: WormWeapon.grenade,
          ));
        }
      case WormWeapon.shotgun:
        if ((ammo[WormWeapon.shotgun] ?? 0) > 0) {
          ammo[WormWeapon.shotgun] = (ammo[WormWeapon.shotgun] ?? 1) - 1;
          // Hitscan
          _shotgunHit(w, a);
        }
      case WormWeapon.dynamite:
        if ((ammo[WormWeapon.dynamite] ?? 0) > 0) {
          ammo[WormWeapon.dynamite] = (ammo[WormWeapon.dynamite] ?? 1) - 1;
          projectiles.add(Projectile(
            x: w.x + cos(a) * 10,
            y: w.y - 4 + sin(a) * 10,
            vx: 0,
            vy: 0,
            type: WormWeapon.dynamite,
          ));
        }
      case WormWeapon.airstrike:
        if ((ammo[WormWeapon.airstrike] ?? 0) > 0) {
          ammo[WormWeapon.airstrike] = (ammo[WormWeapon.airstrike] ?? 1) - 1;
          // 5 projectiles qui tombent du ciel
          for (int i = -2; i <= 2; i++) {
            projectiles.add(Projectile(
              x: w.x + cos(a) * 80 + i * 12,
              y: 5,
              vx: 0,
              vy: 80,
              type: WormWeapon.bazooka,
            ));
          }
        }
    }
  }

  void _shotgunHit(Worm shooter, double angle) {
    // Rayon hitscan
    double rx = shooter.x, ry = shooter.y - 4;
    for (int i = 0; i < 120; i++) {
      rx += cos(angle) * 2;
      ry += sin(angle) * 2;
      if (_solid(rx.round(), ry.round())) {
        _explode(rx, ry, 6);
        return;
      }
      for (final w in allWorms) {
        if (w == shooter || !w.alive) continue;
        if ((w.x - rx).abs() < 5 && (w.y - ry).abs() < 8) {
          _explode(rx, ry, 6);
          return;
        }
      }
    }
  }

  // === IA ===
  void _aiTurn(double dt) {
    if (inTransition) return;
    final w = activeWorm;
    if (!w.alive) {
      _nextTurn();
      return;
    }

    // Viser le joueur le plus proche
    Worm? target;
    double bestDist = double.infinity;
    for (final pw in playerWorms) {
      if (!pw.alive) continue;
      final d = (pw.x - w.x).abs();
      if (d < bestDist) {
        bestDist = d;
        target = pw;
      }
    }

    if (target == null) return;

    // Calculer l'angle vers la cible
    final dx = target.x - w.x;
    final dy = target.y - w.y;
    w.aimAngle = atan2(dy, dx);

    // Tirer après un délai
    turnTimer -= dt;
    if (turnTimer < 27 && !hasFired) {
      _fireWeapon(w, 100 + _rng.nextDouble() * 60);
      hasFired = true;
      waitingForProjectile = true;
    }
  }

  void _applyGravityWorm(Worm w, double dt) {
    if (!_solid(w.x.round(), w.y.round() + 1)) {
      w.vy += gravity * dt;
      w.y += w.vy * dt;
      w.grounded = false;
    } else {
      w.vy = 0;
      w.grounded = true;
      // Ajuster sur le sol
      while (_solid(w.x.round(), w.y.round())) {
        w.y -= 0.5;
      }
    }
    // Eau = mort
    if (w.y > terrainH - 7) {
      w.alive = false;
      if (!w.isPlayer) score += 50;
    }
    w.x = w.x.clamp(2, terrainW - 2.0);
  }

  // === Boucle principale ===
  void update(double dt) {
    if (gameOver) return;

    // Charge
    if (charging) {
      power += 150 * dt;
      if (power > maxPower) power = maxPower;
    }

    // Transition entre tours
    if (inTransition) {
      turnTransitionTimer -= dt;
      if (turnTransitionTimer <= 0) {
        inTransition = false;
      }
      onStateChanged();
      return;
    }

    // Timer du tour
    turnTimer -= dt;
    if (turnTimer <= 0 && !waitingForProjectile) {
      _nextTurn();
    }

    // IA
    if (!isPlayerTurn) {
      _aiTurn(dt);
    }

    // Physique des vers (vélocité résiduelle d'explosions)
    for (final w in allWorms) {
      if (!w.alive) continue;
      if (w.vx.abs() > 0.5 || w.vy.abs() > 0.5) {
        w.x += w.vx * dt;
        w.vy += gravity * dt;
        w.y += w.vy * dt;
        w.vx *= 0.95;
        if (_solid(w.x.round(), w.y.round() + 1)) {
          w.vy = 0;
          w.vx *= 0.8;
          while (_solid(w.x.round(), w.y.round())) {
            w.y -= 0.5;
          }
        }
        if (w.y > terrainH - 7) {
          w.alive = false;
          if (!w.isPlayer) score += 50;
        }
      } else {
        _applyGravityWorm(w, dt);
      }
    }

    // Projectiles
    for (final p in projectiles) {
      if (!p.active) continue;

      // Gravité + vent
      p.vy += gravity * dt;
      if (p.type == WormWeapon.bazooka || p.type == WormWeapon.grenade) {
        p.vx += wind * 0.5 * dt;
      }
      p.x += p.vx * dt;
      p.y += p.vy * dt;

      // Timer (grenade, dynamite)
      if (p.type == WormWeapon.grenade || p.type == WormWeapon.dynamite) {
        p.timer -= dt;
        // Grenade rebondit
        if (p.type == WormWeapon.grenade &&
            _solid(p.x.round(), p.y.round())) {
          p.vy *= -0.5;
          p.vx *= 0.7;
          p.y -= 2;
        }
        if (p.timer <= 0) {
          _explode(p.x, p.y, p.radius);
          p.active = false;
          continue;
        }
      }

      // Impact terrain
      if (_solid(p.x.round(), p.y.round())) {
        if (p.type != WormWeapon.grenade) {
          _explode(p.x, p.y, p.radius);
          p.active = false;
        }
      }

      // Hors écran
      if (p.x < -20 || p.x > terrainW + 20 || p.y > terrainH + 20) {
        p.active = false;
      }
    }

    // Nettoyage
    projectiles.removeWhere((p) => !p.active);

    // Explosions (animation)
    for (final e in explosions) {
      e.timer -= dt;
    }
    explosions.removeWhere((e) => e.timer <= 0);

    // Fin des projectiles → tour suivant
    if (waitingForProjectile && projectiles.isEmpty && explosions.isEmpty) {
      waitingForProjectile = false;
      _nextTurn();
    }

    // Vérifier victoire/défaite
    final playerAlive = playerWorms.any((w) => w.alive);
    final enemyAlive = enemyWorms.any((w) => w.alive);
    if (!playerAlive || !enemyAlive) {
      won = !enemyAlive;
      if (won) score += 300;
      gameOver = true;
      onGameOver(score);
    }

    onStateChanged();
  }

  void _nextTurn() {
    isPlayerTurn = !isPlayerTurn;
    turnTimer = 30;
    hasFired = false;
    charging = false;
    power = 0;

    // Avancer l'index du ver actif
    final team = isPlayerTurn ? playerWorms : enemyWorms;
    final alive = team.where((w) => w.alive).toList();
    if (alive.isNotEmpty) {
      activeWormIndex = (activeWormIndex + 1) % alive.length;
    }

    _newWind();
    inTransition = true;
    turnTransitionTimer = 1.5;
  }
}

/// Painter Worms — style original pixel art
class WormsPainter extends CustomPainter {
  final WormsGame game;

  WormsPainter(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / WormsGame.terrainW;
    final sy = size.height / WormsGame.terrainH;

    // Ciel dégradé
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4488CC), Color(0xFFAADDFF)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Terrain
    for (int y = 0; y < WormsGame.terrainH; y++) {
      for (int x = 0; x < WormsGame.terrainW; x++) {
        final t = game._tget(x, y);
        if (t == 0) continue;
        Color color;
        if (t == 2) {
          // Eau
          final wave = sin(x * 0.3) * 0.5;
          color = Color.lerp(
              const Color(0xFF2244AA), const Color(0xFF3366CC), wave)!;
        } else {
          // Terre — brun avec surface verte
          final isTop = y > 0 && game._tget(x, y - 1) == 0;
          if (isTop) {
            color = const Color(0xFF44AA22);
          } else {
            final n = ((x * 7 + y * 13) % 4);
            color = switch (n) {
              0 => const Color(0xFF8B5E3C),
              1 => const Color(0xFF7A5232),
              2 => const Color(0xFF9B6B4A),
              _ => const Color(0xFF846040),
            };
          }
        }
        canvas.drawRect(
          Rect.fromLTWH(x * sx, y * sy, sx + 0.5, sy + 0.5),
          Paint()..color = color,
        );
      }
    }

    // Explosions
    for (final e in game.explosions) {
      final alpha = (e.timer / 0.4).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(e.x * sx, e.y * sy),
        e.radius * sx * (2 - alpha),
        Paint()
          ..color = Color.lerp(
              Colors.yellow, Colors.red, 1 - alpha)!
              .withValues(alpha: alpha),
      );
    }

    // Projectiles
    for (final p in game.projectiles) {
      final color = switch (p.type) {
        WormWeapon.bazooka => Colors.red,
        WormWeapon.grenade => Colors.green,
        WormWeapon.dynamite => Colors.orange,
        _ => Colors.white,
      };
      canvas.drawCircle(
        Offset(p.x * sx, p.y * sy),
        max(2, 3 * sx),
        Paint()..color = color,
      );
      // Traînée
      canvas.drawLine(
        Offset(p.x * sx, p.y * sy),
        Offset((p.x - p.vx * 0.02) * sx, (p.y - p.vy * 0.02) * sy),
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..strokeWidth = 1.5,
      );
    }

    // Vers
    for (final w in game.allWorms) {
      _drawWorm(canvas, w, sx, sy);
    }

    // Indicateur vent
    _drawWind(canvas, size);

    // Indicateur du ver actif
    if (!game.gameOver && !game.inTransition) {
      final aw = game.activeWorm;
      if (aw.alive) {
        // Flèche au-dessus
        final ax = aw.x * sx;
        final ay = aw.y * sy - 18 * sy;
        final arrowPath = Path()
          ..moveTo(ax, ay + 4 * sy)
          ..lineTo(ax - 3 * sx, ay)
          ..lineTo(ax + 3 * sx, ay)
          ..close();
        canvas.drawPath(
          arrowPath,
          Paint()
            ..color = game.isPlayerTurn ? Colors.green : Colors.red,
        );

        // Ligne de visée (joueur seulement)
        if (game.isPlayerTurn && !game.hasFired) {
          final aimLen = 20 * sx;
          canvas.drawLine(
            Offset(ax, aw.y * sy - 4 * sy),
            Offset(
              ax + cos(aw.aimAngle) * aimLen,
              aw.y * sy - 4 * sy + sin(aw.aimAngle) * aimLen,
            ),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.6)
              ..strokeWidth = 1.5,
          );
        }
      }
    }
  }

  void _drawWorm(Canvas canvas, Worm w, double sx, double sy) {
    if (!w.alive) return;
    final x = w.x * sx;
    final y = w.y * sy;
    final bodyW = 4 * sx;
    final bodyH = 6 * sy;

    // Corps (rose)
    final bodyColor =
        w.isPlayer ? const Color(0xFFFF88AA) : const Color(0xFFFF6666);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, y - bodyH * 0.4),
          width: bodyW,
          height: bodyH,
        ),
        Radius.circular(bodyW * 0.4),
      ),
      Paint()..color = bodyColor,
    );

    // Yeux
    canvas.drawCircle(
      Offset(x - sx, y - bodyH * 0.6),
      sx * 0.7,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(x + sx, y - bodyH * 0.6),
      sx * 0.7,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(x - sx * 0.7, y - bodyH * 0.6),
      sx * 0.35,
      Paint()..color = Colors.black,
    );
    canvas.drawCircle(
      Offset(x + sx * 0.7, y - bodyH * 0.6),
      sx * 0.35,
      Paint()..color = Colors.black,
    );

    // Barre de vie
    final hpW = bodyW * 1.5;
    final hpY = y - bodyH - 3 * sy;
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(x, hpY), width: hpW, height: 2 * sy),
      Paint()..color = Colors.red,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        x - hpW / 2,
        hpY - sy,
        hpW * (w.health / 100).clamp(0, 1),
        2 * sy,
      ),
      Paint()..color = Colors.green,
    );

    // Nom
    final tp = TextPainter(
      text: TextSpan(
        text: w.name,
        style: TextStyle(
          color: Colors.white,
          fontSize: 3 * sx,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, hpY - 5 * sy));
  }

  void _drawWind(Canvas canvas, Size size) {
    final windStr = game.wind;
    final cx = size.width / 2;
    const y = 12.0;
    // Flèche de vent
    final arrowLen = (windStr / WormsGame.windMax) * 30;
    canvas.drawLine(
      Offset(cx, y),
      Offset(cx + arrowLen, y),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    if (arrowLen.abs() > 5) {
      final dir = arrowLen > 0 ? -1.0 : 1.0;
      canvas.drawLine(
        Offset(cx + arrowLen, y),
        Offset(cx + arrowLen + dir * 5, y - 4),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5,
      );
      canvas.drawLine(
        Offset(cx + arrowLen, y),
        Offset(cx + arrowLen + dir * 5, y + 4),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
