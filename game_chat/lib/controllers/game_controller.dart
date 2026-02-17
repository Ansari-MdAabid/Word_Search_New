// lib/controllers/game_controller.dart - Updated version with word overlapping support

import 'package:get/get.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/word_datasets.dart';
import '../widgets/word_celebration.dart';
import '../widgets/winning_screen.dart';
import '../screens/home_screen.dart';
import '../services/level_progress_manager.dart';
import '../services/sound_manager.dart';
import '../services/daily_puzzle_manager.dart';

class Position {
  final int row;
  final int col;

  Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && runtimeType == other.runtimeType && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Position($row, $col)';
}

class WordModel {
  final String word;
  final List<Position> positions;
  final Color color;
  bool found;

  WordModel({
    required this.word,
    required this.positions,
    required this.color,
    this.found = false,
  });
}

class HintState {
  final WordModel word;
  final int revealedLetters;

  HintState({required this.word, this.revealedLetters = 0});
}

class GameController extends GetxController with WidgetsBindingObserver {
  // Game configuration
  final String gameMode;
  int? level;
  final String? category;
  final String? difficulty;
  final int? customGridSize;

  // Celebration words
  static const List<String> _celebrationWords = [
    'WOW!', 'EXCELLENT!', 'GREAT!', 'AMAZING!', 'FANTASTIC!', 
    'BRILLIANT!', 'AWESOME!', 'SUPERB!', 'PERFECT!', 'INCREDIBLE!'
  ];

  // Game state
  bool _isGameComplete = false;
  bool _isShowingCelebration = false;
  bool _isShowingWinningScreen = false;
  bool _isDisposed = false;
  int? _selectionRowDirection;
  int? _selectionColDirection;

  // App lifecycle
  bool _isAppPaused = false;
  bool _isAppInBackground = false;
  DateTime? _pauseStartTime;
  Duration _pausedDuration = Duration.zero;

  GameController({
    required this.gameMode,
    this.level,
    this.category,
    this.difficulty,
    this.customGridSize,
  });

  // Observable variables
  final RxString levelTitle = 'Level 1 - Nature'.obs;
  final RxInt score = 0.obs;
  final RxInt gridSize = 6.obs;
  final RxInt roundsCompleted = 0.obs;
  final RxInt wordsFoundCount = 0.obs;
  final RxInt totalWordsCount = 0.obs;
  final RxInt hintsUsed = 0.obs;
  final RxDouble timeElapsed = 0.0.obs;
  
  // Winning screen observables for Stack-based rendering
  final RxBool showingWinningScreen = false.obs;
  final RxMap winningData = {}.obs;
  
  DateTime? gameStartTime;
  
  final RxList<RxList<String>> _grid = <RxList<String>>[].obs;
  List<List<String>> get grid => _grid.map((row) => row.toList()).toList();
  
  final RxList<WordModel> words = <WordModel>[].obs;
  final RxList<Position> selectedTiles = <Position>[].obs;
  final RxSet<Position> foundWordPositions = <Position>{}.obs;
  final RxBool isSelecting = false.obs;
  final Rx<Position?> lastSelectedPosition = Rx<Position?>(null);
  final RxBool showInvalidSelection = false.obs;

  final RxList<Position> hintHighlightPositions = <Position>[].obs;
  final RxBool showHintHighlight = false.obs;
  final Rx<HintState?> currentHintState = Rx<HintState?>(null);

