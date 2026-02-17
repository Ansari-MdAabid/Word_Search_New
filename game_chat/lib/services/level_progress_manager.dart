// lib/services/level_progress_manager.dart

import 'package:get_storage/get_storage.dart';
import '../data/word_datasets.dart';

class LevelProgressManager {
  static final GetStorage _storage = GetStorage();
  
  // Keys for storage
  static const String _levelStarsKey = 'level_stars';
  static const String _levelUnlockedKey = 'level_unlocked';
  static const String _highScoreKey = 'level_high_score';
  static const String _levelStatsKey = 'level_stats';
  
  // Initialize storage
  static Future<void> init() async {
    await GetStorage.init();
    
    // Ensure level 1 is always unlocked
    if (!isLevelUnlocked(1)) {
      unlockLevel(1);
    }
  }
  
  // Save stars earned for a level
  static void saveLevelStars(int level, int stars) {
    Map<String, dynamic> levelStars = _storage.read(_levelStarsKey) ?? {};
    int currentStars = levelStars[level.toString()] ?? 0;
    
    // Only save if new stars are better than current
    if (stars > currentStars) {
      levelStars[level.toString()] = stars;
      _storage.write(_levelStarsKey, levelStars);
      
      // Unlock next level if this level is completed (1+ stars)
      if (stars > 0 && level < 50) {
        unlockLevel(level + 1);
      }
    }
  }
  
  // Save detailed level statistics
  static void saveLevelStats(int level, {
    required int score,
    required int totalWords,
    required int hintsUsed,
    required double timeElapsed,
    required int gridSize,
  }) {
    Map<String, dynamic> levelStats = _storage.read(_levelStatsKey) ?? {};
    Map<String, dynamic> currentLevelStats = levelStats[level.toString()] ?? {};
    
    // Save best performance stats
    int currentBestScore = currentLevelStats['bestScore'] ?? 0;
    double currentBestTime = currentLevelStats['bestTime'] ?? double.infinity;
    int currentFewestHints = currentLevelStats['fewestHints'] ?? 999;
    
    bool isNewBest = false;
    
    if (score > currentBestScore) {
      currentLevelStats['bestScore'] = score;
      isNewBest = true;
    }
    
    if (timeElapsed < currentBestTime) {
      currentLevelStats['bestTime'] = timeElapsed;
      isNewBest = true;
    }
    
    if (hintsUsed < currentFewestHints) {
      currentLevelStats['fewestHints'] = hintsUsed;
      isNewBest = true;
    }
    
    // Always save the current attempt
    currentLevelStats['lastScore'] = score;
    currentLevelStats['lastTime'] = timeElapsed;
    currentLevelStats['lastHints'] = hintsUsed;
    currentLevelStats['totalWords'] = totalWords;
    currentLevelStats['gridSize'] = gridSize;
    currentLevelStats['attempts'] = (currentLevelStats['attempts'] ?? 0) + 1;
    
    levelStats[level.toString()] = currentLevelStats;
    _storage.write(_levelStatsKey, levelStats);
  }
  
  // Get stars for a level
  static int getLevelStars(int level) {
    Map<String, dynamic> levelStars = _storage.read(_levelStarsKey) ?? {};
    return levelStars[level.toString()] ?? 0;
  }
  
  // Check if level is unlocked
  static bool isLevelUnlocked(int level) {
    if (level == 1) return true; // Level 1 is always unlocked
    
    Map<String, dynamic> unlockedLevels = _storage.read(_levelUnlockedKey) ?? {};
    return unlockedLevels[level.toString()] ?? false;
  }
  
  // Unlock a level
  static void unlockLevel(int level) {
    Map<String, dynamic> unlockedLevels = _storage.read(_levelUnlockedKey) ?? {};
    unlockedLevels[level.toString()] = true;
    _storage.write(_levelUnlockedKey, unlockedLevels);
  }
  
  // Save high score for a level
  static void saveLevelScore(int level, int score) {
    Map<String, dynamic> highScores = _storage.read(_highScoreKey) ?? {};
    int currentScore = highScores[level.toString()] ?? 0;
    
    if (score > currentScore) {
      highScores[level.toString()] = score;
      _storage.write(_highScoreKey, highScores);
    }
  }
  
  // Get high score for a level
  static int getLevelHighScore(int level) {
    Map<String, dynamic> highScores = _storage.read(_highScoreKey) ?? {};
    return highScores[level.toString()] ?? 0;
  }
  
  // Get level difficulty tier
  static int _getLevelTier(int level) {
    if (level <= 10) return 1; // Easy (6x6 grid)
    if (level <= 20) return 2; // Medium (8x8 grid)
    if (level <= 30) return 3; // Hard (10x10 grid)
    if (level <= 40) return 4; // Expert (12x12 grid)
    return 5; // Master (12x12 grid, complex words)
  }
  
