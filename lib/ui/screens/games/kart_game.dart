import 'dart:math';
import 'package:flutter/material.dart';

/// Moteur Kart Racing — course pseudo-3D style Mode 7 / SNES
class KartGame {
  // Circuit
  static const int trackSegments = 300;
  static const double segmentLength = 5.0;

  // Joueur
  double playerX = 0; // -1.0 (gauche) à 1.0 (droite)
  double speed = 0;
  static const double maxSpeed = 200.0;
  static const double acceleration = 120.0;
  static const double deceleration = 80.0;
  static const double braking = 150.0;
  static const double steerSpeed = 3.0;
  static const double centrifugalForce = 0.3;

  // Position sur le circuit
  double position = 0;
  int currentLap = 0;
  int totalLaps = 3;

  // IA adversaires
  final List<KartOpponent> opponents = [];

  // Circuit — liste de segments avec courbe
  late List<TrackSegment> segments;

  // État
  int score = 0;
  bool gameOver = false;
  bool won = false;
  double raceTimer = 0;
  int playerRank = 1;

  final VoidCallback onStateChanged;
  final void Function(int finalScore) onGameOver;
  final Random _random = Random();

  KartGame({
    required this.onStateChanged,
    required this.onGameOver,
  }) {
    _buildTrack();
    _spawnOpponents();
  }

  void _buildTrack() {
    segments = List.generate(trackSegments, (i) {
      double curve = 0;
      double hill = 0;

      // Virages
      if (i > 20 && i < 60) curve = 0.5; // virage droit
      if (i > 80 && i < 120) curve = -0.7; // virage gauche serré
      if (i > 140 && i < 170) curve = 0.3; // léger virage
      if (i > 190 && i < 230) curve = -0.5; // virage gauche
      if (i > 250 && i < 270) curve = 0.8; // virage serré droit

      // Collines
      if (i > 30 && i < 50) hill = sin((i - 30) / 20.0 * pi) * 30;
      if (i > 150 && i < 180) hill = sin((i - 150) / 30.0 * pi) * 20;

      // Décors (arbres, panneaux...)
      SpriteType? leftSprite;
      SpriteType? rightSprite;
      if (i % 15 == 0) leftSprite = SpriteType.tree;
      if (i % 15 == 7) rightSprite = SpriteType.tree;
      if (i % 40 == 0) rightSprite = SpriteType.sign;

      return TrackSegment(
        index: i,
        curve: curve,
        hill: hill,
        leftSprite: leftSprite,
        rightSprite: rightSprite,
      );
    });
  }

  void _spawnOpponents() {
    final colors = [
      const Color(0xFFFF0000), // Rouge
      const Color(0xFF00AA00), // Vert
      const Color(0xFFFFAA00), // Orange
      const Color(0xFFAA00FF), // Violet
      const Color(0xFF00AAFF), // Cyan
    ];
    for (int i = 0; i < 5; i++) {
      opponents.add(KartOpponent(
        position: (i + 1) * 40.0 + _random.nextDouble() * 20,
        x: (_random.nextDouble() - 0.5) * 1.2,
        speed: 100 + _random.nextDouble() * 80,
        color: colors[i],
      ));
    }
  }

  // Contrôles
  bool accelerating = false;
  bool braking_ = false;
  double steerInput = 0; // -1 gauche, 0 centre, 1 droite

  void update(double dt) {
    if (gameOver) return;

    raceTimer += dt;

    // Accélération / freinage
    if (accelerating) {
      speed += acceleration * dt;
    } else if (braking_) {
      speed -= braking * dt;
    } else {
      speed -= deceleration * dt;
    }
    speed = speed.clamp(0, maxSpeed);

    // Segment courant
    final segIndex =
        (position / segmentLength).floor() % trackSegments;
    final seg = segments[segIndex];

    // Direction + force centrifuge
    playerX += steerInput * steerSpeed * dt;
    playerX -= seg.curve * centrifugalForce * (speed / maxSpeed) * dt;
    playerX = playerX.clamp(-1.5, 1.5);

    // Ralentir hors piste
    if (playerX.abs() > 1.0) {
      speed *= 0.97;
    }

    // Avancer
    position += speed * dt;

    // Vérifier tour
    final newLap = (position / (trackSegments * segmentLength)).floor();
    if (newLap > currentLap) {
      currentLap = newLap;
      if (currentLap >= totalLaps) {
        _finishRace();
        return;
      }
    }

    // IA adversaires
    for (final opp in opponents) {
      // Vitesse variable
      opp.speed += (_random.nextDouble() - 0.48) * 50 * dt;
      opp.speed = opp.speed.clamp(80, 170);
      opp.position += opp.speed * dt;

      // Suivre la route
      final oppSeg =
          (opp.position / segmentLength).floor() % trackSegments;
      opp.x -= segments[oppSeg].curve * 0.2 * dt;
      opp.x += (_random.nextDouble() - 0.5) * 0.5 * dt;
      opp.x = opp.x.clamp(-0.8, 0.8);

      // Collision joueur/adversaire
      final relPos = opp.position - position;
      if (relPos.abs() < segmentLength * 2 &&
          (opp.x - playerX).abs() < 0.3) {
        speed *= 0.7;
        opp.speed *= 0.7;
      }
    }

    // Calculer le classement
    _updateRank();

    onStateChanged();
  }

