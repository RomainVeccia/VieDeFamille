import 'dart:math';
import 'package:flutter/material.dart';

/// Moteur Tetris complet — grille 10x20, 7 pièces, scoring classique
class TetrisGame {
  static const int cols = 10;
  static const int rows = 20;

  // Grille : 0 = vide, 1-7 = couleur de pièce
  final List<List<int>> grid =
      List.generate(rows, (_) => List.filled(cols, 0));

  // Pièce courante
  late List<List<int>> _currentPiece;
  late int _currentType;
  int _pieceX = 0;
  int _pieceY = 0;

  // Prochaine pièce
  late List<List<int>> _nextPiece;
  late int _nextType;

  int score = 0;
  int level = 1;
  int linesCleared = 0;
  bool gameOver = false;

  final VoidCallback onStateChanged;
  final void Function(int finalScore) onGameOver;
  final Random _random = Random();

  // Timing
  double _dropTimer = 0;
  double get _dropInterval => max(0.1, 1.0 - (level - 1) * 0.08);

  TetrisGame({
    required this.onStateChanged,
    required this.onGameOver,
  }) {
    _nextType = _random.nextInt(7);
    _nextPiece = _getPieceShape(_nextType);
    _spawnPiece();
  }

  List<List<int>> get nextPiece => _nextPiece;
  int get nextType => _nextType;

  // Couleurs des pièces (style classique NES)
  static const List<Color> pieceColors = [
    Color(0xFF00F0F0), // I - Cyan
    Color(0xFFF0F000), // O - Jaune
    Color(0xFFA000F0), // T - Violet
    Color(0xFF00F000), // S - Vert
    Color(0xFFF00000), // Z - Rouge
    Color(0xFF0000F0), // J - Bleu
    Color(0xFFF0A000), // L - Orange
  ];

  /// Les 7 pièces standard (rotations = rotation de la matrice)
  static List<List<int>> _getPieceShape(int type) {
    switch (type) {
      case 0: // I
        return [
          [0, 0, 0, 0],
          [1, 1, 1, 1],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ];
      case 1: // O
        return [
          [1, 1],
          [1, 1],
        ];
      case 2: // T
        return [
          [0, 1, 0],
          [1, 1, 1],
          [0, 0, 0],
        ];
      case 3: // S
        return [
          [0, 1, 1],
          [1, 1, 0],
          [0, 0, 0],
        ];
      case 4: // Z
        return [
          [1, 1, 0],
          [0, 1, 1],
          [0, 0, 0],
        ];
      case 5: // J
        return [
          [1, 0, 0],
          [1, 1, 1],
          [0, 0, 0],
        ];
      case 6: // L
        return [
          [0, 0, 1],
          [1, 1, 1],
          [0, 0, 0],
        ];
      default:
        return [
          [1]
        ];
    }
  }

  void _spawnPiece() {
    _currentType = _nextType;
    _currentPiece = _nextPiece;
    _nextType = _random.nextInt(7);
    _nextPiece = _getPieceShape(_nextType);
    _pieceX = (cols - _currentPiece[0].length) ~/ 2;
    _pieceY = 0;

    if (_collides(_currentPiece, _pieceX, _pieceY)) {
      gameOver = true;
      onGameOver(score);
    }
  }

  bool _collides(List<List<int>> piece, int px, int py) {
    for (int y = 0; y < piece.length; y++) {
      for (int x = 0; x < piece[y].length; x++) {
        if (piece[y][x] == 0) continue;
        final gx = px + x;
        final gy = py + y;
        if (gx < 0 || gx >= cols || gy >= rows) return true;
        if (gy >= 0 && grid[gy][gx] != 0) return true;
      }
    }
    return false;
  }

  void _lockPiece() {
    for (int y = 0; y < _currentPiece.length; y++) {
      for (int x = 0; x < _currentPiece[y].length; x++) {
        if (_currentPiece[y][x] == 0) continue;
        final gy = _pieceY + y;
        final gx = _pieceX + x;
        if (gy >= 0 && gy < rows && gx >= 0 && gx < cols) {
          grid[gy][gx] = _currentType + 1;
        }
      }
    }
    _clearLines();
    _spawnPiece();
  }