  // Get level characteristics for adaptive scoring
  static Map<String, dynamic> _getLevelCharacteristics(int level) {
    int tier = _getLevelTier(level);
    List<String> levelWords = WordDatasets.getLevelWords(level);
    
    // Calculate average word length for this level
    double avgWordLength = levelWords.isNotEmpty 
        ? levelWords.map((w) => w.length).reduce((a, b) => a + b) / levelWords.length
        : 5.0;
    
    // Determine grid size based on tier
    int gridSize;
    switch (tier) {
      case 1: gridSize = 6; break;
      case 2: gridSize = 8; break;
      case 3: gridSize = 10; break;
      case 4: 
      case 5: gridSize = 12; break;
      default: gridSize = 6;
    }
    
    return {
      'tier': tier,
      'expectedWords': levelWords.length,
      'avgWordLength': avgWordLength,
      'gridSize': gridSize,
      'complexity': _calculateLevelComplexity(levelWords, gridSize),
    };
  }
  
  // Calculate level complexity score (0-100)
  static double _calculateLevelComplexity(List<String> words, int gridSize) {
    if (words.isEmpty) return 50.0;
    
    double complexity = 0;
    
    // Factor 1: Average word length (longer words = higher complexity)
    double avgLength = words.map((w) => w.length).reduce((a, b) => a + b) / words.length;
    complexity += (avgLength - 3) * 10; // 3-letter baseline
    
    // Factor 2: Grid size (larger grids = slightly higher complexity)
    complexity += (gridSize - 6) * 2;
    
    // Factor 3: Number of words (more words = higher complexity)
    complexity += words.length * 2;
    
    // Factor 4: Word variety (more unique starting letters = higher complexity)
    Set<String> startingLetters = words.map((w) => w[0]).toSet();
    complexity += startingLetters.length * 1.5;
    
    return complexity.clamp(10.0, 90.0);
  }
  
  // Improved star calculation with adaptive thresholds
  static int calculateStars({
    required int score,
    required int totalWords,
    required int hintsUsed,
    required double timeElapsed,
    required int level,
  }) {
    if (totalWords == 0) return 1; // Safety check
    
    Map<String, dynamic> characteristics = _getLevelCharacteristics(level);
    double complexity = characteristics['complexity'];
    int tier = characteristics['tier'];
    int expectedWords = characteristics['expectedWords'];
    
    // Adaptive scoring based on level characteristics
    double baseScorePerWord = _getBaseScoreForTier(tier);
    double timeMultiplier = _getTimeMultiplierForTier(tier);
    int maxHintsForTwoStars = _getMaxHintsForTier(tier);
    
    // Calculate metrics
    double avgScorePerWord = score / totalWords;
    double expectedTime = _calculateExpectedTime(level, totalWords, complexity);
    double timeRatio = timeElapsed / expectedTime; // < 1.0 is good, > 1.0 is slow
    
    // Star 1: Complete the level (always awarded for completion)
    int stars = 1;
    
    // Star 2: Good performance
    bool scoreThresholdMet = avgScorePerWord >= baseScorePerWord;
    bool hintsThresholdMet = hintsUsed <= maxHintsForTwoStars;
    bool timeReasonable = timeRatio <= 2.0; // Not too slow
    
    if (scoreThresholdMet && hintsThresholdMet && timeReasonable) {
      stars = 2;
    }
    
    // Star 3: Excellent performance
    // double excellentScoreMultiplier = 1.4; // 40% above base
    // bool excellentScore = avgScorePerWord >= (baseScorePerWord * excellentScoreMultiplier);
    bool noHints = hintsUsed == 0;
    bool fastCompletion = timeRatio <= 1.2; // Within 120% of expected time
    
    if (stars == 2 && noHints && fastCompletion) {
      stars = 3;
    }
    
    return stars;
  }
  
  // Get base score per word requirement for each tier
  static double _getBaseScoreForTier(int tier) {
    switch (tier) {
      case 1: return 35.0; // Easy levels - lower requirement
      case 2: return 45.0; // Medium levels
      case 3: return 55.0; // Hard levels
      case 4: return 65.0; // Expert levels
      case 5: return 70.0; // Master levels
      default: return 50.0;
    }
  }
  
  // Get time multiplier for expected completion time
  static double _getTimeMultiplierForTier(int tier) {
    switch (tier) {
      case 1: return 1.0;   // 1x base time
      case 2: return 1.3;   // 1.3x base time
      case 3: return 1.6;   // 1.6x base time
      case 4: return 2.0;   // 2x base time
      case 5: return 2.5;   // 2.5x base time
      default: return 1.5;
    }
  }
  
  // Get maximum hints allowed for 2 stars based on tier
  static int _getMaxHintsForTier(int tier) {
    switch (tier) {
      case 1: return 2; // Easy levels allow more hints
      case 2: return 2;
      case 3: return 1; // Hard levels allow fewer hints
      case 4: return 1;
      case 5: return 0; // Master levels require no hints for 2+ stars
      default: return 1;
    }
  }
  
