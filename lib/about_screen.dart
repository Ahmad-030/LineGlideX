import 'package:flutter/material.dart';
import 'game_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Color(0xFF8B949E), size: 20),
                  ),
                  const Text('ABOUT',
                      style: TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Game logo card
                    _glowCard(
                      const Color(0xFF00E5FF),
                      Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF58A6FF)],
                            ).createShader(bounds),
                            child: const Text('LineGlideX',
                                style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1)),
                          ),

                          const SizedBox(height: 12),
                          Text(
                            'Draw tracks, dodge obstacles and\nride to glory across 6 unique levels!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: const Color(0xFF8B949E).withOpacity(0.8),
                                fontSize: 14,
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Developer card
                    _glowCard(
                      const Color(0xFFFF9800),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFFF9800).withOpacity(0.4)),
                                ),
                                child: const Icon(Icons.code_rounded,
                                    color: Color(0xFFFF9800), size: 22),
                              ),
                              const SizedBox(width: 14),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('DEVELOPER',
                                      style: TextStyle(
                                          color: Color(0xFFFF9800),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5)),
                                  Text('Hamad Gaming Studio',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _infoRow(Icons.email_rounded, 'farhanabid961@gmail.com',
                              const Color(0xFFFF9800)),


                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Level list card
                    _glowCard(
                      const Color(0xFF58A6FF),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LEVELS',
                              style: TextStyle(
                                  color: Color(0xFF58A6FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          ...GameConstants.levels.map((lvl) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Color(lvl['color'] as int).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Color(lvl['color'] as int).withOpacity(0.4)),
                                  ),
                                  child: Center(
                                    child: Text('${lvl['level']}',
                                        style: TextStyle(
                                            color: Color(lvl['color'] as int),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(lvl['name'] as String,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700)),
                                      Text(lvl['description'] as String,
                                          style: TextStyle(
                                              color: const Color(0xFF8B949E).withOpacity(0.6),
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Text(
                                  (lvl['distance'] as int) >= 999999
                                      ? '∞'
                                      : '${lvl['distance']}m',
                                  style: TextStyle(
                                      color: Color(lvl['color'] as int).withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      '© 2025 Hamad Gaming Studio\nAll rights reserved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: const Color(0xFF8B949E).withOpacity(0.35),
                          fontSize: 11,
                          height: 1.6),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color.withOpacity(0.7), size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: const Color(0xFF8B949E).withOpacity(0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _glowCard(Color color, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.07), blurRadius: 18, spreadRadius: 1),
        ],
      ),
      child: child,
    );
  }
}