  final List<Color> _wordColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
  ];

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    
    _setupGameConfiguration();
    initializeGame();
    
    _initializeSoundManager();
  }

  Future<void> _initializeSoundManager() async {
    try {
      print('GameController: Initializing SoundManager for sound effects...');
      await SoundManager().init();
      print('GameController: SoundManager initialized - music should already be playing');
    } catch (e) {
      print('GameController: Error initializing SoundManager: $e');
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (_isAppInBackground) {
            _pauseGame();
          }
        });
        _isAppInBackground = true;
        break;
        
      case AppLifecycleState.inactive:
        _isAppInBackground = true;
        break;
        
      case AppLifecycleState.resumed:
        _isAppInBackground = false;
        if (_isAppPaused) {
          _resumeGame();
        }
        break;
        
      case AppLifecycleState.detached:
        _pauseGame();
        break;
    }
  }

  void _pauseGame() {
    if (_isAppPaused) return;
    
    print('GameController: Pausing game timing');
    _isAppPaused = true;
    _pauseStartTime = DateTime.now();
  }

  void _resumeGame() {
    if (!_isAppPaused) return;
    
    print('GameController: Resuming game timing');
    if (_pauseStartTime != null) {
      _pausedDuration += DateTime.now().difference(_pauseStartTime!);
      _pauseStartTime = null;
    }
    
    _isAppPaused = false;
  }

  void _setupGameConfiguration() {
    switch (gameMode) {
      case 'level':
        if (level != null) {
          levelTitle.value = WordDatasets.getLevelTitle(level!);
          gridSize.value = _getLevelGridSize(level!);
        }
        break;
      case 'infinite':
        levelTitle.value = 'Infinite Mode - Round ${roundsCompleted.value + 1}';
        gridSize.value = customGridSize ?? 8;
        break;
      case 'daily':
        levelTitle.value = 'Daily Puzzle';
        if (difficulty != null) {
          gridSize.value = _getDifficultyGridSize(difficulty!);
        }
        break;
      case 'theme':
        if (category != null) {
          String categoryName = category!.toLowerCase();
          categoryName = categoryName[0].toUpperCase() + categoryName.substring(1);
          levelTitle.value = '$categoryName Theme';
          gridSize.value = customGridSize ?? 8;
        }
        break;
    }
  }

  int _getLevelGridSize(int level) {
    if (level <= 10) return 6;
    if (level <= 20) return 8;
    if (level <= 30) return 10;
    return 12;
  }

  int _getDifficultyGridSize(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return 6;
      case 'normal': return 8;
      case 'hard': return 10;
      default: return 8;
    }
  }

  void initializeGame() {
    _isGameComplete = false;
    _isShowingCelebration = false;
    _isShowingWinningScreen = false;
    
    gameStartTime = DateTime.now().subtract(_pausedDuration);
    
    selectedTiles.clear();
    foundWordPositions.clear();
    isSelecting.value = false;
    lastSelectedPosition.value = null;
    showInvalidSelection.value = false;
    wordsFoundCount.value = 0;
    hintsUsed.value = 0;
    timeElapsed.value = 0.0;
    
    _selectionRowDirection = null;
    _selectionColDirection = null;
    
    _clearHintHighlight();
    _initializeGrid();
    _setupWords();
    
    int maxRetries = 15; // Increased retries for overlapping placement
    int retryCount = 0;
    bool allWordsPlaced = false;
    
    while (!allWordsPlaced && retryCount < maxRetries) {
      _initializeGrid();
      allWordsPlaced = _placeWordsWithOverlapping();
      if (!allWordsPlaced) {
        retryCount++;
        if (retryCount < maxRetries) {
          words.shuffle();
          // Be less aggressive about removing words to allow for more overlapping attempts
          if (retryCount > 10) {
            int targetWordCount = (words.length * 0.9).ceil();
            if (words.length > targetWordCount) {
              words.removeRange(targetWordCount, words.length);
            }
          }
        }
      }
    }
    
    if (!allWordsPlaced) {
      words.removeWhere((word) => word.positions.isEmpty);
      if (words.isEmpty) {
        _createFallbackWords();
      }
    }
    
    totalWordsCount.value = words.where((word) => word.positions.isNotEmpty).length;
    _fillEmptyCells();
    
    if (gameMode == 'infinite') {
      levelTitle.value = 'Infinite Mode - Round ${roundsCompleted.value + 1}';
    }

    print('Game initialized with ${totalWordsCount.value} words placed');
  }

  void _createFallbackWords() {
    words.clear();
    List<String> fallbackWords = ['CAT', 'DOG', 'SUN', 'SKY', 'RUN', 'FUN'];
    
    for (int i = 0; i < fallbackWords.length && i < 4; i++) {
      words.add(WordModel(
        word: fallbackWords[i],
        positions: [],
        color: _wordColors[i % _wordColors.length],
      ));
    }
    
    _placeWordsWithOverlapping();
  }

  // NEW METHOD: Enhanced word placement with overlapping support
  bool _placeWordsWithOverlapping() {
    Random random = Random();
    int placedWords = 0;
    
    // Clear all positions first
    for (int i = 0; i < words.length; i++) {
      words[i].positions.clear();
    }
    
    // Sort words by length (longer words first for better placement)
    List<int> wordIndices = List.generate(words.length, (index) => index);
    wordIndices.sort((a, b) => words[b].word.length.compareTo(words[a].word.length));
    
    // TRACKER for directions to ensure variety
    Map<int, int> directionCounts = {for (var i = 0 ; i < 8; i++) i : 0};
    
    for (int wordIndex in wordIndices) {
      WordModel wordModel = words[wordIndex];
      bool placed = false;
      List<Map<String, dynamic>> possiblePlacements = [];
      
      // Find all possible placements for this word
      for (int row = 0; row < gridSize.value; row++) {
        for (int col = 0; col < gridSize.value; col++) {
          for (int direction = 0; direction < 8; direction++) {
            List<Position> positions = _getWordPositions(
              wordModel.word, row, col, direction
            );
            
            if (positions.isNotEmpty && _canPlaceWordWithOverlap(wordModel.word, positions)) {
              // Calculate overlap score (higher is better for more interesting puzzles)
              int overlapScore = _calculateOverlapScore(wordModel.word, positions);
              
              possiblePlacements.add({
                'positions': positions,
                'row': row,
                'col': col,
                'direction': direction,
                'overlapScore': overlapScore,
              });
            }
          }
        }
      }
      
      if (possiblePlacements.isNotEmpty) {
        // ENHANCED CHOICE: Use weighted sorting to avoid vertical clustering
        // Direction 2: Vertical (Top-Bottom), Direction 3: Vertical (Bottom-Top)
        int verticalCount = directionCounts[2]! + directionCounts[3]!;
        bool verticalBiasDetected = verticalCount > (placedWords / 3).ceil().clamp(2, words.length);

        possiblePlacements.sort((a, b) {
          int scoreA = a['overlapScore'];
          int scoreB = b['overlapScore'];
          
          if (verticalBiasDetected) {
            bool isVerticalA = a['direction'] == 2 || a['direction'] == 3;
            bool isVerticalB = b['direction'] == 2 || b['direction'] == 3;
            
            if (isVerticalA && !isVerticalB) scoreA -= 2;
            if (!isVerticalA && isVerticalB) scoreB -= 2;
          }
          
          return scoreB.compareTo(scoreA);
        });
        
        // Choose from top choices to balance randomness with variety
        int choiceRange = (possiblePlacements.length * 0.2).ceil().clamp(1, possiblePlacements.length);
        var chosenPlacement = possiblePlacements[random.nextInt(choiceRange)];
        List<Position> positions = chosenPlacement['positions'];
        int chosenDir = chosenPlacement['direction'];
        directionCounts[chosenDir] = directionCounts[chosenDir]! + 1;
        
        _placeWordWithOverlap(wordModel.word, positions);
        
        words[wordIndex] = WordModel(
          word: wordModel.word,
          positions: positions,
          color: wordModel.color,
          found: false,
        );
        placed = true;
        placedWords++;
        
        print('Placed word "${wordModel.word}" with overlap score: ${chosenPlacement['overlapScore']}');
      }
    }
    
    print('Successfully placed $placedWords out of ${words.length} words');
    return placedWords >= (words.length * 0.7).ceil() && placedWords >= 3;
  }

  // NEW METHOD: Check if word can be placed with overlap support
  bool _canPlaceWordWithOverlap(String word, List<Position> positions) {
    for (int i = 0; i < positions.length; i++) {
      Position pos = positions[i];
      String currentLetter = _grid[pos.row][pos.col];
      String wordLetter = word[i];
      
      // If cell is empty, it's ok to place
      if (currentLetter == '') {
        continue;
      }
      
      // If cell has a letter, it must match the word letter for valid overlap
      if (currentLetter != wordLetter) {
        return false;
      }
    }
    return true;
  }

  // NEW METHOD: Calculate overlap score for placement preference
  int _calculateOverlapScore(String word, List<Position> positions) {
    int overlapCount = 0;
    int emptyCount = 0;
    
    for (int i = 0; i < positions.length; i++) {
      Position pos = positions[i];
      String currentLetter = _grid[pos.row][pos.col];
      String wordLetter = word[i];
      
      if (currentLetter == '') {
        emptyCount++;
      } else if (currentLetter == wordLetter) {
        overlapCount++;
      }
    }
    
    // Score calculation:
    // - Prefer some overlap but not too much
    // - Penalize no overlap for longer words
    // - Reward strategic overlapping
    int baseScore = emptyCount * 2; // Base score for new letters
    int overlapBonus = 0;
    
    if (overlapCount > 0) {
      // Bonus for having overlap, but diminishing returns
      overlapBonus = overlapCount * 5 - (overlapCount > 2 ? (overlapCount - 2) * 2 : 0);
    } else if (word.length > 4) {
      // Small penalty for longer words with no overlap
      overlapBonus = -1;
    }
    
    return baseScore + overlapBonus;
  }

  // NEW METHOD: Place word with overlap support
  void _placeWordWithOverlap(String word, List<Position> positions) {
    for (int i = 0; i < word.length; i++) {
      Position pos = positions[i];
      String wordLetter = word[i];
      
      // Only place the letter if the cell is empty
      // If it already has the same letter (overlap), leave it as is
      if (_grid[pos.row][pos.col] == '') {
        _grid[pos.row][pos.col] = wordLetter;
      }
    }
  }

  void startSelection(int row, int col) {
    SoundManager().playTileSelect();
    
    selectedTiles.clear();
    isSelecting.value = true;
    Position position = Position(row, col);
    selectedTiles.add(position);
    lastSelectedPosition.value = position;
    showInvalidSelection.value = false;
    
    _selectionRowDirection = null;
    _selectionColDirection = null;
    _clearHintHighlight();
  }

  void continueSelection(int row, int col) {
    if (!isSelecting.value) return;
    
    Position newPosition = Position(row, col);
    if (lastSelectedPosition.value == newPosition) return;
    
    SoundManager().playTileSelect();
    
    if (selectedTiles.length > 1 && selectedTiles[selectedTiles.length - 2] == newPosition) {
      selectedTiles.removeLast();
      lastSelectedPosition.value = newPosition;
      return;
    }
    
    int existingIndex = selectedTiles.indexOf(newPosition);
    if (existingIndex >= 0) {
      selectedTiles.removeRange(existingIndex + 1, selectedTiles.length);
      lastSelectedPosition.value = newPosition;
      return;
    }
    
    if (selectedTiles.isNotEmpty) {
      List<Position>? autoPath = _calculateAutoPath(selectedTiles.first, newPosition);
      if (autoPath != null && autoPath.length > 1) {
        selectedTiles.clear();
        selectedTiles.addAll(autoPath);
        lastSelectedPosition.value = newPosition;
        
        if (autoPath.length >= 2) {
          _selectionRowDirection = autoPath[1].row - autoPath[0].row;
          _selectionColDirection = autoPath[1].col - autoPath[0].col;
        }
        return;
      }
    }
    
    if (_isValidContinuation(newPosition)) {
      selectedTiles.add(newPosition);
      lastSelectedPosition.value = newPosition;
    }
  }

  void endSelection() {
    isSelecting.value = false;
    _selectionRowDirection = null;
    _selectionColDirection = null;
    
    if (selectedTiles.isNotEmpty) {
      _checkSelectedWord();
    }
  }

  void _checkSelectedWord() {
    if (selectedTiles.isEmpty || _isShowingCelebration) return;
    
    String selectedWord = selectedTiles.map((pos) => _grid[pos.row][pos.col]).join();
    String reversedWord = selectedWord.split('').reversed.join();
    bool wordFound = false;
    
    print('DEBUG: Checking word: $selectedWord (reversed: $reversedWord)');
    
    for (int i = 0; i < words.length; i++) {
      WordModel wordModel = words[i];
      if (!wordModel.found && wordModel.positions.isNotEmpty) {
        
        bool wordMatches = (wordModel.word == selectedWord || wordModel.word == reversedWord);
        
        if (wordMatches) {
          bool positionsMatchForward = _checkPositionsMatch(wordModel.positions, selectedTiles.toList());
          bool positionsMatchBackward = _checkPositionsMatch(wordModel.positions, selectedTiles.toList().reversed.toList());
          
          if (positionsMatchForward || positionsMatchBackward) {
            words[i] = WordModel(
              word: wordModel.word,
              positions: wordModel.positions,
              color: wordModel.color,
              found: true,
            );
            
            foundWordPositions.addAll(wordModel.positions);
            wordsFoundCount.value++;
            
            int points = wordModel.word.length * 10;
            score.value += points;
            
            if (currentHintState.value?.word == wordModel) {
              _clearHintHighlight();
            }
            
            bool isLastWord = words.where((word) => word.positions.isNotEmpty).every((word) => word.found);
            print('DEBUG: Word found! isLastWord: $isLastWord, wordsFound: ${wordsFoundCount.value}/${totalWordsCount.value}');
            
            SoundManager().playWordFound();
            
            _showWordCelebration(wordModel.word, points, isLastWord);
            wordFound = true;
            break;
          }
        }
      }
    }
    
    if (!wordFound && selectedTiles.isNotEmpty) {
      SoundManager().playInvalidSelection();
      
      showInvalidSelection.value = true;
      
      Future.delayed(const Duration(milliseconds: 300), () {
        showInvalidSelection.value = false;
      });
    }
    
    clearSelection();
  }

  void _showWordCelebration(String foundWord, int points, bool isLastWord) {
    // Celebration removed - just play sound and check for game completion
    if (foundWord.length >= 6) {
      SoundManager().playCelebration();
    }
    
    if (isLastWord && !_isGameComplete) {
      print('DEBUG: Last word found, calling _handleGameComplete');
      _handleGameComplete();
    }
  }

  Future<void> _handleGameComplete() async{
    print('DEBUG: _handleGameComplete called - gameMode: $gameMode, level: $level');
    print('DEBUG: _isGameComplete: $_isGameComplete, _isShowingWinningScreen: $_isShowingWinningScreen, _isDisposed: $_isDisposed');
    
    if (_isGameComplete || _isShowingWinningScreen || _isDisposed) return;
    
    _isGameComplete = true;
    _updateTimeElapsed();
    
    int starsEarned = _calculateStarsEarned();
    SoundManager().onLevelComplete(starsEarned);
    
    if (gameMode == 'infinite') {
      _startNewInfiniteRound();
    } else if (gameMode == 'daily') {
        // Mark specific difficulty as completed instead of marking entire daily as completed
        if (difficulty != null) {
          await DailyPuzzleManager.markDifficultyAsCompleted(difficulty!);
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!_isDisposed) {
            SoundManager().playCelebration();
            // Go back to home screen
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!_isDisposed) {
                SoundManager().playPageTransition();
                Get.offAll(() => const HomeScreen());
              }
            });
          }
        });
      } else {
      // Show winning screen for all other modes including 'level'
      print('DEBUG: Scheduling winning screen display');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isShowingWinningScreen && !_isDisposed) {
          print('DEBUG: Actually showing winning screen now');
          _showWinningScreen();
        } else {
          print('DEBUG: Winning screen blocked - showing: $_isShowingWinningScreen, disposed: $_isDisposed');
        }
      });
    }
  }

  void _showWinningScreen() {
    print('DEBUG: _showWinningScreen called');
    if (showingWinningScreen.value || _isDisposed) return;
    
    _isShowingWinningScreen = true;
    int stars = _calculateStarsEarned();
    
    if (gameMode == 'level' && level != null) {
      LevelProgressManager.saveLevelStars(level!, stars);
      LevelProgressManager.saveLevelScore(level!, score.value);
    }
    
    SoundManager().playCelebration();
    
    // Set observable data for Stack rendering
    winningData.value = {
      'gameMode': gameMode,
      'level': level,
      'category': category,
      'difficulty': difficulty,
      'gridSize': gridSize.value,
      'finalScore': score.value,
      'starsEarned': stars,
    };
    
    showingWinningScreen.value = true;
  }

  void onWinningScreenClosed() {
    showingWinningScreen.value = false;
    _isShowingWinningScreen = false;
    winningData.clear();
  }

  void playNextLevel() {
    if (gameMode == 'level' && level != null) {
      try {
        int nextLevel = LevelProgressManager.getNextLevel(level!);
        
        SoundManager().playPageTransition();
        
        level = nextLevel;
        levelTitle.value = WordDatasets.getLevelTitle(nextLevel);
        gridSize.value = _getLevelGridSize(nextLevel);
        
        _resetCompleteGameState();
        initializeGame();
        
      } catch (e) {
        print('Error transitioning to next level: $e');
      }
    }
  }

  void resetGame() {
    SoundManager().playPageTransition();
    
    if (gameMode == 'infinite') {
      roundsCompleted.value = 0;
    }
    
    _resetCompleteGameState();
    _setupGameConfiguration();
    initializeGame();
  }

  void _startNewInfiniteRound() {
    roundsCompleted.value++;
    SoundManager().playCelebration();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed) {
        Future.delayed(const Duration(milliseconds: 200), () {
          SoundManager().playPageTransition();
          initializeGame();
        });
      }
    });
    
    score.value += 100;
  }

  void useHint() {
    if (hintsUsed.value >= 5) return;
    
    SoundManager().playHintUsed();
    
    WordModel? targetWord;
    int currentRevealedLetters = 0;
    
    if (currentHintState.value != null && 
        !currentHintState.value!.word.found && 
        currentHintState.value!.word.positions.isNotEmpty) {
      targetWord = currentHintState.value!.word;
      currentRevealedLetters = currentHintState.value!.revealedLetters;
    } else {
      List<WordModel> unFoundWords = words
          .where((word) => !word.found && word.positions.isNotEmpty)
          .toList();
      
      if (unFoundWords.isEmpty) return;
      
      unFoundWords.sort((a, b) => b.word.length.compareTo(a.word.length));
      targetWord = unFoundWords.first;
      currentRevealedLetters = 0;
    }
    
    int lettersToReveal = (currentRevealedLetters + 1).clamp(1, targetWord.word.length);
    hintsUsed.value++;
    
    currentHintState.value = HintState(
      word: targetWord,
      revealedLetters: lettersToReveal,
    );
    
    hintHighlightPositions.clear();
    for (int i = 0; i < lettersToReveal; i++) {
      hintHighlightPositions.add(targetWord.positions[i]);
    }
    showHintHighlight.value = true;
    
    String revealedLetters = targetWord.word.substring(0, lettersToReveal);
    String hiddenPart = '•' * (targetWord.word.length - lettersToReveal);
    
    String hintMessage;
    if (lettersToReveal == 1) {
      hintMessage = 'Look for "${targetWord.word}" - first letter "$revealedLetters" highlighted!';
    } else if (lettersToReveal < targetWord.word.length) {
      hintMessage = 'Look for "${targetWord.word}" - showing "$revealedLetters$hiddenPart" (${lettersToReveal}/${targetWord.word.length} letters)';
    } else {
      hintMessage = 'Look for "${targetWord.word}" - all letters highlighted! Find the correct path.';
    }
    
    Get.snackbar(
      'Hint ${hintsUsed.value}',
      hintMessage,
      backgroundColor: Colors.blue.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      snackPosition: SnackPosition.BOTTOM,
    );
    
    Future.delayed(const Duration(seconds: 8), () {
      if (currentHintState.value?.word == targetWord && 
          currentHintState.value?.revealedLetters == lettersToReveal) {
        _clearHintHighlight();
      }
    });
    
    int penalty = lettersToReveal == 1 ? 10 : lettersToReveal * 5;
    score.value = (score.value - penalty).clamp(0, score.value);
  }

  void _updateTimeElapsed() {
    if (gameStartTime != null && !_isAppPaused) {
      Duration elapsed = DateTime.now().difference(gameStartTime!);
      elapsed = elapsed - _pausedDuration;
      timeElapsed.value = elapsed.inSeconds / 60.0;
    }
  }

  void _resetCompleteGameState() {
    score.value = 0;
    wordsFoundCount.value = 0;
    totalWordsCount.value = 0;
    hintsUsed.value = 0;
    timeElapsed.value = 0.0;
    
    selectedTiles.clear();
    foundWordPositions.clear();
    words.clear();
    
    isSelecting.value = false;
    lastSelectedPosition.value = null;
    showInvalidSelection.value = false;
    
    gameStartTime = null;
    _pauseStartTime = null;
    
    _isGameComplete = false;
    _isShowingCelebration = false;
    _isShowingWinningScreen = false;
    
    _selectionRowDirection = null;
    _selectionColDirection = null;
    
    _clearHintHighlight();
    _grid.clear();
  }

  void _initializeGrid() {
    _grid.clear();
    for (int i = 0; i < gridSize.value; i++) {
      RxList<String> row = <String>[].obs;
      for (int j = 0; j < gridSize.value; j++) {
        row.add('');
      }
      _grid.add(row);
    }
  }

  void _setupWords() {
    List<String> gameWords = _getWordsForCurrentGame();
    words.clear();
    
    List<String> validWords = gameWords.where((word) => 
      word.length <= gridSize.value && word.length >= 3
    ).toList();
    
    validWords.sort((a, b) => b.length.compareTo(a.length));
    
    int maxWords = _getMaxWordsForGrid();
    if (validWords.length > maxWords) {
      validWords = validWords.take(maxWords).toList();
    }
    
    for (int i = 0; i < validWords.length; i++) {
      String word = validWords[i];
      words.add(WordModel(
        word: word,
        positions: [],
        color: _wordColors[i % _wordColors.length],
      ));
    }
  }

  int _getMaxWordsForGrid() {
    int gridArea = gridSize.value * gridSize.value;
    // Increase max words since we now support overlapping
    if (gridSize.value <= 6) return 6;
    if (gridSize.value <= 8) return 8;
    if (gridSize.value <= 10) return 10;
    return 12;
  }

  List<String> _getWordsForCurrentGame() {
    switch (gameMode) {
      case 'level':
        return level != null ? WordDatasets.getLevelWords(level!) : ['TREE', 'LEAF', 'BIRD', 'FISH'];
      case 'infinite':
        int wordCount = _getMaxWordsForGrid();
        return WordDatasets.getRandomWords(wordCount * 3, gridSize.value);
      case 'daily':
        if (difficulty != null) {
          return WordDatasets.getWordsForDifficulty('NATURE', difficulty!);
        }
        return WordDatasets.getWordsForDifficulty('NATURE', 'normal');
      case 'theme':
        if (category != null) {
          List<String> categoryWords = WordDatasets.categories[category] ?? WordDatasets.categories['NATURE']!;
          categoryWords = categoryWords.where((word) => word.length <= gridSize.value && word.length >= 3).toList()..shuffle();
          int wordCount = _getMaxWordsForGrid();
          return categoryWords.take(wordCount * 3).toList();
        }
        return WordDatasets.categories['NATURE']!.take(6).toList();
      default:
        return ['TREE', 'LEAF', 'BIRD', 'FISH', 'ROCK', 'WIND'];
    }
  }

  List<Position> _getWordPositions(String word, int startRow, int startCol, int direction) {
    List<Position> positions = [];
    
    List<List<int>> directions = [
      [0, 1], [0, -1], [1, 0], [-1, 0],
      [1, 1], [1, -1], [-1, 1], [-1, -1],
    ];
    
    int rowDelta = directions[direction][0];
    int colDelta = directions[direction][1];
    
    for (int i = 0; i < word.length; i++) {
      int row = startRow + (i * rowDelta);
      int col = startCol + (i * colDelta);
      
      if (row >= 0 && row < gridSize.value && col >= 0 && col < gridSize.value) {
        positions.add(Position(row, col));
      } else {
        return [];
      }
    }
    
    return positions;
  }

  void _fillEmptyCells() {
    Random random = Random();
    String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    
    for (int row = 0; row < gridSize.value; row++) {
      for (int col = 0; col < gridSize.value; col++) {
        if (_grid[row][col] == '') {
          _grid[row][col] = alphabet[random.nextInt(alphabet.length)];
        }
      }
    }
  }

  bool _checkPositionsMatch(List<Position> wordPositions, List<Position> selectedPositions) {
    if (wordPositions.length != selectedPositions.length) return false;
    
    for (int i = 0; i < wordPositions.length; i++) {
      if (wordPositions[i] != selectedPositions[i]) {
        return false;
      }
    }
    return true;
  }

  bool _isValidContinuation(Position newPosition) {
    if (selectedTiles.isEmpty) return true;
    
    Position lastPosition = selectedTiles.last;
    
    int rowDiff = (newPosition.row - lastPosition.row).abs();
    int colDiff = (newPosition.col - lastPosition.col).abs();
    
    bool isAdjacent = (rowDiff <= 1 && colDiff <= 1) && !(rowDiff == 0 && colDiff == 0);
    
    if (!isAdjacent) return false;
    
    if (selectedTiles.length == 1) {
      _selectionRowDirection = newPosition.row - lastPosition.row;
      _selectionColDirection = newPosition.col - lastPosition.col;
      return true;
    }
    
    if (selectedTiles.length >= 2) {
      return _isInEstablishedDirection(newPosition);
    }
    
    return true;
  }

  bool _isInEstablishedDirection(Position newPosition) {
    if (selectedTiles.isEmpty || _selectionRowDirection == null || _selectionColDirection == null) {
      return true;
    }
    
    Position lastPosition = selectedTiles.last;
    
    int expectedRow = lastPosition.row + _selectionRowDirection!;
    int expectedCol = lastPosition.col + _selectionColDirection!;
    
    return newPosition.row == expectedRow && newPosition.col == expectedCol;
  }

  List<Position>? _calculateAutoPath(Position start, Position end) {
    int rowDiff = end.row - start.row;
    int colDiff = end.col - start.col;
    
    if (rowDiff == 0 && colDiff == 0) return [start];
    if (rowDiff == 0) return _generateHorizontalPath(start, end);
    if (colDiff == 0) return _generateVerticalPath(start, end);
    if (rowDiff.abs() == colDiff.abs()) return _generateDiagonalPath(start, end);
    
    return null;
  }

  List<Position> _generateHorizontalPath(Position start, Position end) {
    List<Position> path = [];
    int step = end.col > start.col ? 1 : -1;
    
    for (int col = start.col; col != end.col + step; col += step) {
      path.add(Position(start.row, col));
    }
    return path;
  }

  List<Position> _generateVerticalPath(Position start, Position end) {
    List<Position> path = [];
    int step = end.row > start.row ? 1 : -1;
    
    for (int row = start.row; row != end.row + step; row += step) {
      path.add(Position(row, start.col));
    }
    return path;
  }

  List<Position> _generateDiagonalPath(Position start, Position end) {
    List<Position> path = [];
    int rowStep = end.row > start.row ? 1 : -1;
    int colStep = end.col > start.col ? 1 : -1;
    
    int currentRow = start.row;
    int currentCol = start.col;
    
    while (true) {
      path.add(Position(currentRow, currentCol));
      
      if (currentRow == end.row && currentCol == end.col) break;
      
      currentRow += rowStep;
      currentCol += colStep;
    }
    return path;
  }

  void _clearHintHighlight() {
    hintHighlightPositions.clear();
    showHintHighlight.value = false;
    currentHintState.value = null;
  }

  int _calculateStarsEarned() {
    if (gameMode == 'level' && level != null) {
      return LevelProgressManager.calculateStars(
        score: score.value,
        totalWords: totalWordsCount.value,
        hintsUsed: hintsUsed.value,
        timeElapsed: timeElapsed.value,
        level: level!,
      );
    } else {
      int stars = 1;
      double avgScorePerWord = totalWordsCount.value > 0 ? score.value / totalWordsCount.value : 0;
      
      if (avgScorePerWord >= 50 && hintsUsed.value <= 1) stars = 2;
      if (avgScorePerWord >= 70 && hintsUsed.value == 0) stars = 3;
      
      return stars.clamp(1, 3);
    }
  }

  bool _canPlayNextLevel() {
    if (gameMode == 'level' && level != null) {
      return LevelProgressManager.hasNextLevel(level!);
    }
    return false;
  }

  static String _getRandomCelebrationWord() {
    final random = Random();
    return _celebrationWords[random.nextInt(_celebrationWords.length)];
  }

  void clearSelection() {
    selectedTiles.clear();
    isSelecting.value = false;
    lastSelectedPosition.value = null;
    showInvalidSelection.value = false;
    
    _selectionRowDirection = null;
    _selectionColDirection = null;
  }

  // UI helper methods
  bool isTileSelected(int row, int col) {
    return selectedTiles.any((pos) => pos.row == row && pos.col == col);
  }

  bool isTilePartOfFoundWord(int row, int col) {
    return foundWordPositions.any((pos) => pos.row == row && pos.col == col);
  }

  bool isTileHintHighlighted(int row, int col) {
    if (!showHintHighlight.value) return false;
    return hintHighlightPositions.any((pos) => pos.row == row && pos.col == col);
  }

  Color? getTileFoundColor(int row, int col) {
    Position position = Position(row, col);
    for (WordModel word in words) {
      if (word.found && word.positions.contains(position)) {
        return word.color;
      }
    }
    return null;
  }

  String getCurrentSelectedWord() {
    if (selectedTiles.isEmpty) return '';
    return selectedTiles.map((pos) => _grid[pos.row][pos.col]).join();
  }

  bool isLastSelected(int row, int col) {
    return lastSelectedPosition.value?.row == row && lastSelectedPosition.value?.col == col;
  }

  // Sound helper methods for UI
  void playButtonSound() => SoundManager().playButtonClick();
  void playTransitionSound() => SoundManager().playPageTransition();
}