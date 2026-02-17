// lib/services/daily_puzzle_manager.dart
import 'package:shared_preferences/shared_preferences.dart';

class DailyPuzzleManager {
  static const String _lastPlayedDateKey = 'daily_puzzle_last_played';
  static const String _completedDifficultiesKey = 'daily_puzzle_completed_difficulties';
  
  // Mark specific difficulty as completed
  static Future<void> markDifficultyAsCompleted(String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    
    // Get currently completed difficulties for today
    List<String> completedDifficulties = await getCompletedDifficulties();
    
    // Add the new difficulty if not already completed
    if (!completedDifficulties.contains(difficulty)) {
      completedDifficulties.add(difficulty);
    }
    
    // Save updated list
    await prefs.setStringList('${_completedDifficultiesKey}_$today', completedDifficulties);
    await prefs.setString(_lastPlayedDateKey, today);
  }
  
  // Get list of completed difficulties for today
  static Future<List<String>> getCompletedDifficulties() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    return prefs.getStringList('${_completedDifficultiesKey}_$today') ?? [];
  }
  
  // Check if specific difficulty is completed
  static Future<bool> isDifficultyCompleted(String difficulty) async {
    final completedDifficulties = await getCompletedDifficulties();
    return completedDifficulties.contains(difficulty);
  }
  
  // Check if ALL difficulties are completed (original isCompletedToday logic)
  static Future<bool> isCompletedToday() async {
    final completedDifficulties = await getCompletedDifficulties();
    const allDifficulties = ['easy', 'normal', 'hard'];
    
    // Check if all three difficulties are completed
    return allDifficulties.every((difficulty) => completedDifficulties.contains(difficulty));
  }
  
  // Check if user can play today (at least one difficulty not completed)
  static Future<bool> canPlayToday() async {
    final isAllCompleted = await isCompletedToday();
    return !isAllCompleted;
  }
  
  // Get remaining difficulties that can be played
  static Future<List<String>> getRemainingDifficulties() async {
    const allDifficulties = ['easy', 'normal', 'hard'];
    final completedDifficulties = await getCompletedDifficulties();
    
    return allDifficulties.where((difficulty) => 
      !completedDifficulties.contains(difficulty)
    ).toList();
  }
  
  // Get count of completed difficulties
  static Future<int> getCompletedCount() async {
    final completedDifficulties = await getCompletedDifficulties();
    return completedDifficulties.length;
  }
  
  // Get status message for UI
  static Future<String> getStatusMessage() async {
    final completedCount = await getCompletedCount();
    const totalCount = 3;
    
    if (completedCount == 0) {
      return 'Ready to play! Choose your difficulty.';
    } else if (completedCount < totalCount) {
      return 'Progress: $completedCount/$totalCount difficulties completed';
    } else {
      return 'All difficulties completed! Come back tomorrow.';
    }
  }
  
  // Get time until next puzzle (unchanged)
  static Future<Duration?> getTimeUntilNextPuzzle() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }
  
  // Helper method to get today's date key
  static String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  
  // Clean up old data (call this periodically)
  static Future<void> cleanupOldData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final today = _getTodayKey();
    
    // Remove data older than 7 days
    final keysToRemove = keys.where((key) {
      if (key.startsWith(_completedDifficultiesKey)) {
        final dateKey = key.split('_').last;
        return dateKey != today; // Remove if not today
      }
      return false;
    }).toList();
    
    for (String key in keysToRemove) {
      await prefs.remove(key);
    }
  }
}