  void _clearLines() {
    int cleared = 0;
    for (int y = rows - 1; y >= 0; y--) {
      if (grid[y].every((c) => c != 0)) {
        grid.removeAt(y);
        grid.insert(0, List.filled(cols, 0));
        cleared++;
        y++; // Re-check la même ligne
      }
    }
    if (cleared > 0) {
      linesCleared += cleared;
      // Scoring classique
      final points = switch (cleared) {
        1 => 100,
        2 => 300,
        3 => 500,
        4 => 800,
        _ => 0,
      };
      score += points * level;
      level = (linesCleared ~/ 10) + 1;
    }
  }

  List<List<int>> _rotate(List<List<int>> piece) {
    final n = piece.length;
    final rotated = List.generate(n, (y) => List.generate(n, (x) => 0));
    for (int y = 0; y < n; y++) {
      for (int x = 0; x < n; x++) {
        rotated[x][n - 1 - y] = piece[y][x];
      }
    }
    return rotated;
  }

  // === Contrôles ===

  void moveLeft() {
    if (gameOver) return;
    if (!_collides(_currentPiece, _pieceX - 1, _pieceY)) {
      _pieceX--;
      onStateChanged();
    }
  }

  void moveRight() {
    if (gameOver) return;
    if (!_collides(_currentPiece, _pieceX + 1, _pieceY)) {
      _pieceX++;
      onStateChanged();
    }
  }

  void rotate() {
    if (gameOver) return;
    final rotated = _rotate(_currentPiece);
    // Wall kick basique
    for (final dx in [0, -1, 1, -2, 2]) {
      if (!_collides(rotated, _pieceX + dx, _pieceY)) {
        _currentPiece = rotated;
        _pieceX += dx;
        onStateChanged();
        return;
      }
    }
  }

  void softDrop() {
    if (gameOver) return;
    if (!_collides(_currentPiece, _pieceX, _pieceY + 1)) {
      _pieceY++;
      score += 1;
      onStateChanged();
    }
  }

  void hardDrop() {
    if (gameOver) return;
    while (!_collides(_currentPiece, _pieceX, _pieceY + 1)) {
      _pieceY++;
      score += 2;
    }
    _lockPiece();
    onStateChanged();
  }

  /// Appelé à chaque frame (delta en secondes)
  void update(double dt) {
    if (gameOver) return;
    _dropTimer += dt;
    if (_dropTimer >= _dropInterval) {
      _dropTimer = 0;
      if (!_collides(_currentPiece, _pieceX, _pieceY + 1)) {
        _pieceY++;
      } else {
        _lockPiece();
      }
      onStateChanged();
    }
  }

  /// Position fantôme (hard drop preview)
  int get ghostY {
    int gy = _pieceY;
    while (!_collides(_currentPiece, _pieceX, gy + 1)) {
      gy++;
    }
    return gy;
  }

  // === Rendu ===

  /// Dessine une cellule avec effet 3D bevel (style 90s)
  static void drawCell(Canvas canvas, double x, double y, double size,
      Color color,
      {double opacity = 1.0}) {
    final baseColor = color.withValues(alpha: opacity);
    final light =
        Color.lerp(baseColor, Colors.white, 0.3)!.withValues(alpha: opacity);
    final dark =
        Color.lerp(baseColor, Colors.black, 0.3)!.withValues(alpha: opacity);
    final bevel = size * 0.12;

    // Face principale
    canvas.drawRect(
      Rect.fromLTWH(x, y, size, size),
      Paint()..color = baseColor,
    );
    // Bord haut + gauche (clair)
    final lightPath = Path()
      ..moveTo(x, y + size)
      ..lineTo(x, y)
      ..lineTo(x + size, y)
      ..lineTo(x + size - bevel, y + bevel)
      ..lineTo(x + bevel, y + bevel)
      ..lineTo(x + bevel, y + size - bevel)
      ..close();
    canvas.drawPath(lightPath, Paint()..color = light);
    // Bord bas + droite (foncé)
    final darkPath = Path()
      ..moveTo(x + size, y)
      ..lineTo(x + size, y + size)
      ..lineTo(x, y + size)
      ..lineTo(x + bevel, y + size - bevel)
      ..lineTo(x + size - bevel, y + size - bevel)
      ..lineTo(x + size - bevel, y + bevel)
      ..close();
    canvas.drawPath(darkPath, Paint()..color = dark);
  }

