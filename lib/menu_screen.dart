import 'dart:math';
import 'package:LineGlideXx/save_service.dart';
import 'package:flutter/material.dart';

import 'game_constants.dart';
import 'game_models.dart';
import 'game_screen.dart';
import 'about_screen.dart';
import 'level_select_screen.dart';
import 'privacy_policy_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  SaveData _saveData = SaveData();
  bool _hasProgress = false;
  bool _loading = true;

  late AnimationController _bgController;
  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _entryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.7)));
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _loadData();
  }

  Future<void> _loadData() async {
    final data = await SaveService.load();
    final progress = await SaveService.hasProgress();
    if (mounted) {
      setState(() {
        _saveData = data;
        _hasProgress = progress;
        _loading = false;
      });
      _entryController.forward();
    }
  }

  Future<void> _refreshData() async {
    final data = await SaveService.load();
    final progress = await SaveService.hasProgress();
    if (mounted) setState(() { _saveData = data; _hasProgress = progress; });
  }

  void _newGame() async {
    await SaveService.resetProgress();
    if (!mounted) return;
    final data = await SaveService.load();
    _navigate(GameScreen(startLevel: 1, highScore: data.highScore));
  }

  void _continueGame() {
    _navigate(GameScreen(startLevel: _saveData.currentLevel, highScore: _saveData.highScore));
  }

  void _navigate(Widget screen) {
    Navigator.of(context)
        .push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ))
        .then((_) => _refreshData());
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          CustomPaint(size: size, painter: _MenuBgPainter(anim: _bgController)),

          if (_loading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
          else
            SafeArea(
              child: FadeTransition(
                opacity: _entryFade,
                child: SlideTransition(
                  position: _entrySlide,
                  child: _buildContent(size),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(Size size) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: size.height - 60),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildHero(),
            const SizedBox(height: 16),
            _buildHighScoreBar(),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  _MenuButton(
                    icon: Icons.fiber_new_rounded,
                    label: 'NEW GAME',
                    sublabel: 'Start from Level 1',
                    color: const Color(0xFF00E5FF),
                    onTap: _newGame,
                  ),
                  const SizedBox(height: 14),
                  if (_hasProgress)
                    _MenuButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'CONTINUE',
                      sublabel: 'Level ${_saveData.currentLevel} — resume progress',
                      color: const Color(0xFF3FB950),
                      onTap: _continueGame,
                    ),
                  if (_hasProgress) const SizedBox(height: 14),
                  _MenuButton(
                    icon: Icons.grid_view_rounded,
                    label: 'LEVELS',
                    sublabel: 'Choose a level to play',
                    color: const Color(0xFF58A6FF),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                      builder: (_) => LevelSelectScreen(
                        unlockedLevel: _saveData.currentLevel,
                        highScore: _saveData.highScore,
                      ),
                    ))
                        .then((_) => _refreshData()),
                  ),
                  const SizedBox(height: 14),
                  _MenuButton(
                    icon: Icons.info_outline_rounded,
                    label: 'ABOUT',
                    sublabel: 'Developer info & game details',
                    color: const Color(0xFFFF9800),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const AboutScreen())),
                  ),
                  const SizedBox(height: 14),
                  // Privacy Policy moved here from About screen
                  _MenuButton(
                    icon: Icons.privacy_tip_outlined,
                    label: 'PRIVACY POLICY',
                    sublabel: 'View our privacy policy',
                    color: const Color(0xFF3FB950),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1C2A3A), Color(0xFF0D1117)],
            ),
            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.45), width: 2),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.18), blurRadius: 24, spreadRadius: 2),
            ],
          ),
          child: CustomPaint(painter: _LogoMiniPainter()),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF58A6FF), Color(0xFF00E5FF)],
          ).createShader(bounds),
          child: const Text(
            'LineGlideX',
            style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Draw • Ride • Survive',
          style: TextStyle(
            color: const Color(0xFF8B949E).withOpacity(0.65),
            fontSize: 14,
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHighScoreBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFDD00).withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFFDD00).withOpacity(0.06), blurRadius: 16, spreadRadius: 1),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HIGH SCORE',
                      style: TextStyle(
                          color: Color(0xFFFFDD00),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5)),
                  Text(
                    '${_saveData.highScore}m',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('LEVEL',
                  style: TextStyle(
                      color: Color(0xFF8B949E),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              Text(
                '${_saveData.currentLevel} / ${GameConstants.maxLevel()}',
                style: const TextStyle(
                    color: Color(0xFF58A6FF), fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Menu Button ──────────────────────────────────────────────────────────────

class _MenuButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _pressScale = Tween<double>(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _pressCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) { _pressCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (_, child) => Transform.scale(scale: _pressScale.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(color: widget.color.withOpacity(0.1), blurRadius: 16, spreadRadius: 1),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.color.withOpacity(0.3)),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: TextStyle(
                            color: widget.color,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2)),
                    Text(widget.sublabel,
                        style: TextStyle(
                            color: widget.color.withOpacity(0.55),
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: widget.color.withOpacity(0.5), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Painters ────────────────────────────────────────────────────────────────

class _MenuBgPainter extends CustomPainter {
  final Animation<double> anim;
  _MenuBgPainter({required this.anim}) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFF161B22)..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    for (double y = 0; y < size.height; y += step) canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);

    final t = anim.value;
    for (int i = 0; i < 3; i++) {
      final phase = i * 0.33 + t;
      final y = size.height * (0.3 + i * 0.2 + sin(phase * 2 * pi) * 0.05);
      final path = Path();
      for (double x = 0; x <= size.width; x += 5) {
        final dy = sin((x / size.width + phase) * 2 * pi) * 18;
        if (x == 0) path.moveTo(x, y + dy);
        else path.lineTo(x, y + dy);
      }
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(0.04 + i * 0.015)
        ..strokeWidth = 1.5 + i * 0.5
        ..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MenuBgPainter old) => true;
}

class _LogoMiniPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final path = Path()
      ..moveTo(10, cy + 6)
      ..quadraticBezierTo(cx, cy - 16, size.width - 10, cy + 6);
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF58A6FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(cx + 3, cy - 8), 4, Paint()..color = const Color(0xFFF0D9B5));
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 4, cy - 3, 10, 6), const Radius.circular(2)),
        Paint()..color = const Color(0xFF238636));
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}