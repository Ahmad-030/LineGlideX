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
    _drawMotorbike(canvas);
    _drawParticles(canvas);
  }

  void _drawGoalLine(Canvas canvas, Size size) {
    if (targetDistance >= 999999) return;
    final goalWorldX = targetDistance * 10.0;
    final goalScreenX = goalWorldX - cameraX;
    if (goalScreenX < -50 || goalScreenX > size.width + 50) return;

    final paint = Paint()
      ..color = const Color(0xFF3FB950).withOpacity(0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(goalScreenX, y), Offset(goalScreenX, y + 14), paint);
      y += 22;
    }

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

      if (si == 0) {
        final sp = (phase == GamePhase.drawing) ? seg.points.first : w2s(seg.points.first);
        canvas.drawCircle(sp, 8, Paint()..color = GameConstants.accentGreen);
        canvas.drawCircle(sp, 8,
            Paint()
              ..color = Colors.white.withOpacity(0.35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
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
          Paint()..color = GameConstants.accentCyan.withOpacity(frac * 0.4));
    }
  }

  // ─── Proper Motorbike + Rider ─────────────────────────────────────────────

  void _drawMotorbike(Canvas canvas) {
    if (rider == null) return;
    final sp = w2s(rider!.position);

    canvas.save();
    canvas.translate(sp.dx, sp.dy);
    canvas.rotate(rider!.angle);

    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 16), width: 56, height: 10),
      Paint()..color = Colors.black.withOpacity(0.28),
    );

    _drawBikeBody(canvas);
    _drawBikeRider(canvas);

    canvas.restore();
  }

  void _drawBikeBody(Canvas canvas) {
    // ── Rear wheel ──
    _drawWheel(canvas, const Offset(-16, 14), 11);

    // ── Front wheel ──
    _drawWheel(canvas, const Offset(16, 14), 10);

    // ── Swingarm (rear suspension) ──
    canvas.drawLine(
      const Offset(-3, 4),
      const Offset(-16, 14),
      Paint()
        ..color = const Color(0xFF444C56)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // ── Chain / engine area ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-10, 0, 20, 9), const Radius.circular(3)),
      Paint()..color = const Color(0xFF21262D),
    );

    // ── Main frame ──
    final framePath = Path()
      ..moveTo(-12, 4)   // rear top
      ..lineTo(4, -8)    // top spine toward front
      ..lineTo(14, -4)   // front fork top
      ..lineTo(16, 14)   // front axle
      ..lineTo(-1, 6)    // bottom bracket
      ..lineTo(-16, 14)  // rear axle
      ..close();
    canvas.drawPath(
      framePath,
      Paint()..color = const Color(0xFF1C2A3A),
    );
    canvas.drawPath(
      framePath,
      Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // ── Fuel tank ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-8, -11, 16, 8), const Radius.circular(4)),
      Paint()..color = const Color(0xFF238636),
    );
    // Tank highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-5, -10, 8, 3), const Radius.circular(2)),
      Paint()..color = const Color(0xFF3FB950).withOpacity(0.6),
    );

    // ── Fairing / headlight ──
    final fairingPath = Path()
      ..moveTo(10, -6)
      ..lineTo(18, -2)
      ..lineTo(18, 4)
      ..lineTo(10, 2)
      ..close();
    canvas.drawPath(fairingPath, Paint()..color = const Color(0xFF1C2A3A));
    // Headlight
    canvas.drawOval(
      const Rect.fromLTWH(14, -1, 6, 5),
      Paint()..color = const Color(0xFFFFDD00).withOpacity(0.9),
    );
    canvas.drawOval(
      const Rect.fromLTWH(14, -1, 6, 5),
      Paint()
        ..color = const Color(0xFFFFDD00).withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // ── Exhaust pipe ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-20, 6, 10, 3), const Radius.circular(1.5)),
      Paint()..color = const Color(0xFF8B949E),
    );
    // Exhaust tip
    canvas.drawOval(
      const Rect.fromLTWH(-22, 6, 5, 3),
      Paint()..color = const Color(0xFF6E7681),
    );

    // ── Front fork ──
    canvas.drawLine(
      const Offset(12, -4),
      const Offset(16, 14),
      Paint()
        ..color = const Color(0xFF58A6FF)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // ── Seat ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, -13, 14, 5), const Radius.circular(3)),
      Paint()..color = const Color(0xFF161B22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, -13, 14, 5), const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFF8B949E).withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawWheel(Canvas canvas, Offset center, double radius) {
    // Tyre (outer ring)
    canvas.drawCircle(
      center, radius,
      Paint()..color = const Color(0xFF21262D),
    );
    // Tyre highlight
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = const Color(0xFF444C56)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    // Hub
    canvas.drawCircle(
      center, radius * 0.38,
      Paint()..color = const Color(0xFF58A6FF),
    );
    // Spokes × 4
    for (int s = 0; s < 4; s++) {
      final ang = s * pi / 4;
      canvas.drawLine(
        Offset(center.dx + cos(ang) * radius * 0.38, center.dy + sin(ang) * radius * 0.38),
        Offset(center.dx + cos(ang) * radius * 0.9, center.dy + sin(ang) * radius * 0.9),
        Paint()
          ..color = const Color(0xFF8B949E)
          ..strokeWidth = 1,
      );
    }
  }

  void _drawBikeRider(Canvas canvas) {
    // ── Legs / boots ──
    // Left leg (far side — slightly behind)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-10, -6, 5, 10), const Radius.circular(2)),
      Paint()..color = const Color(0xFF1C2A3A).withOpacity(0.7),
    );
    // Right leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-6, -6, 5, 10), const Radius.circular(2)),
      Paint()..color = const Color(0xFF1C2A3A),
    );
    // Boots
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-10, 2, 9, 4), const Radius.circular(2)),
      Paint()..color = const Color(0xFF0D1117),
    );

    // ── Body / jacket ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-9, -18, 14, 13), const Radius.circular(4)),
      Paint()..color = const Color(0xFF238636),
    );
    // Jacket stripe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-9, -14, 14, 3), const Radius.circular(1)),
      Paint()..color = const Color(0xFF00E5FF).withOpacity(0.5),
    );

    // ── Arms (reaching forward to handlebar) ──
    canvas.drawLine(
      const Offset(0, -15),
      const Offset(10, -10),
      Paint()
        ..color = const Color(0xFF238636)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // Glove
    canvas.drawCircle(
      const Offset(10, -10), 3,
      Paint()..color = const Color(0xFF0D1117),
    );

    // ── Handlebar ──
    canvas.drawLine(
      const Offset(7, -12),
      const Offset(13, -12),
      Paint()
        ..color = const Color(0xFF8B949E)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // ── Neck ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-2, -22, 5, 5), const Radius.circular(2)),
      Paint()..color = const Color(0xFFF0D9B5),
    );

    // ── Helmet ──
    // Helmet shell
    canvas.drawOval(
      const Rect.fromLTWH(-8, -34, 18, 16),
      Paint()..color = const Color(0xFF238636),
    );
    // Helmet visor / stripe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -29, 12, 5), const Radius.circular(3)),
      Paint()..color = const Color(0xFF00E5FF).withOpacity(0.85),
    );
    // Visor glare
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-2, -28, 4, 2), const Radius.circular(1)),
      Paint()..color = Colors.white.withOpacity(0.55),
    );
    // Helmet outline
    canvas.drawOval(
      const Rect.fromLTWH(-8, -34, 18, 16),
      Paint()
        ..color = const Color(0xFF3FB950).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawParticles(Canvas canvas) {
    for (final p in particles) {
      canvas.drawCircle(
          w2s(p.position), p.radius, Paint()..color = p.color.withOpacity(p.opacity));
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter old) => true;
}