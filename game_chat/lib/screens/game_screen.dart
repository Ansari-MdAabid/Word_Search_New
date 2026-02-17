// lib/screens/game_screen.dart - Fixed with uniform component sizes

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/game_controller.dart';
import '../widgets/letter_tile.dart';
import '../widgets/word_list_view.dart';
import '../widgets/score_display.dart';
import '../widgets/animated_background.dart';
import '../widgets/winning_screen.dart';
import '../services/sound_manager.dart';
import 'home_screen.dart';
import 'dart:math' as math;

class GameScreen extends StatelessWidget {
  final String gameMode; // 'level', 'infinite', 'daily', 'theme'
  final int? level;
  final String? category;
  final String? difficulty;
  final int? gridSize;

  const GameScreen({
    super.key,
    this.gameMode = 'level',
    this.level,
    this.category,
    this.difficulty,
    this.gridSize,
  });

  @override
  Widget build(BuildContext context) {
    print('DEBUG: GameScreen build called with gameMode: $gameMode, level: $level');
    
    // Remove any existing controller first, then register new one
    if (Get.isRegistered<GameController>()) {
      Get.delete<GameController>();
    }
    
    // Properly register the controller with GetX dependency injection
    final controller = Get.put(GameController(
      gameMode: gameMode,
      level: level,
      category: category,
      difficulty: difficulty,
      customGridSize: gridSize,
    ), permanent: false);

    return WillPopScope(
      onWillPop: () async {
        // Handle back button - show confirmation dialog
        bool shouldPop = await _showExitConfirmation(context);
        return shouldPop;
      },
      child: Scaffold(
        body: AnimatedBackground(
          child: SafeArea(
            child: GetBuilder<GameController>(
              builder: (controller) {
                return Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Use MediaQuery to get screen orientation and dimensions
                        final mediaQuery = MediaQuery.of(context);
                        final isLandscape = mediaQuery.orientation == Orientation.landscape;
                        
                        if (isLandscape) {
                          return _buildLandscapeLayout(controller, constraints);
                        } else {
                          return _buildPortraitLayout(controller, constraints);
                        }
                      },
                    ),
                    

                    // Stack-based Winning Screen Overlay (Crisp, no dialog blur)
                    Obx(() => controller.showingWinningScreen.value 
                      ? WinningScreen(
                          gameMode: controller.winningData['gameMode'] ?? 'level',
                          level: controller.winningData['level'],
                          category: controller.winningData['category'],
                          difficulty: controller.winningData['difficulty'],
                          gridSize: controller.winningData['gridSize'],
                          finalScore: controller.winningData['finalScore'] ?? 0,
                          starsEarned: controller.winningData['starsEarned'] ?? 0,
                          onReplay: () {
                            controller.onWinningScreenClosed();
                            controller.resetGame();
                          },
                          onHome: () {
                            controller.onWinningScreenClosed();
                             SoundManager().playPageTransition();
                            Get.offAll(() => const HomeScreen());
                          },
                          onNextLevel: controller.level != null ? () {
                            controller.onWinningScreenClosed();
                            controller.playNextLevel();
                          } : null,
                        )
                      : const SizedBox.shrink()),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to create uniform containers
  Widget _buildUniformContainer({
    required Widget child,
    Color? backgroundColor,
    double borderRadius = 14.0,
  }) {
    return Container(
      height: 32, // Fixed height for all components
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildPortraitLayout(GameController controller, BoxConstraints constraints) {
    double availableHeight = constraints.maxHeight;
    double availableWidth = constraints.maxWidth;
    
    // More precise space calculations to prevent overflow
    double headerHeight = availableHeight * 0.12; // Dynamic header height
    double currentSelectionHeight = availableHeight * 0.05; // Dynamic selection height
    double bottomPadding = 16; 
    double spacingBetweenElements = availableHeight * 0.03; 
    
    headerHeight = headerHeight.clamp(80.0, 120.0);
    currentSelectionHeight = currentSelectionHeight.clamp(30.0, 50.0);
    
    // Calculate remaining height for grid and word list
    double remainingHeight = availableHeight - headerHeight - currentSelectionHeight - bottomPadding - spacingBetweenElements;
    
    // Ensure we have minimum space
    if (remainingHeight < 300) {
      remainingHeight = 300; // Minimum required space
    }
    
    // Grid takes priority, word list gets remaining space - increased to 70%
    double maxGridSize = availableWidth - 32; // Account for horizontal padding
    double gridHeight = remainingHeight * 0.70; // Increased from 0.55 to give more space to grid
    double gridSize = math.min(gridHeight, maxGridSize).clamp(200.0, 400.0);
    
    // Word list gets the remaining space
    double wordListHeight = remainingHeight - gridSize;
    // Ensure minimum height for word list
    wordListHeight = math.max(wordListHeight, 80); // Reduced min height from 120

    return Column(
      children: [
        const SizedBox(height: 8),

        // Header Section with Title, Score, and Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Level Title
              Obx(() => FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  controller.levelTitle.value,
                  style: const TextStyle(
                    fontSize: 20, 
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )),
              const SizedBox(height: 8), // Reduced from 12

              // Score, Progress, and Compact Control Buttons Row - All uniform sizes
              Row(
                children: [
                  // Score Display - Uniform container
                  Expanded(
                    child: _buildUniformContainer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stars, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Obx(() => Text(
                            '${controller.score.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 6),
                  
                  // Words Found Counter - Uniform container
                  Expanded(
                    child: _buildUniformContainer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Obx(() => Text(
                            '${controller.wordsFoundCount.value}/${controller.totalWordsCount.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 6),
                  
                  // Hint Button - Uniform container
                  Expanded(
                    child: Obx(() => _buildUniformContainer(
                      backgroundColor: controller.hintsUsed.value < 3 
                          ? Colors.amber.shade600.withOpacity(0.8)
                          : Colors.grey.shade600.withOpacity(0.8),
                      child: InkWell(
                        onTap: controller.hintsUsed.value < 3 ? controller.useHint : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lightbulb,
                              size: 14,
                              color: controller.hintsUsed.value < 3 ? Colors.white : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${3 - controller.hintsUsed.value}',
                              style: TextStyle(
                                fontSize: 12,
                                color: controller.hintsUsed.value < 3 ? Colors.white : Colors.grey.shade400,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ),
                  
                  const SizedBox(width: 6),
                  
                  // Reset Button - Uniform container
                  Expanded(
                    child: _buildUniformContainer(
                      backgroundColor: Colors.red.shade600.withOpacity(0.8),
                      child: InkWell(
                        onTap: controller.resetGame,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8), // Reduced from 12

        // Game Grid - Fixed size
        Container(
          width: gridSize,
          height: gridSize,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: _buildGameGrid(controller),
        ),
        
        const SizedBox(height: 6), // Reduced spacing

        // Current selection display - more compact
        SizedBox(
          height: currentSelectionHeight,
          child: Center(
            child: _buildCurrentSelection(controller),
          ),
        ),

        const SizedBox(height: 6), // Reduced spacing

        // Word List - Fixed height to prevent overflow
        Container(
          height: wordListHeight,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Word List Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reduced padding
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.list_alt,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Words to Find',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13, // Reduced font size
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Obx(() => Text(
                      '${controller.wordsFoundCount.value}/${controller.totalWordsCount.value}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11, // Reduced font size
                      ),
                    )),
                  ],
                ),
              ),
              // Word List Content - Flexible to use remaining space
              Expanded(
                child: _buildWordList(controller),
              ),
            ],
          ),
        ),

        // Bottom spacing
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLandscapeLayout(GameController controller, BoxConstraints constraints) {
    double availableHeight = constraints.maxHeight;
    double availableWidth = constraints.maxWidth;
    
    // In landscape, use side-by-side layout
    double gridSize = (availableHeight - 100).clamp(200.0, double.infinity); // Leave space for header
    
    return Column(
      children: [
        const SizedBox(height: 8),
        
        // Header with title, stats, and compact controls - All uniform
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Title
              Expanded(
                flex: 3,
                child: Obx(() => Text(
                  controller.levelTitle.value,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ),
              
              // Score - Uniform container
              _buildUniformContainer(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Obx(() => Text(
                      '${controller.score.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Progress - Uniform container
              _buildUniformContainer(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Obx(() => Text(
                      '${controller.wordsFoundCount.value}/${controller.totalWordsCount.value}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Hint Button - Uniform container
              Obx(() => _buildUniformContainer(
                backgroundColor: controller.hintsUsed.value < 3 
                    ? Colors.amber.shade600.withOpacity(0.8)
                    : Colors.grey.shade600.withOpacity(0.8),
                child: InkWell(
                  onTap: controller.hintsUsed.value < 3 ? controller.useHint : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb,
                        size: 14,
                        color: controller.hintsUsed.value < 3 ? Colors.white : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${3 - controller.hintsUsed.value}',
                        style: TextStyle(
                          fontSize: 12,
                          color: controller.hintsUsed.value < 3 ? Colors.white : Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
              
              const SizedBox(width: 8),
              
              // Reset Button - Uniform container
              _buildUniformContainer(
                backgroundColor: Colors.red.shade600.withOpacity(0.8),
                child: InkWell(
                  onTap: controller.resetGame,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Main content area - side by side
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Game Grid
              Container(
                width: gridSize,
                height: gridSize,
                margin: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: _buildGameGrid(controller),
              ),
              
              const SizedBox(width: 16),
              
              // Sidebar with current selection and expanded word list
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      // Current selection
                      _buildCurrentSelection(controller),
                      const SizedBox(height: 12),
                      
                      // Word list - takes most of the space with header
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Word List Header
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.list_alt, color: Colors.white70, size: 16),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Words to Find',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Obx(() => Text(
                                      '${controller.wordsFoundCount.value}/${controller.totalWordsCount.value}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                              // Word List Content
                              Expanded(
                                child: _buildWordList(controller),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
      ],
    );
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Game?'),
        content: const Text('Are you sure you want to exit? Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildGameGrid(GameController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Store the container size for coordinate calculation
        final containerSize = constraints.biggest;
        
        return Container(
          padding: const EdgeInsets.all(8.0), // Reduced padding for more grid space
          child: GestureDetector(
            onPanStart: (details) {
              final coordinates = _getTileCoordinates(
                details.localPosition, 
                controller, 
                containerSize
              );
              if (coordinates != null) {
                print('Pan start at (${coordinates.row}, ${coordinates.col})');
                controller.startSelection(coordinates.row, coordinates.col);
              }
            },
            onPanUpdate: (details) {
              if (controller.isSelecting.value) {
                final coordinates = _getTileCoordinates(
                  details.localPosition, 
                  controller, 
                  containerSize
                );
                if (coordinates != null) {
                  controller.continueSelection(coordinates.row, coordinates.col);
                }
              }
            },
            onPanEnd: (_) {
              print('Pan end');
              controller.endSelection();
            },
            child: Obx(() => GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: controller.gridSize.value,
                childAspectRatio: 1,
                crossAxisSpacing: 1, // Reduced spacing for larger tiles
                mainAxisSpacing: 1,
              ),
              itemCount: controller.gridSize.value * controller.gridSize.value,
              itemBuilder: (context, index) {
                final row = index ~/ controller.gridSize.value;
                final col = index % controller.gridSize.value;

                return GestureDetector(
                  onTap: () {
                    // Handle single tap
                    controller.startSelection(row, col);
                    // End selection immediately after single tap
                    Future.delayed(const Duration(milliseconds: 50), () {
                      controller.endSelection();
                    });
                  },
                  child: Container(
                    key: ValueKey('tile_${row}_$col'),
                    child: Obx(() => LetterTile(
                      letter: controller.grid.length > row && controller.grid[row].length > col 
                          ? controller.grid[row][col] 
                          : '',
                      isSelected: controller.isTileSelected(row, col),
                      isFound: controller.isTilePartOfFoundWord(row, col),
                      isLastSelected: controller.isLastSelected(row, col),
                      isHintHighlighted: controller.isTileHintHighlighted(row, col),
                      foundColor: controller.getTileFoundColor(row, col),
                    )),
                  ),
                );
              },
            )),
          ),
        );
      },
    );
  }

  Position? _getTileCoordinates(Offset localPosition, GameController controller, Size containerSize) {
    final int gridCount = controller.gridSize.value;
    final double spacing = 1.0; // Updated to match reduced spacing
    
    // Account for container padding (8px on each side)
    final double contentSize = containerSize.width - 16; // Remove padding
    final double totalSpacing = spacing * (gridCount - 1);
    final double tileSize = (contentSize - totalSpacing) / gridCount;
    
    // Adjust for padding
    final double adjustedX = localPosition.dx - 8;
    final double adjustedY = localPosition.dy - 8;
    
    // Check if the position is within bounds
    if (adjustedX < 0 || adjustedY < 0 || adjustedX >= contentSize || adjustedY >= contentSize) {
      return null;
    }
    
    // Calculate tile coordinates
    int col = (adjustedX / (tileSize + spacing)).floor();
    int row = (adjustedY / (tileSize + spacing)).floor();
    
    // Validate coordinates
    if (row >= 0 && row < gridCount && col >= 0 && col < gridCount) {
      // Additional check to ensure we're actually within the tile bounds
      double tileStartX = col * (tileSize + spacing);
      double tileStartY = row * (tileSize + spacing);
      
      if (adjustedX >= tileStartX && adjustedX <= tileStartX + tileSize &&
          adjustedY >= tileStartY && adjustedY <= tileStartY + tileSize) {
        return Position(row, col);
      }
    }
    
    return null;
  }

  Widget _buildWordList(GameController controller) {
    return Obx(() {
      List<WordWithColor> wordsWithColors = controller.words.map((w) => 
        WordWithColor(
          word: w.word,
          color: w.color,
          found: w.found,
        )
      ).toList();
      
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: WordListView(wordsWithColors: wordsWithColors),
        ),
      );
    });
  }

  Widget _buildCurrentSelection(GameController controller) {
    return Obx(() {
      String currentWord = controller.getCurrentSelectedWord();
      bool showInvalid = controller.showInvalidSelection.value;
      
      if (currentWord.isEmpty && !showInvalid) {
        return const SizedBox(height: 20); // Reduced height
      }
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        constraints: const BoxConstraints(maxWidth: 280), // Limit width
        decoration: BoxDecoration(
          color: showInvalid ? Colors.red.withOpacity(0.3) : Colors.white24,
          borderRadius: BorderRadius.circular(12), // Smaller radius
          border: Border.all(
            color: showInvalid ? Colors.red : Colors.white38,
            width: showInvalid ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // Reduced padding
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                showInvalid ? Icons.close : Icons.text_fields,
                color: showInvalid ? Colors.red : Colors.white70,
                size: 12, // Smaller icon
              ),
              const SizedBox(width: 4), // Reduced spacing
              Flexible(
                child: Text(
                  showInvalid ? 'Word not found' : 'Selected: ${currentWord.toUpperCase()}',
                  style: TextStyle(
                    color: showInvalid ? Colors.red : Colors.white,
                    fontSize: 11, // Smaller font
                    fontWeight: FontWeight.w500,
                    letterSpacing: showInvalid ? 0 : 0.5, // Reduced letter spacing
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class Position {
  final int row;
  final int col;

  Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && 
      runtimeType == other.runtimeType && 
      row == other.row && 
      col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Position($row, $col)';
}