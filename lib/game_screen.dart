import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'game_constants.dart';
import 'game_models.dart';
import 'game_painter.dart';
import 'save_service.dart';

class GameScreen extends StatefulWidget {
  final int startLevel;
  final int highScore;

  const GameScreen({super.key, required this.startLevel, required this.highScore});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  final List<TrackSegment> _segments = [];
  List<Offset> _currentStroke = [];
  GamePhase _phase = GamePhase.drawing;
  RiderState? _rider;
  List<Particle> _particles = [];
  late Ticker _ticker;
  double _elapsed = 0;
  bool _canUndo = false;
  double _riderTrailTimer = 0;
  final List<Offset> _riderTrail = [];

  // Camera
  double _cameraX = 0;
  double _cameraY = 0;

  // Obstacles
  final List<Obstacle> _obstacles = [];
  double _nextObstacleX = 800;

  // Level & scoring
  late int _currentLevel;
  late int _highScore;
  int _distanceMeters = 0;
  int _targetDistance = 300;
  double _levelStartX = 0;

  // Pencil is ALWAYS on during riding - no toggle needed
  bool _isDrawingStroke = false;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.startLevel;
    _highScore = widget.highScore;
    _loadLevelConfig();
    _ticker = createTicker(_onTick)..start();
  }

  void _loadLevelConfig() {
    final lvl = GameConstants.getLevel(_currentLevel);
    _targetDistance = lvl['distance'] as int;
  }

  // ─── Camera ───────────────────────────────────────────────────────────────

  Offset worldToScreen(Offset world) => Offset(world.dx - _cameraX, world.dy - _cameraY);
  Offset screenToWorld(Offset screen) => Offset(screen.dx + _cameraX, screen.dy + _cameraY);

  void _updateCamera(Size size) {
    if (_rider == null) return;
    final targetX = _rider!.position.dx - size.width * GameConstants.riderScreenXFraction;
    final targetY = _rider!.position.dy - size.height * 0.46;
    _cameraX += (targetX - _cameraX) * 0.09;
    _cameraY += (targetY - _cameraY) * 0.07;
  }

  // ─── Tick ─────────────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    final dt = (elapsed.inMicroseconds - _elapsed) / 1e6;
    _elapsed = elapsed.inMicroseconds.toDouble();
    if (dt <= 0 || dt > 0.1) return;

    if (_phase == GamePhase.riding && _rider != null) {
      final size = MediaQuery.of(context).size;
      _updatePhysics(dt, size);
      _updateCamera(size);
      _spawnObstacles();
      _checkObstacleCollisions();
      _checkLevelComplete();
    }

    _particles = _particles.map((p) {
      return Particle(
        position: p.position + p.velocity * dt,
        velocity: Offset(p.velocity.dx * 0.98, p.velocity.dy + 280 * dt),
        opacity: p.opacity - dt * 1.1,
        color: p.color,
        radius: p.radius,
      );
    }).where((p) => p.opacity > 0).toList();

    if (mounted) setState(() {});
  }

  // ─── Physics ──────────────────────────────────────────────────────────────

  void _updatePhysics(double dt, Size size) {
    final rider = _rider!;

    rider.velocity = Offset(
      rider.velocity.dx * GameConstants.friction,
      rider.velocity.dy + GameConstants.gravity * dt,
    );

    Offset newPos = rider.position + rider.velocity * dt;

    bool landed = false;
    for (final seg in _segments) {
      final result = _resolveCollision(newPos, rider.velocity, seg.points);
      if (result != null) {
        newPos = result.$1;
        rider.velocity = result.$2;
        rider.angle = result.$3;
        landed = true;
        break;
      }
    }

    rider.onGround = landed;
    rider.position = newPos;

    // Distance from level start
    _distanceMeters = ((newPos.dx - _levelStartX) / 10).floor().clamp(0, 999999);
    if (_distanceMeters > _highScore) {
      _highScore = _distanceMeters;
    }

    _riderTrailTimer += dt;
    if (_riderTrailTimer > 0.04) {
      _riderTrailTimer = 0;
      _riderTrail.add(rider.position);
      if (_riderTrail.length > 30) _riderTrail.removeAt(0);
    }

    if (newPos.dy > _cameraY + size.height + 300) {
      _crash(newPos);
    }
  }

  (Offset, Offset, double)? _resolveCollision(Offset pos, Offset vel, List<Offset> pts) {
    for (int i = 0; i < pts.length - 1; i++) {
      final r = _segmentCollision(pos, vel, pts[i], pts[i + 1]);
      if (r != null) return r;
    }
    return null;
  }

  (Offset, Offset, double)? _segmentCollision(Offset pos, Offset vel, Offset a, Offset b) {
    final ab = b - a;
    final len = ab.distance;
    if (len < 1) return null;

    final tangent = Offset(ab.dx / len, ab.dy / len);
    Offset normal = Offset(-tangent.dy, tangent.dx);
    if (normal.dy > 0) normal = Offset(tangent.dy, -tangent.dx);

    final ap = pos - a;
    final tParam = ap.dx * tangent.dx + ap.dy * tangent.dy;
    if (tParam <= 0 || tParam >= len) return null;

    final dist = ap.dx * normal.dx + ap.dy * normal.dy;
    if (dist < 0 || dist > GameConstants.riderSize + 10.0) return null;

    final velN = vel.dx * normal.dx + vel.dy * normal.dy;
    if (velN > 0) return null;

    final newPos = pos + normal * (GameConstants.riderSize - dist);
    final velT = vel.dx * tangent.dx + vel.dy * tangent.dy;
    final newVel = tangent * (velT * 0.995) + normal * (-velN * 0.08);

    return (newPos, newVel, atan2(ab.dy, ab.dx));
  }

  // ─── Obstacles ────────────────────────────────────────────────────────────

  void _spawnObstacles() {
    if (_rider == null) return;
    final lvl = GameConstants.getLevel(_currentLevel);
    final mult = (lvl['obstacleMultiplier'] as double);
    if (mult == 0) return;

    final spacing = GameConstants.obstacleBaseSpacing / mult;

    while (_nextObstacleX < _rider!.position.dx + 1400) {
      final type = _rng.nextBool() ? ObstacleType.spike : ObstacleType.box;
      final y = _rider!.position.dy + _rng.nextDouble() * 20 - 30;
      _obstacles.add(Obstacle(worldPos: Offset(_nextObstacleX, y), type: type));
      _nextObstacleX += spacing * (0.65 + _rng.nextDouble() * 0.7);
    }
    _obstacles.removeWhere((o) => o.worldPos.dx < _cameraX - 400);
  }

  void _checkObstacleCollisions() {
    if (_rider == null) return;
    final rp = _rider!.position;
    for (final obs in _obstacles) {
      if (obs.hit) continue;
      final r = _obstacleRect(obs);
      final closest = Offset(rp.dx.clamp(r.left, r.right), rp.dy.clamp(r.top, r.bottom));
      if ((rp - closest).distance < GameConstants.riderSize + 2) {
        obs.hit = true;
        _crash(rp);
        return;
      }
    }
  }

  Rect _obstacleRect(Obstacle obs) {
    return obs.type == ObstacleType.spike
        ? Rect.fromLTWH(obs.worldPos.dx - 13, obs.worldPos.dy - 28, 26, 28)
        : Rect.fromLTWH(obs.worldPos.dx - 18, obs.worldPos.dy - 18, 36, 36);
  }

  void _checkLevelComplete() {
    if (_targetDistance >= 999999) return;
    if (_distanceMeters >= _targetDistance) {
      _levelComplete();
    }
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _crash(Offset worldPos) {
    _phase = GamePhase.crashed;
    _saveProgress(crashed: true);
    for (int i = 0; i < 32; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 90 + _rng.nextDouble() * 210;
      _particles.add(Particle(
        position: worldPos,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        opacity: 1.0,
        color: [
          const Color(0xFFFF4444),
          const Color(0xFFFF8800),
          const Color(0xFFFFDD00),
          Colors.white,
        ][i % 4],
        radius: 3 + _rng.nextDouble() * 6,
      ));
    }
  }

  void _levelComplete() {
    _phase = GamePhase.levelComplete;
    _saveProgress(crashed: false);
    // Celebration particles
    for (int i = 0; i < 50; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 60 + _rng.nextDouble() * 180;
      _particles.add(Particle(
        position: _rider!.position,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed - 100),
        opacity: 1.0,
        color: [
          const Color(0xFF3FB950),
          const Color(0xFF00E5FF),
          const Color(0xFFFFDD00),
          const Color(0xFFFF9800),
          Colors.white,
        ][i % 5],
        radius: 4 + _rng.nextDouble() * 5,
      ));
    }
  }

  Future<void> _saveProgress({required bool crashed}) async {
    final nextLevel = crashed
        ? _currentLevel
        : (_currentLevel + 1).clamp(1, GameConstants.maxLevel());
    final data = SaveData(
      currentLevel: nextLevel,
      highScore: _highScore,
    );
    await SaveService.save(data);
  }

  void _startRiding() {
    if (_segments.isEmpty) return;
    final firstSeg = _segments.first;
    if (firstSeg.points.length < 2) return;

    final a = firstSeg.points[0];
    final b = firstSeg.points[1];
    final ab = b - a;
    final len = ab.distance;
    final tangent = Offset(ab.dx / len, ab.dy / len);
    Offset normal = Offset(-tangent.dy, tangent.dx);
    if (normal.dy > 0) normal = Offset(tangent.dy, -tangent.dx);

    final startPos = a + normal * GameConstants.riderSize + tangent * 10;
    _levelStartX = startPos.dx;

    setState(() {
      _phase = GamePhase.riding;
      _riderTrail.clear();
      _distanceMeters = 0;
      _obstacles.clear();
      _nextObstacleX = startPos.dx + 550;
      _rider = RiderState(position: startPos, velocity: tangent * GameConstants.startVelocity);
      final size = MediaQuery.of(context).size;
      _cameraX = startPos.dx - size.width * GameConstants.riderScreenXFraction;
      _cameraY = startPos.dy - size.height * 0.46;
    });
  }

  void _resetToDrawing() {
    setState(() {
      _segments.clear();
      _currentStroke = [];
      _phase = GamePhase.drawing;
      _rider = null;
      _particles.clear();
      _riderTrail.clear();
      _obstacles.clear();
      _distanceMeters = 0;
      _canUndo = false;
      _cameraX = 0;
      _cameraY = 0;
    });
  }

  void _nextLevel() {
    final nextLvl = (_currentLevel + 1).clamp(1, GameConstants.maxLevel());
    setState(() {
      _currentLevel = nextLvl;
      _loadLevelConfig();
    });
    _resetToDrawing();
  }

  void _undo() {
    if (_phase == GamePhase.drawing && _segments.isNotEmpty) {
      setState(() {
        _segments.removeLast();
        _canUndo = _segments.isNotEmpty;
      });
    }
  }

  void _goToMenu() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ─── Gestures ─────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    if (_phase == GamePhase.drawing) {
      _currentStroke = [d.localPosition];
    } else if (_phase == GamePhase.riding) {
      // Pencil always on during riding
      _isDrawingStroke = true;
      _currentStroke = [screenToWorld(d.localPosition)];
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_phase == GamePhase.drawing) {
      if (_currentStroke.isEmpty) return;
      if ((d.localPosition - _currentStroke.last).distance > 4) {
        setState(() => _currentStroke.add(d.localPosition));
      }
    } else if (_phase == GamePhase.riding && _isDrawingStroke) {
      final wp = screenToWorld(d.localPosition);
      if (_currentStroke.isEmpty || (wp - _currentStroke.last).distance > 4) {
        setState(() => _currentStroke.add(wp));
      }
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (_phase == GamePhase.drawing) {
      if (_currentStroke.length >= 2) {
        setState(() {
          _segments.add(TrackSegment(List.from(_currentStroke)));
          _canUndo = true;
        });
      }
      _currentStroke = [];
    } else if (_phase == GamePhase.riding && _isDrawingStroke) {
      if (_currentStroke.length >= 2) {
        setState(() => _segments.add(TrackSegment(List.from(_currentStroke))));
      }
      _currentStroke = [];
      _isDrawingStroke = false;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final lvlData = GameConstants.getLevel(_currentLevel);
    final lvlColor = Color(lvlData['color'] as int);

    return Scaffold(
      backgroundColor: GameConstants.bgColor,
      body: Stack(
        children: [
          // Scrolling grid
          CustomPaint(
            size: size,
            painter: GridPainter(cameraX: _cameraX, cameraY: _cameraY),
          ),

          // Game canvas
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              size: size,
              painter: GamePainter(
                segments: _segments,
                currentStroke: _currentStroke,
                rider: _rider,
                particles: _particles,
                riderTrail: _riderTrail,
                obstacles: _obstacles,
                phase: _phase,
                cameraX: _cameraX,
                cameraY: _cameraY,
                currentLevel: _currentLevel,
                targetDistance: _targetDistance,
                distanceTravelled: _distanceMeters,
              ),
            ),
          ),

          // HUD
          _buildHUD(lvlColor),

          // Progress bar (only while riding)
          if (_phase == GamePhase.riding && _targetDistance < 999999)
            _buildProgressBar(lvlColor),

          // Overlays
          if (_phase == GamePhase.crashed) _buildCrashOverlay(),
          if (_phase == GamePhase.levelComplete) _buildLevelCompleteOverlay(lvlColor),
          if (_phase == GamePhase.drawing && _segments.isEmpty && _currentStroke.isEmpty)
            _buildDrawingHint(),
        ],
      ),
    );
  }

  Widget _buildHUD(Color lvlColor) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            // Level badge
            _levelBadge(lvlColor),
            const SizedBox(width: 10),

            // Distance
            if (_phase == GamePhase.riding || _phase == GamePhase.crashed)
              _HudChip(
                icon: Icons.straighten,
                label: 'DIST',
                value: '${_distanceMeters}m',
                color: GameConstants.accentCyan,
              ),

            const Spacer(),

            // High score
            _HudChip(
              icon: Icons.emoji_events,
              label: 'BEST',
              value: '${_highScore}m',
              color: const Color(0xFFFFDD00),
            ),
            const SizedBox(width: 8),

            // Drawing phase controls
            if (_phase == GamePhase.drawing) ...[
              if (_canUndo)
                _iconBtn(Icons.undo_rounded, 'Undo', GameConstants.accentOrange, _undo),
              const SizedBox(width: 8),
              if (_segments.isNotEmpty)
                _primaryBtn('RIDE ▶', GameConstants.accentCyan, _startRiding),
            ],

            // Riding controls
            if (_phase == GamePhase.riding)
              _iconBtn(Icons.refresh_rounded, 'Retry', GameConstants.accentRed, _resetToDrawing),

            // Crashed / complete
            if (_phase == GamePhase.crashed || _phase == GamePhase.levelComplete)
              _iconBtn(Icons.home_rounded, 'Menu', GameConstants.accentCyan, _goToMenu),
          ],
        ),
      ),
    );
  }

  Widget _levelBadge(Color color) {
    final lvlData = GameConstants.getLevel(_currentLevel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LVL $_currentLevel',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          Text(
            lvlData['name'] as String,
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(Color lvlColor) {
    final progress = (_distanceMeters / _targetDistance).clamp(0.0, 1.0);
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 4,
        color: GameConstants.gridColor,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [lvlColor.withOpacity(0.7), lvlColor],
              ),
              boxShadow: [BoxShadow(color: lvlColor.withOpacity(0.6), blurRadius: 6)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCrashOverlay() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        builder: (ctx, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: GameConstants.accentRed.withOpacity(0.6), width: 2),
            boxShadow: [
              BoxShadow(color: GameConstants.accentRed.withOpacity(0.2), blurRadius: 40, spreadRadius: 4),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💥', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text('CRASHED!',
                  style: TextStyle(
                      color: Color(0xFFFF4444), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 4)),
              const SizedBox(height: 4),
              Text('Distance: ${_distanceMeters}m  •  Best: ${_highScore}m',
                  style: const TextStyle(color: Color(0xFF8B949E), fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              _targetDistance < 999999
                  ? Text(
                'Goal: ${_targetDistance}m',
                style: TextStyle(color: GameConstants.accentCyan.withOpacity(0.6), fontSize: 12),
              )
                  : const SizedBox.shrink(),
              const SizedBox(height: 22),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _primaryBtn('↺ RETRY', GameConstants.accentCyan, _resetToDrawing),
                  const SizedBox(width: 10),
                  _primaryBtn('⌂ MENU', GameConstants.accentOrange, _goToMenu),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCompleteOverlay(Color lvlColor) {
    final isLast = _currentLevel >= GameConstants.maxLevel();
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (ctx, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: lvlColor.withOpacity(0.7), width: 2),
            boxShadow: [
              BoxShadow(color: lvlColor.withOpacity(0.25), blurRadius: 40, spreadRadius: 4),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isLast ? '🏆' : '🎉', style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              Text(
                isLast ? 'YOU WIN!' : 'LEVEL COMPLETE!',
                style: TextStyle(
                    color: lvlColor, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3),
              ),
              const SizedBox(height: 4),
              Text(
                isLast
                    ? 'You completed all levels!'
                    : 'Level $_currentLevel cleared • ${_distanceMeters}m',
                style: const TextStyle(color: Color(0xFF8B949E), fontSize: 14),
              ),
              if (_highScore == _distanceMeters && _distanceMeters > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDD00).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFDD00).withOpacity(0.4)),
                  ),
                  child: const Text('🏅 NEW BEST!',
                      style: TextStyle(
                          color: Color(0xFFFFDD00), fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isLast)
                    _primaryBtn('NEXT ▶', lvlColor, _nextLevel),
                  if (!isLast) const SizedBox(width: 10),
                  _primaryBtn('⌂ MENU', GameConstants.accentOrange, _goToMenu),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawingHint() {
    final lvlData = GameConstants.getLevel(_currentLevel);
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gesture, color: Color(0xFF30363D), size: 72),
            const SizedBox(height: 14),
            Text(
              'Draw your track',
              style: TextStyle(
                  color: const Color(0xFF8B949E).withOpacity(0.65),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 6),
            Text(
              lvlData['description'] as String,
              style: TextStyle(
                  color: const Color(0xFF8B949E).withOpacity(0.4),
                  fontSize: 13,
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: 4),
            Text(
              'Goal: ${lvlData['distance']}m',
              style: TextStyle(
                  color: GameConstants.accentCyan.withOpacity(0.4),
                  fontSize: 12,
                  letterSpacing: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Mini widget helpers ──────────────────────────────────────────────────

  Widget _iconBtn(IconData icon, String tip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _primaryBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.6)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.14), blurRadius: 12)],
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
      ),
    );
  }
}

// ─── HUD Chip ──────────────────────────────────────────────────────────────

class _HudChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HudChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text('$label: ',
              style: TextStyle(color: color.withOpacity(0.65), fontSize: 10, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}