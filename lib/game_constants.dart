import 'package:flutter/material.dart';

class GameConstants {
  // Physics
  static const double gravity = 600;
  static const double friction = 0.9992;
  static const double riderSize = 14.0;
  static const double startVelocity = 170.0;

  // Camera
  static const double riderScreenXFraction = 0.28;

  // Obstacles
  static const double obstacleBaseSpacing = 480;

  // Colors
  static const Color bgColor = Color(0xFF0D1117);
  static const Color gridColor = Color(0xFF161B22);
  static const Color trackColor = Color(0xFF58A6FF);
  static const Color trackGlow = Color(0xFF00E5FF);
  static const Color riderGreen = Color(0xFF238636);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentRed = Color(0xFFFF4444);
  static const Color accentGreen = Color(0xFF3FB950);

  // Levels: {name, distanceToComplete (meters), obstacleMultiplier, description}
  static const List<Map<String, dynamic>> levels = [
    {
      'level': 1,
      'name': 'Smooth Start',
      'distance': 300,
      'obstacleMultiplier': 0.0,
      'description': 'No obstacles. Just ride!',
      'color': 0xFF3FB950,
    },
    {
      'level': 2,
      'name': 'First Spikes',
      'distance': 500,
      'obstacleMultiplier': 0.5,
      'description': 'Watch out for spikes ahead.',
      'color': 0xFF58A6FF,
    },
    {
      'level': 3,
      'name': 'Box Canyon',
      'distance': 800,
      'obstacleMultiplier': 0.8,
      'description': 'Boxes and spikes mixed.',
      'color': 0xFF00E5FF,
    },
    {
      'level': 4,
      'name': 'Danger Zone',
      'distance': 1200,
      'obstacleMultiplier': 1.2,
      'description': 'Dense obstacles. Stay sharp!',
      'color': 0xFFFF9800,
    },
    {
      'level': 5,
      'name': 'Chaos Run',
      'distance': 1800,
      'obstacleMultiplier': 1.6,
      'description': 'Maximum chaos. Good luck.',
      'color': 0xFFFF4444,
    },
    {
      'level': 6,
      'name': 'Endless Glory',
      'distance': 999999,
      'obstacleMultiplier': 2.0,
      'description': 'Survive as long as you can.',
      'color': 0xFFFFDD00,
    },
  ];

  static Map<String, dynamic> getLevel(int level) {
    final idx = (level - 1).clamp(0, levels.length - 1);
    return levels[idx];
  }

  static int maxLevel() => levels.length;
}