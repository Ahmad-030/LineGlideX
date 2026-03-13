import 'package:shared_preferences/shared_preferences.dart';
import 'game_models.dart';

class SaveService {
  static const _keyLevel = 'current_level';
  static const _keyHighScore = 'high_score';
  static const _keyTotalDist = 'total_distance';
  static const _keyHasProgress = 'has_progress';

  static Future<SaveData> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SaveData(
      currentLevel: prefs.getInt(_keyLevel) ?? 1,
      highScore: prefs.getInt(_keyHighScore) ?? 0,
      totalDistance: prefs.getInt(_keyTotalDist) ?? 0,
    );
  }

  static Future<void> save(SaveData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLevel, data.currentLevel);
    await prefs.setInt(_keyHighScore, data.highScore);
    await prefs.setInt(_keyTotalDist, data.totalDistance);
    await prefs.setBool(_keyHasProgress, data.currentLevel > 1);
  }

  static Future<bool> hasProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasProgress) ?? false;
  }

  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLevel, 1);
    await prefs.setInt(_keyTotalDist, 0);
    await prefs.setBool(_keyHasProgress, false);
  }

  static Future<void> updateHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyHighScore) ?? 0;
    if (score > current) {
      await prefs.setInt(_keyHighScore, score);
    }
  }
}