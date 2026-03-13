import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lineglidex/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const LineGlideApp());
}

class LineGlideApp extends StatelessWidget {
  const LineGlideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LineGlide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF3FB950),
          surface: Color(0xFF0D1117),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
      ),
      home: const SplashScreen(),
    );
  }
}