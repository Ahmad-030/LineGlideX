import 'package:flutter/material.dart';

import 'game_constants.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatelessWidget {
  final int unlockedLevel;
  final int highScore;

  const LevelSelectScreen({
    super.key,
    required this.unlockedLevel,
    required this.highScore,
  });

  @override
  Widget build(BuildContext context) {
    final levels = GameConstants.levels;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Color(0xFF8B949E), size: 20),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'SELECT LEVEL',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                ),
                itemCount: levels.length,
                itemBuilder: (ctx, i) {
                  final lvl = levels[i];
                  final lvlNum = lvl['level'] as int;
                  final locked = lvlNum > unlockedLevel;
                  final color = Color(lvl['color'] as int);

                  return _LevelCard(
                    levelData: lvl,
                    locked: locked,
                    isCurrentLevel: lvlNum == unlockedLevel,
                    color: color,
                    onTap: locked
                        ? null
                        : () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => GameScreen(
                            startLevel: lvlNum,
                            highScore: highScore,
                          ),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final Map<String, dynamic> levelData;
  final bool locked;
  final bool isCurrentLevel;
  final Color color;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.levelData,
    required this.locked,
    required this.isCurrentLevel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lvlNum = levelData['level'] as int;
    final name = levelData['name'] as String;
    final dist = levelData['distance'] as int;
    final effectiveColor = locked ? const Color(0xFF30363D) : color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: locked
              ? const Color(0xFF0D1117)
              : effectiveColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentLevel
                ? effectiveColor.withOpacity(0.8)
                : effectiveColor.withOpacity(locked ? 0.15 : 0.3),
            width: isCurrentLevel ? 2 : 1.5,
          ),
          boxShadow: locked
              ? []
              : [
            BoxShadow(
                color: effectiveColor.withOpacity(0.1),
                blurRadius: 14,
                spreadRadius: 1),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: effectiveColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'LVL $lvlNum',
                      style: TextStyle(
                          color: effectiveColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1),
                    ),
                  ),
                  if (locked)
                    const Icon(Icons.lock_rounded, color: Color(0xFF30363D), size: 18)
                  else if (isCurrentLevel)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow_rounded, color: color, size: 14),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                name,
                style: TextStyle(
                  color: locked ? const Color(0xFF30363D) : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                dist >= 999999 ? '∞ Endless' : '$dist m',
                style: TextStyle(
                  color: locked
                      ? const Color(0xFF21262D)
                      : effectiveColor.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}