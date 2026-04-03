import 'dart:math';
import 'package:flutter/material.dart';

/// Moteur Marble Madness — physique 2D avec rendu isométrique
class MarbleGame {
  // Taille de la grille du niveau
  static const int gridWidth = 12;
  static const int gridHeight = 20;

  // Types de tuiles
  static const int tEmpty = 0; // vide (trou)
  static const int tFlat = 1; // surface plane
  static const int tGoal = 2; // arrivée
  static const int tBonus = 3; // bonus points
  static const int tIce = 4; // glissant
  static const int tSlow = 5; // ralentit

  // Niveaux pré-définis
  static final List<List<List<int>>> levels = [_level1, _level2, _level3];

  // Niveau 1 — Initiation
  static final List<List<int>> _level1 = [
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 1, 1, 3, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 1, 1, 3, 1, 1, 1, 1, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 1, 1, 3, 1, 1, 1, 1, 0, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 1, 1, 2, 2, 1, 1, 1, 0, 0],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
  ];

  // Niveau 2 — Glace et passages étroits
  static final List<List<int>> _level2 = [
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 1, 4, 4, 4, 4, 1, 1, 0, 0],
    [0, 0, 1, 1, 4, 3, 4, 4, 1, 1, 0, 0],
    [0, 0, 0, 1, 4, 4, 4, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0],
    [0, 0, 1, 3, 0, 0, 0, 3, 1, 0, 0, 0],
    [0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0],
    [0, 0, 0, 1, 1, 5, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 5, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 1, 1, 4, 4, 4, 1, 1, 0, 0, 0],
    [0, 0, 1, 4, 4, 3, 4, 4, 1, 0, 0, 0],
    [0, 0, 1, 1, 4, 4, 4, 1, 1, 0, 0, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 1, 1, 2, 1, 1, 0, 0, 0, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0],
  ];

  // Niveau 3 — Le défi
  static final List<List<int>> _level3 = [
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0],
    [0, 0, 0, 1, 4, 4, 4, 4, 1, 0, 0, 0],
    [0, 0, 0, 1, 4, 3, 3, 4, 1, 0, 0, 0],
    [0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 0, 0, 5, 5, 0, 0, 1, 0, 0],
    [0, 0, 1, 0, 0, 5, 5, 0, 0, 1, 0, 0],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
    [0, 1, 1, 4, 4, 4, 4, 4, 4, 1, 1, 0],
    [0, 1, 3, 4, 0, 0, 0, 0, 4, 3, 1, 0],
    [0, 1, 1, 4, 0, 0, 0, 0, 4, 1, 1, 0],
    [0, 0, 0, 4, 4, 1, 1, 4, 4, 0, 0, 0],
    [0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0],
    [0, 0, 0, 1, 1, 2, 2, 1, 1, 0, 0, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0],
  ];

  // Bille
  double marbleX = 5.5;
  double marbleY = 1.0;
  double vx = 0;
  double vy = 0;
  static const double marbleRadius = 0.35;
  static const double gravity = 8.0;
  static const double friction = 0.97;
  static const double iceFriction = 0.995;
  static const double slowFriction = 0.92;
  static const double maxSpeed = 6.0;

  // Force appliquée par le joueur
  double forceX = 0;
  double forceY = 0;

  // État
  int score = 0;
  int currentLevel = 0;
  double timer = 60; // secondes
  bool gameOver = false;
  bool won = false;

  List<List<int>> get currentMap => levels[currentLevel];

  final VoidCallback onStateChanged;
  final void Function(int finalScore) onGameOver;

  MarbleGame({
    required this.onStateChanged,
    required this.onGameOver,
  });

  void update(double dt) {
    if (gameOver) return;

    // Timer
    timer -= dt;
    if (timer <= 0) {
      timer = 0;
      gameOver = true;
      onGameOver(score);
      return;
    }

    // Physique
    vx += forceX * gravity * dt;
    vy += forceY * gravity * dt;

    // Limiter la vitesse
    final speed = sqrt(vx * vx + vy * vy);
    if (speed > maxSpeed) {
      vx = vx / speed * maxSpeed;
      vy = vy / speed * maxSpeed;
    }

    // Friction basée sur la tuile
    final tileX = marbleX.floor().clamp(0, gridWidth - 1);
    final tileY = marbleY.floor().clamp(0, gridHeight - 1);
    final tile = currentMap[tileY][tileX];
    final fric = switch (tile) {
      tIce => iceFriction,
      tSlow => slowFriction,
      _ => friction,
    };
    vx *= fric;
    vy *= fric;

    // Déplacement
    final newX = marbleX + vx * dt;
    final newY = marbleY + vy * dt;

    // Collision avec les bords et les trous
    final checkX = newX.floor().clamp(0, gridWidth - 1);
    final checkY = newY.floor().clamp(0, gridHeight - 1);
    final targetTile = currentMap[checkY][checkX];

    if (targetTile == tEmpty) {
      // Tombe dans le vide !
      gameOver = true;
      onGameOver(score);
      return;
    }

    if (targetTile == tGoal) {
      // Niveau terminé !
      score += (timer * 10).toInt(); // bonus temps
      if (currentLevel < levels.length - 1) {
        currentLevel++;
        _resetMarble();
        timer = 60;
      } else {
        won = true;
        score += 500; // bonus fin du jeu
        gameOver = true;
        onGameOver(score);
        return;
      }
    }

    if (targetTile == tBonus) {
      // Ramasse le bonus
      score += 50;
      currentMap[checkY][checkX] = tFlat;
    }

    // Collision murs (bords de la carte)
    marbleX = newX.clamp(marbleRadius, gridWidth - marbleRadius);
    marbleY = newY.clamp(marbleRadius, gridHeight - marbleRadius);

    // Rebond sur les bords de tuiles vides adjacentes
    _handleEdgeCollisions();

    onStateChanged();
  }

  void _handleEdgeCollisions() {
    // Vérifier les tuiles adjacentes — rebondir si c'est du vide
    final cx = marbleX.floor().clamp(0, gridWidth - 1);
    final cy = marbleY.floor().clamp(0, gridHeight - 1);

    // Gauche
    if (cx > 0 && currentMap[cy][cx - 1] == tEmpty) {
      final edge = cx.toDouble();
      if (marbleX - marbleRadius < edge) {
        marbleX = edge + marbleRadius;
        vx = vx.abs() * 0.5;
      }
    }
    // Droite
    if (cx < gridWidth - 1 && currentMap[cy][cx + 1] == tEmpty) {
      final edge = (cx + 1).toDouble();
      if (marbleX + marbleRadius > edge) {
        marbleX = edge - marbleRadius;
        vx = -vx.abs() * 0.5;
      }
    }
    // Haut
    if (cy > 0 && currentMap[cy - 1][cx] == tEmpty) {
      final edge = cy.toDouble();
      if (marbleY - marbleRadius < edge) {
        marbleY = edge + marbleRadius;
        vy = vy.abs() * 0.5;
      }
    }
    // Bas
    if (cy < gridHeight - 1 && currentMap[cy + 1][cx] == tEmpty) {
      final edge = (cy + 1).toDouble();
      if (marbleY + marbleRadius > edge) {
        marbleY = edge - marbleRadius;
        vy = -vy.abs() * 0.5;
      }
    }
  }

  void _resetMarble() {
    marbleX = 5.5;
    marbleY = 1.0;
    vx = 0;
    vy = 0;
  }

  void setForce(double fx, double fy) {
    forceX = fx.clamp(-1.0, 1.0);
    forceY = fy.clamp(-1.0, 1.0);
  }
}