  void _updateRank() {
    int rank = 1;
    for (final opp in opponents) {
      if (opp.position > position) rank++;
    }
    playerRank = rank;
  }

  void _finishRace() {
    _updateRank();
    // Score basé sur le classement et le temps
    score = switch (playerRank) {
      1 => 1000,
      2 => 700,
      3 => 500,
      4 => 300,
      5 => 200,
      _ => 100,
    };
    // Bonus temps
    score += max(0, (300 - raceTimer.toInt()) * 2);
    won = playerRank <= 3;
    gameOver = true;
    onGameOver(score);
  }

  /// Données de rendu pour le painter
  double getTrackPosition() => position;

  TrackSegment getSegment(int offset) {
    final idx = ((position / segmentLength).floor() + offset) %
        trackSegments;
    return segments[idx.abs()];
  }

  List<KartOpponentRender> getVisibleOpponents(int drawDistance) {
    final result = <KartOpponentRender>[];
    for (final opp in opponents) {
      final relPos = opp.position - position;
      if (relPos > 0 && relPos < drawDistance * segmentLength) {
        result.add(KartOpponentRender(
          segmentOffset: (relPos / segmentLength).floor(),
          x: opp.x,
          color: opp.color,
        ));
      }
    }
    return result;
  }
}

enum SpriteType { tree, sign }

class TrackSegment {
  final int index;
  final double curve;
  final double hill;
  final SpriteType? leftSprite;
  final SpriteType? rightSprite;

  TrackSegment({
    required this.index,
    required this.curve,
    required this.hill,
    this.leftSprite,
    this.rightSprite,
  });
}

class KartOpponent {
  double position;
  double x;
  double speed;
  final Color color;

  KartOpponent({
    required this.position,
    required this.x,
    required this.speed,
    required this.color,
  });
}

class KartOpponentRender {
  final int segmentOffset;
  final double x;
  final Color color;

  KartOpponentRender({
    required this.segmentOffset,
    required this.x,
    required this.color,
  });
}

/// Painter pseudo-3D pour la course
class KartPainter extends CustomPainter {
  final KartGame game;
  static const int drawDistance = 80;