  // Calculate expected completion time in minutes
  static double _calculateExpectedTime(int level, int totalWords, double complexity) {
    // Base time per word (varies by complexity)
    double baseTimePerWord = 0.3 + (complexity / 200); // 0.3-0.75 minutes per word
    
    // Level tier adjustment
    int tier = _getLevelTier(level);
    double tierMultiplier = _getTimeMultiplierForTier(tier);
    
    // Grid size factor (larger grids take longer to scan)
    int gridSize = tier <= 2 ? 6 + (tier - 1) * 2 : 8 + (tier - 2) * 2;
    double gridFactor = 1.0 + ((gridSize - 6) * 0.1); // +10% per size increase
    
    double expectedTime = totalWords * baseTimePerWord * tierMultiplier * gridFactor;
    
    // Minimum and maximum bounds
    return expectedTime.clamp(1.0, 15.0);
  }
  
  // Get performance analysis for a level
  static Map<String, dynamic> getLevelPerformanceAnalysis(int level) {
    Map<String, dynamic> levelStats = _storage.read(_levelStatsKey) ?? {};
    Map<String, dynamic> stats = levelStats[level.toString()] ?? {};
    
    if (stats.isEmpty) {
      return {
        'hasData': false,
        'message': 'No performance data available',
      };
    }
    
    Map<String, dynamic> characteristics = _getLevelCharacteristics(level);
    int bestScore = stats['bestScore'] ?? 0;
    double bestTime = stats['bestTime'] ?? 0.0;
    int fewestHints = stats['fewestHints'] ?? 0;
    int totalWords = stats['totalWords'] ?? 1;
    
    double avgScorePerWord = totalWords > 0 ? bestScore / totalWords : 0;
    double expectedTime = _calculateExpectedTime(level, totalWords, characteristics['complexity']);
    double timeRatio = bestTime > 0 ? bestTime / expectedTime : 1.0;
    
    String timePerformance = timeRatio <= 0.8 ? 'Excellent' : 
                           timeRatio <= 1.2 ? 'Good' : 
                           timeRatio <= 2.0 ? 'Average' : 'Needs Improvement';
    
    String scorePerformance = avgScorePerWord >= _getBaseScoreForTier(characteristics['tier']) * 1.4 ? 'Excellent' :
                             avgScorePerWord >= _getBaseScoreForTier(characteristics['tier']) ? 'Good' :
                             'Needs Improvement';
    
    return {
      'hasData': true,
      'bestScore': bestScore,
      'bestTime': bestTime,
      'fewestHints': fewestHints,
      'avgScorePerWord': avgScorePerWord.round(),
      'expectedTime': expectedTime,
      'timePerformance': timePerformance,
      'scorePerformance': scorePerformance,
      'attempts': stats['attempts'] ?? 0,
      'tier': characteristics['tier'],
      'complexity': characteristics['complexity'].round(),
    };
  }
  
  // Get total stars earned across all levels
  static int getTotalStars() {
    Map<String, dynamic> levelStars = _storage.read(_levelStarsKey) ?? {};
    int totalStars = 0;
    
    for (String levelStr in levelStars.keys) {
      totalStars += (levelStars[levelStr] as int? ?? 0);
    }
    
    return totalStars;
  }
  
  // Get number of completed levels
  static int getCompletedLevels() {
    Map<String, dynamic> levelStars = _storage.read(_levelStarsKey) ?? {};
    int completed = 0;
    
    for (String levelStr in levelStars.keys) {
      if ((levelStars[levelStr] as int? ?? 0) > 0) {
        completed++;
      }
    }
    
    return completed;
  }
  
  // Get player's overall performance tier
  static String getPlayerTier() {
    int totalStars = getTotalStars();
    int completedLevels = getCompletedLevels();
    
    if (completedLevels == 0) return 'Beginner';
    
    double avgStars = totalStars / completedLevels;
    
    if (avgStars >= 2.8) return 'Master';
    if (avgStars >= 2.3) return 'Expert';
    if (avgStars >= 1.8) return 'Advanced';
    if (avgStars >= 1.3) return 'Intermediate';
    return 'Beginner';
  }
  
  // Reset all progress (for testing or reset functionality)
  static void resetAllProgress() {
    _storage.remove(_levelStarsKey);
    _storage.remove(_levelUnlockedKey);
    _storage.remove(_highScoreKey);
    _storage.remove(_levelStatsKey);
    
    // Unlock level 1 again
    unlockLevel(1);
  }
  
  // Check if next level exists and is available
  static bool hasNextLevel(int currentLevel) {
    return currentLevel < 50; // Assuming 50 levels total
  }
  
  // Get the next level number
  static int getNextLevel(int currentLevel) {
    if (hasNextLevel(currentLevel)) {
      return currentLevel + 1;
    }
    return currentLevel;
  }
}