/// Painter isométrique pour Marble Madness
class MarblePainter extends CustomPainter {
  final MarbleGame game;

  MarblePainter(this.game);

  // Couleurs des tuiles
  static const tileColors = {
    MarbleGame.tFlat: Color(0xFF4A7C59), // vert
    MarbleGame.tGoal: Color(0xFFFFD700), // or
    MarbleGame.tBonus: Color(0xFFFF69B4), // rose
    MarbleGame.tIce: Color(0xFF87CEEB), // bleu clair
    MarbleGame.tSlow: Color(0xFF8B6914), // brun
  };

  @override
  void paint(Canvas canvas, Size size) {
    final map = game.currentMap;
    // Calcul de la taille isométrique pour tenir dans l'écran
    final tileW = size.width / (MarbleGame.gridWidth + 2);
    final tileH = tileW * 0.5;
    final offsetX = size.width / 2;
    final offsetY = tileH * 2;

    // Conversion iso : x_screen = (gx - gy) * tileW/2 + offsetX
    //                   y_screen = (gx + gy) * tileH/2 + offsetY
    Offset toIso(double gx, double gy) {
      return Offset(
        (gx - gy) * tileW / 2 + offsetX,
        (gx + gy) * tileH / 2 + offsetY,
      );
    }

    // Dessiner les tuiles
    for (int y = 0; y < MarbleGame.gridHeight; y++) {
      for (int x = 0; x < MarbleGame.gridWidth; x++) {
        final tile = map[y][x];
        if (tile == MarbleGame.tEmpty) continue;

        final color = tileColors[tile] ?? const Color(0xFF4A7C59);
        final topLeft = toIso(x.toDouble(), y.toDouble());
        final topRight = toIso(x + 1.0, y.toDouble());
        final bottomRight = toIso(x + 1.0, y + 1.0);
        final bottomLeft = toIso(x.toDouble(), y + 1.0);

        // Face du dessus
        final topPath = Path()
          ..moveTo(topLeft.dx, topLeft.dy)
          ..lineTo(topRight.dx, topRight.dy)
          ..lineTo(bottomRight.dx, bottomRight.dy)
          ..lineTo(bottomLeft.dx, bottomLeft.dy)
          ..close();
        canvas.drawPath(topPath, Paint()..color = color);

        // Bord gauche (plus foncé)
        final leftSide = Path()
          ..moveTo(bottomLeft.dx, bottomLeft.dy)
          ..lineTo(bottomLeft.dx, bottomLeft.dy + tileH * 0.3)
          ..lineTo(bottomRight.dx, bottomRight.dy + tileH * 0.3)
          ..lineTo(bottomRight.dx, bottomRight.dy)
          ..close();
        canvas.drawPath(
          leftSide,
          Paint()..color = Color.lerp(color, Colors.black, 0.4)!,
        );

        // Contour
        canvas.drawPath(
          topPath,
          Paint()
            ..color = Color.lerp(color, Colors.black, 0.2)!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );

        // Indicateur spécial pour les tuiles goal et bonus
        if (tile == MarbleGame.tGoal) {
          final center = toIso(x + 0.5, y + 0.5);
          canvas.drawCircle(
            center,
            tileW * 0.15,
            Paint()..color = Colors.white.withValues(alpha: 0.6),
          );
        }
        if (tile == MarbleGame.tBonus) {
          final center = toIso(x + 0.5, y + 0.5);
          // Étoile bonus
          canvas.drawCircle(
            center,
            tileW * 0.1,
            Paint()..color = Colors.yellow,
          );
        }
      }
    }

    // Bille (ombre + sphère 3D)
    final marbleIso = toIso(game.marbleX, game.marbleY);
    final marbleScreenRadius = tileW * 0.25;

    // Ombre
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(marbleIso.dx + 2, marbleIso.dy + marbleScreenRadius * 0.4),
        width: marbleScreenRadius * 1.8,
        height: marbleScreenRadius * 0.8,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Sphère avec dégradé radial
    const marbleGradient = RadialGradient(
      center: Alignment(-0.3, -0.3),
      radius: 0.8,
      colors: [
        Color(0xFFFF4444),
        Color(0xFFCC0000),
        Color(0xFF660000),
      ],
    );
    canvas.drawCircle(
      marbleIso,
      marbleScreenRadius,
      Paint()
        ..shader = marbleGradient.createShader(
          Rect.fromCircle(center: marbleIso, radius: marbleScreenRadius),
        ),
    );

    // Reflet
    canvas.drawCircle(
      Offset(marbleIso.dx - marbleScreenRadius * 0.25,
          marbleIso.dy - marbleScreenRadius * 0.25),
      marbleScreenRadius * 0.2,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