  KartPainter(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final halfH = h / 2;

    // Ciel
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, halfH),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [Color(0xFF0055AA), Color(0xFF87CEEB)],
        ).createShader(Rect.fromLTWH(0, 0, w, halfH)),
    );

    // Montagnes en fond
    final mountainPath = Path()..moveTo(0, halfH);
    for (double x = 0; x <= w; x += 20) {
      final mh = halfH - 30 - sin(x / 50) * 25 - cos(x / 30) * 15;
      mountainPath.lineTo(x, mh);
    }
    mountainPath.lineTo(w, halfH);
    mountainPath.close();
    canvas.drawPath(
      mountainPath,
      Paint()..color = const Color(0xFF2E7D32),
    );

    // Route — rendu segment par segment du plus loin au plus proche
    double cumulativeCurve = 0;
    final visibleOpponents = game.getVisibleOpponents(drawDistance);

    for (int i = drawDistance; i > 0; i--) {
      final seg = game.getSegment(i);

      // Perspective
      final p = i / drawDistance.toDouble();
      final scale = 1.0 / (p * p * 3 + 0.3);
      final y = halfH + (h * 0.45) * (1 - 1 / (p * 3 + 0.1));

      final nextP = (i - 1) / drawDistance.toDouble();
      final nextY = halfH + (h * 0.45) * (1 - 1 / (nextP * 3 + 0.1));

      cumulativeCurve += seg.curve * scale * 0.5;
      final xOffset = cumulativeCurve * w * 0.3 - game.playerX * w * 0.2 * scale;

      final roadW = w * 0.6 * scale;
      final cx = w / 2 + xOffset;

      // Couleur route alternée
      final isStripe = (seg.index + (game.position / KartGame.segmentLength).floor()) % 2 == 0;

      // Herbe
      final grassColor = isStripe
          ? const Color(0xFF228B22)
          : const Color(0xFF1B7A1B);
      canvas.drawRect(
        Rect.fromLTRB(0, y, w, nextY),
        Paint()..color = grassColor,
      );

      // Route
      final roadColor = isStripe
          ? const Color(0xFF444444)
          : const Color(0xFF555555);
      canvas.drawRect(
        Rect.fromLTRB(cx - roadW, y, cx + roadW, nextY),
        Paint()..color = roadColor,
      );

      // Bordures rouge/blanc
      final rumbleW = roadW * 1.15;
      final rumbleColor = isStripe ? Colors.red : Colors.white;
      // Gauche
      canvas.drawRect(
        Rect.fromLTRB(cx - rumbleW, y, cx - roadW, nextY),
        Paint()..color = rumbleColor,
      );
      // Droite
      canvas.drawRect(
        Rect.fromLTRB(cx + roadW, y, cx + rumbleW, nextY),
        Paint()..color = rumbleColor,
      );

      // Ligne centrale pointillée
      if (isStripe) {
        final lineW = roadW * 0.02;
        canvas.drawRect(
          Rect.fromLTRB(cx - lineW, y, cx + lineW, nextY),
          Paint()..color = Colors.white,
        );
      }

      // Sprites (arbres, panneaux)
      if (seg.leftSprite != null) {
        _drawSprite(canvas, cx - rumbleW - roadW * 0.5, y,
            scale, seg.leftSprite!);
      }
      if (seg.rightSprite != null) {
        _drawSprite(canvas, cx + rumbleW + roadW * 0.5, y,
            scale, seg.rightSprite!);
      }

      // Adversaires
      for (final opp in visibleOpponents) {
        if (opp.segmentOffset == i) {
          _drawKart(canvas, cx + opp.x * roadW, y, scale, opp.color);
        }
      }
    }

    // Kart du joueur (en bas au centre)
    _drawPlayerKart(canvas, w, h);
  }

  void _drawSprite(
      Canvas canvas, double x, double y, double scale, SpriteType type) {
    if (scale < 0.05) return;
    switch (type) {
      case SpriteType.tree:
        // Tronc
        final trunkW = 4 * scale;
        final trunkH = 20 * scale;
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y - trunkH / 2),
            width: trunkW,
            height: trunkH,
          ),
          Paint()..color = const Color(0xFF5D4037),
        );
        // Feuillage
        canvas.drawCircle(
          Offset(x, y - trunkH),
          12 * scale,
          Paint()..color = const Color(0xFF1B5E20),
        );
        canvas.drawCircle(
          Offset(x - 5 * scale, y - trunkH + 5 * scale),
          10 * scale,
          Paint()..color = const Color(0xFF2E7D32),
        );
      case SpriteType.sign:
        final signH = 18 * scale;
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y - signH / 2),
            width: 3 * scale,
            height: signH,
          ),
          Paint()..color = Colors.grey,
        );
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y - signH),
            width: 12 * scale,
            height: 8 * scale,
          ),
          Paint()..color = Colors.yellow,
        );
    }
  }

  void _drawKart(
      Canvas canvas, double x, double y, double scale, Color color) {
    if (scale < 0.05) return;
    final kartW = 30 * scale;
    final kartH = 15 * scale;
    // Corps
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, y - kartH / 2),
          width: kartW,
          height: kartH,
        ),
        Radius.circular(3 * scale),
      ),
      Paint()..color = color,
    );
    // Casque
    canvas.drawCircle(
      Offset(x, y - kartH),
      5 * scale,
      Paint()..color = Colors.white,
    );
  }

  void _drawPlayerKart(Canvas canvas, double w, double h) {
    final cx = w / 2;
    final by = h - 30;
    const kartW = 70.0;
    const kartH = 35.0;

    // Ombre
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, by + 5),
        width: kartW * 1.1,
        height: 10,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Corps du kart
    final bodyPath = Path()
      ..moveTo(cx - kartW / 2, by)
      ..lineTo(cx - kartW / 3, by - kartH)
      ..lineTo(cx + kartW / 3, by - kartH)
      ..lineTo(cx + kartW / 2, by)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFFE53935));
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFFB71C1C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Roues
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - kartW / 2 + 5, by + 2),
        width: 14,
        height: 8,
      ),
      Paint()..color = Colors.black,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + kartW / 2 - 5, by + 2),
        width: 14,
        height: 8,
      ),
      Paint()..color = Colors.black,
    );

    // Casque pilote
    canvas.drawCircle(
      Offset(cx, by - kartH - 5),
      10,
      Paint()..color = Colors.white,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, by - kartH - 5),
        width: 20,
        height: 20,
      ),
      pi,
      pi,
      true,
      Paint()..color = const Color(0xFFE53935),
    );

    // Vitesse visuelle — lignes de vitesse
    if (game.speed > 100) {
      final alpha = ((game.speed - 100) / 100).clamp(0.0, 0.5);
      for (int i = 0; i < 3; i++) {
        final lineY = by - 10 - i * 12.0;
        canvas.drawLine(
          Offset(cx - kartW / 2 - 10 - i * 5, lineY),
          Offset(cx - kartW / 2 - 25 - i * 5, lineY + 5),
          Paint()
            ..color = Colors.white.withValues(alpha: alpha)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          Offset(cx + kartW / 2 + 10 + i * 5, lineY),
          Offset(cx + kartW / 2 + 25 + i * 5, lineY + 5),
          Paint()
            ..color = Colors.white.withValues(alpha: alpha)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