  /// Grille complète avec pièce courante pour le painter
  List<List<int>> getDisplayGrid() {
    final display =
        List.generate(rows, (y) => List<int>.from(grid[y]));
    // Fantôme
    for (int y = 0; y < _currentPiece.length; y++) {
      for (int x = 0; x < _currentPiece[y].length; x++) {
        if (_currentPiece[y][x] == 0) continue;
        final gy = ghostY + y;
        final gx = _pieceX + x;
        if (gy >= 0 && gy < rows && gx >= 0 && gx < cols && display[gy][gx] == 0) {
          display[gy][gx] = -(_currentType + 1); // négatif = fantôme
        }
      }
    }
    // Pièce courante
    for (int y = 0; y < _currentPiece.length; y++) {
      for (int x = 0; x < _currentPiece[y].length; x++) {
        if (_currentPiece[y][x] == 0) continue;
        final gy = _pieceY + y;
        final gx = _pieceX + x;
        if (gy >= 0 && gy < rows && gx >= 0 && gx < cols) {
          display[gy][gx] = _currentType + 1;
        }
      }
    }
    return display;
  }
}

/// Painter pour le plateau Tetris
class TetrisPainter extends CustomPainter {
  final TetrisGame game;

  TetrisPainter(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = min(size.width / TetrisGame.cols,
        size.height / TetrisGame.rows);
    final offsetX = (size.width - cellSize * TetrisGame.cols) / 2;
    final offsetY = (size.height - cellSize * TetrisGame.rows) / 2;

    // Fond noir
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, cellSize * TetrisGame.cols,
          cellSize * TetrisGame.rows),
      Paint()..color = const Color(0xFF0A0A0A),
    );

    // Grille
    final gridPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (int y = 0; y <= TetrisGame.rows; y++) {
      canvas.drawLine(
        Offset(offsetX, offsetY + y * cellSize),
        Offset(offsetX + TetrisGame.cols * cellSize, offsetY + y * cellSize),
        gridPaint,
      );
    }
    for (int x = 0; x <= TetrisGame.cols; x++) {
      canvas.drawLine(
        Offset(offsetX + x * cellSize, offsetY),
        Offset(offsetX + x * cellSize, offsetY + TetrisGame.rows * cellSize),
        gridPaint,
      );
    }

    // Cellules
    final display = game.getDisplayGrid();
    for (int y = 0; y < TetrisGame.rows; y++) {
      for (int x = 0; x < TetrisGame.cols; x++) {
        final cell = display[y][x];
        if (cell == 0) continue;
        final isGhost = cell < 0;
        final colorIndex = (isGhost ? -cell : cell) - 1;
        final color = TetrisGame.pieceColors[colorIndex];
        TetrisGame.drawCell(
          canvas,
          offsetX + x * cellSize + 1,
          offsetY + y * cellSize + 1,
          cellSize - 2,
          color,
          opacity: isGhost ? 0.25 : 1.0,
        );
      }
    }

    // Bordure
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, cellSize * TetrisGame.cols,
          cellSize * TetrisGame.rows),
      Paint()
        ..color = const Color(0xFF444444)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Painter pour la preview de la prochaine pièce
class NextPiecePainter extends CustomPainter {
  final TetrisGame game;

  NextPiecePainter(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    final piece = game.nextPiece;
    final pieceSize = piece.length;
    final cellSize = min(size.width, size.height) / pieceSize;
    final offsetX = (size.width - cellSize * pieceSize) / 2;
    final offsetY = (size.height - cellSize * pieceSize) / 2;

    for (int y = 0; y < pieceSize; y++) {
      for (int x = 0; x < pieceSize; x++) {
        if (piece[y][x] == 0) continue;
        TetrisGame.drawCell(
          canvas,
          offsetX + x * cellSize + 1,
          offsetY + y * cellSize + 1,
          cellSize - 2,
          TetrisGame.pieceColors[game.nextType],
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
