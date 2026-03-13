import 'dart:ui';

class TrackSegment {
  final List<Offset> points;
  TrackSegment(this.points);
}

class Obstacle {
  final Offset worldPos;
  final ObstacleType type;
  bool hit;
  Obstacle({required this.worldPos, required this.type, this.hit = false});
}

enum ObstacleType { spike, box }

class Particle {
  Offset position;
  Offset velocity;
  double opacity;
  Color color;
  double radius;

  Particle({
    required this.position,
    required this.velocity,
    required this.opacity,
    required this.color,
    required this.radius,
  });
}

enum GamePhase { drawing, riding, crashed, levelComplete }

class RiderState {
  Offset position;
  Offset velocity;
  double angle;
  bool onGround;

  RiderState({
    required this.position,
    required this.velocity,
    this.angle = 0,
    this.onGround = false,
  });
}

class SaveData {
  final int currentLevel;
  final int highScore;
  final int totalDistance;

  SaveData({
    this.currentLevel = 1,
    this.highScore = 0,
    this.totalDistance = 0,
  });

  SaveData copyWith({int? currentLevel, int? highScore, int? totalDistance}) {
    return SaveData(
      currentLevel: currentLevel ?? this.currentLevel,
      highScore: highScore ?? this.highScore,
      totalDistance: totalDistance ?? this.totalDistance,
    );
  }
}