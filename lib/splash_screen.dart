import 'dart:math';
import 'package:flutter/material.dart';
import 'menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _lineController;
  late AnimationController _fadeController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _lineProgress;
  late Animation<double> _riderY;
  late Animation<double> _textOpacity;
  late Animation<double> _subOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _lineController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.4)));
    _lineProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _lineController, curve: Curves.easeInOut));
    _riderY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 0.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 20),
    ]).animate(_lineController);
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _lineController, curve: const Interval(0.5, 1.0)));
    _subOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _lineController, curve: const Interval(0.75, 1.0)));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await _lineController.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MenuScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _lineController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // Animated grid
          CustomPaint(size: size, painter: _SplashGridPainter()),

          // Glow blob — changed to a warm purple/violet so it contrasts with
          // the cyan text and doesn't visually merge with it.
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (_, __) => Opacity(
                opacity: _logoOpacity.value * 0.30,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF7C3AED), // violet glow — distinct from cyan text
                        blurRadius: 140,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo icon
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (_, __) => Transform.scale(
                    scale: _logoScale.value,
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: _buildLogoIcon(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Animated line + rider
                AnimatedBuilder(
                  animation: _lineController,
                  builder: (_, __) => SizedBox(
                    width: 220,
                    height: 60,
                    child: CustomPaint(
                      painter: _LinePainter(
                        progress: _lineProgress.value,
                        riderOffsetY: _riderY.value,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                AnimatedBuilder(
                  animation: _lineController,
                  builder: (_, __) => Opacity(
                    opacity: _textOpacity.value,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF58A6FF)],
                      ).createShader(bounds),
                      child: const Text(
                        'LineGlideX',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                ),


              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoIcon() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2535), Color(0xFF0D1117)],
        ),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(painter: _LogoIconPainter()),
    );
  }
}

class _LogoIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final path = Path()
      ..moveTo(12, cy + 8)
      ..quadraticBezierTo(cx, cy - 20, size.width - 12, cy + 8);

    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF58A6FF)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    final rp = Offset(cx + 4, cy - 10);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(rp.dx - 8, rp.dy + 2, 16, 4), const Radius.circular(2)),
        Paint()..color = const Color(0xFF8B949E));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(rp.dx - 4, rp.dy - 8, 8, 12), const Radius.circular(3)),
        Paint()..color = const Color(0xFF238636));
    canvas.drawCircle(rp - const Offset(0, 14), 5, Paint()..color = const Color(0xFFF0D9B5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _LinePainter extends CustomPainter {
  final double progress;
  final double riderOffsetY;
  const _LinePainter({required this.progress, required this.riderOffsetY});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final totalW = size.width;
    const lineY = 40.0;

    final path = Path()
      ..moveTo(0, lineY)
      ..lineTo(totalW * progress, lineY);

    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF00E5FF).withOpacity(0.9)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF00E5FF).withOpacity(0.2)
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    final rx = totalW * progress;
    final ry = lineY + riderOffsetY;

    canvas.save();
    canvas.translate(rx, ry);

    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-8, 2, 16, 3), const Radius.circular(2)),
        Paint()..color = const Color(0xFF8B949E));
    for (final ox in [-5.0, 5.0]) {
      canvas.drawCircle(Offset(ox, 6), 3, Paint()..color = const Color(0xFF30363D));
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -6, 8, 10), const Radius.circular(3)),
        Paint()..color = const Color(0xFF238636));
    canvas.drawCircle(const Offset(0, -11), 5, Paint()..color = const Color(0xFFF0D9B5));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.progress != progress || old.riderOffsetY != riderOffsetY;
}

class _SplashGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF161B22)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}