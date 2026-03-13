import 'dart:math';
import 'package:flutter/material.dart';
import 'game_models.dart';
import 'game_constants.dart';

class GridPainter extends CustomPainter {
  final double cameraX;
  final double cameraY;
  const GridPainter({required this.cameraX, required this.cameraY});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GameConstants.gridColor
      ..strokeWidth = 1;
    const step = 40.0;
    final startX = -(cameraX % step);
    final startY = -(cameraY % step);
    for (double x = startX; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = startY; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) =>
      old.cameraX != cameraX || old.cameraY != cameraY;
}

class GamePainter extends CustomPainter {
  final List<TrackSegment> segments;
  final List<Offset> currentStroke;
  final RiderState? rider;
  final List<Particle> particles;
  final List<Offset> riderTrail;
  final List<Obstacle> obstacles;
  final GamePhase phase;
  final double cameraX;
  final double cameraY;
  final int currentLevel;
  final int targetDistance;
  final int distanceTravelled;

  GamePainter({
    required this.segments,
    required this.currentStroke,
    required this.rider,
    required this.particles,
    required this.riderTrail,
    required this.obstacles,
    required this.phase,
    required this.cameraX,
    required this.cameraY,
    required this.currentLevel,
    required this.targetDistance,
    required this.distanceTravelled,
  });

  Offset w2s(Offset world) => Offset(world.dx - cameraX, world.dy - cameraY);

  @override
  void paint(Canvas canvas, Size size) {
    _drawGoalLine(canvas, size);
    _drawSegments(canvas);
    _drawObstacles(canvas);
    _drawCurrentStroke(canvas);
    _drawTrail(canvas);
    _drawRider(canvas);
    _drawParticles(canvas);
  }

  void _drawGoalLine(Canvas canvas, Size size) {
    if (targetDistance >= 999999) return;
    // Goal line in world space: x = targetDistance * 10
    final goalWorldX = targetDistance * 10.0;
    final goalScreenX = goalWorldX - cameraX;
    if (goalScreenX < -50 || goalScreenX > size.width + 50) return;

    final paint = Paint()
      ..color = const Color(0xFF3FB950).withOpacity(0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Dashed line
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(goalScreenX, y), Offset(goalScreenX, y + 14), paint);
      y += 22;
    }

    // Goal label
    final tp = TextPainter(
      text: TextSpan(
        text: '🏁 GOAL',
        style: TextStyle(
          color: const Color(0xFF3FB950),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(goalScreenX + 6, 60));
  }

  void _drawSegments(Canvas canvas) {
    for (int si = 0; si < segments.length; si++) {
      final seg = segments[si];
      if (seg.points.length < 2) continue;

      final pts = (phase == GamePhase.drawing)
          ? seg.points
          : seg.points.map(w2s).toList();

      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }

      // Glow
      canvas.drawPath(
        path,
        Paint()
          ..color = GameConstants.trackGlow.withOpacity(0.08)
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // Main line
      canvas.drawPath(
        path,
        Paint()
          ..color = GameConstants.trackColor
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );

      // Start dot
      if (si == 0) {
        final sp = (phase == GamePhase.drawing) ? seg.points.first : w2s(seg.points.first);
        canvas.drawCircle(sp, 8, Paint()..color = GameConstants.accentGreen);
        canvas.drawCircle(
          sp, 8,
          Paint()
            ..color = Colors.white.withOpacity(0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  void _drawObstacles(Canvas canvas) {
    for (final obs in obstacles) {
      if (obs.hit) continue;
      final sp = w2s(obs.worldPos);
      obs.type == ObstacleType.spike ? _drawSpike(canvas, sp) : _drawBox(canvas, sp);
    }
  }

  void _drawSpike(Canvas canvas, Offset sp) {
    final path = Path()
      ..moveTo(sp.dx, sp.dy - 28)
      ..lineTo(sp.dx - 13, sp.dy)
      ..lineTo(sp.dx + 13, sp.dy)
      ..close();
    canvas.drawPath(path,
        Paint()
          ..color = const Color(0xFFFF2222).withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawPath(path, Paint()..color = const Color(0xFFFF2222).withOpacity(0.92));
    canvas.drawPath(path,
        Paint()
          ..color = const Color(0xFFFF9999)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  void _drawBox(Canvas canvas, Offset sp) {
    const h = 18.0;
    final rect = Rect.fromLTWH(sp.dx - h, sp.dy - h, h * 2, h * 2);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()
          ..color = const Color(0xFFFF6600).withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()..color = const Color(0xFFFF6600).withOpacity(0.92));
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()
          ..color = const Color(0xFFFFAA44)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final tp = TextPainter(
      text: const TextSpan(text: '⚠', style: TextStyle(fontSize: 20, color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, sp - const Offset(10, 11));
  }

  void _drawCurrentStroke(Canvas canvas) {
    if (currentStroke.length < 2) return;
    final pts = (phase == GamePhase.riding || phase == GamePhase.levelComplete)
        ? currentStroke.map(w2s).toList()
        : currentStroke;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path,
        Paint()
          ..color = GameConstants.accentGreen.withOpacity(0.85)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke);
  }

  void _drawTrail(Canvas canvas) {
    for (int i = 0; i < riderTrail.length; i++) {
      final frac = i / riderTrail.length;
      canvas.drawCircle(w2s(riderTrail[i]), 3.5 * frac,
          Paint()..color = GameConstants.accentCyan.withOpacity(frac * 0.55));
    }
  }

  void _drawRider(Canvas canvas) {
    if (rider == null) return;
    final sp = w2s(rider!.position);

    canvas.save();
    canvas.translate(sp.dx, sp.dy);
    canvas.rotate(rider!.angle);

    // Shadow
    canvas.drawCircle(const Offset(0, 2), 14, Paint()..color = Colors.black.withOpacity(0.35));

    // Board
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-17, 5, 34, 6), const Radius.circular(3)),
        Paint()..color = const Color(0xFF8B949E));

    // Wheels
    for (final ox in [-11.0, 11.0]) {
      canvas.drawCircle(Offset(ox, 12), 5.5, Paint()..color = const Color(0xFF21262D));
      canvas.drawCircle(Offset(ox, 12), 3.5, Paint()..color = const Color(0xFF8B949E));
    }

    // Body
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -9, 14, 16), const Radius.circular(5)),
        Paint()..color = GameConstants.riderGreen);

    // Head
    canvas.drawCircle(const Offset(0, -18), 9, Paint()..color = const Color(0xFFF0D9B5));
    canvas.drawCircle(const Offset(3, -19), 2.5, Paint()..color = const Color(0xFF1C1C1C));

    // Scarf
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -11, 14, 4), const Radius.circular(2)),
        Paint()..color = GameConstants.accentRed);

    canvas.restore();
  }

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      canvas.drawCircle(w2s(p.position), p.radius,
          Paint()..color = p.color.withOpacity(p.opacity));
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter old) => true;
}