import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'game_screen.dart';
import '../widgets/animated_background.dart';
import '../services/level_progress_manager.dart';
import '../data/word_datasets.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the level progress manager
    LevelProgressManager.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header with progress info
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Select Level',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Progress summary
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ProgressStat(
                            icon: Icons.star,
                            label: 'Stars',
                            value: '${LevelProgressManager.getTotalStars()}',
                            color: Colors.amber,
                          ),
                          _ProgressStat(
                            icon: Icons.check_circle,
                            label: 'Completed',
                            value: '${LevelProgressManager.getCompletedLevels()}/50',
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Level Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate dynamic sizing based on available space
                      double availableHeight = constraints.maxHeight;
                      double availableWidth = constraints.maxWidth;
                      
                      // Calculate grid parameters
                      int crossAxisCount = 4;
                      double spacing = 12;
                      double totalHorizontalSpacing = (crossAxisCount - 1) * spacing;
                      double tileWidth = (availableWidth - totalHorizontalSpacing) / crossAxisCount;
                      
                      // Calculate number of rows needed
                      int totalLevels = 50;
                      int rows = (totalLevels / crossAxisCount).ceil();
                      
                      // Calculate tile height to fit available space
                      double totalVerticalSpacing = (rows - 1) * spacing;
                      double maxTileHeight = (availableHeight - totalVerticalSpacing) / rows;
                      
                      // Use smaller of calculated dimensions to maintain aspect ratio
                      double tileSize = tileWidth.clamp(60.0, 100.0);
                      double actualTileHeight = (maxTileHeight).clamp(75.0, 120.0);
                      
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: tileSize / actualTileHeight,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                        ),
                        itemCount: totalLevels,
                        itemBuilder: (context, index) {
                          int levelNumber = index + 1;
                          return _LevelTile(
                            levelNumber: levelNumber,
                            tileSize: tileSize,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProgressStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LevelTile extends StatefulWidget {
  final int levelNumber;
  final double tileSize;

  const _LevelTile({
    required this.levelNumber,
    required this.tileSize,
  });

  @override
  State<_LevelTile> createState() => _LevelTileState();
}

class _LevelTileState extends State<_LevelTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatCategoryName(String category) {
    if (category.isEmpty) return category;
    return category[0].toUpperCase() + category.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    bool isUnlocked = LevelProgressManager.isLevelUnlocked(widget.levelNumber);
    int stars = LevelProgressManager.getLevelStars(widget.levelNumber);
    bool isCompleted = stars > 0;
    Color levelColor = _getLevelColor(widget.levelNumber);

    // Dynamic font sizes based on tile size
    double levelNumberFontSize = (widget.tileSize * 0.24).clamp(16.0, 24.0);
    double categoryFontSize = (widget.tileSize * 0.09).clamp(8.0, 11.0);
    double starSize = (widget.tileSize * 0.14).clamp(10.0, 16.0);
    double scoreFontSize = (widget.tileSize * 0.08).clamp(7.0, 10.0);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              if (isUnlocked) {
                _animationController.forward();
              }
            },
            onTapUp: (_) {
              if (isUnlocked) {
                _animationController.reverse();
                _navigateToLevel();
              }
            },
            onTapCancel: () {
              _animationController.reverse();
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isUnlocked
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          levelColor,
                          levelColor.withOpacity(0.7),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.shade400,
                          Colors.grey.shade600,
                        ],
                      ),
                border: Border.all(
                  color: isUnlocked ? Colors.white.withOpacity(0.3) : Colors.grey,
                  width: 2,
                ),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: levelColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Padding(
                padding: EdgeInsets.all(widget.tileSize * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Level number or lock icon
                    if (isUnlocked)
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${widget.levelNumber}',
                            style: TextStyle(
                              fontSize: levelNumberFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.lock,
                        color: Colors.white70,
                        size: levelNumberFontSize,
                      ),
                    
                    if (isUnlocked) ...[
                      SizedBox(height: widget.tileSize * 0.04),
                      
                      // Category name
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _getCategoryName(widget.levelNumber),
                            style: TextStyle(
                              fontSize: categoryFontSize,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: widget.tileSize * 0.06),
                      
                      // Stars display with animation
                      Flexible(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isCompleted
                              ? Row(
                                  key: ValueKey('stars_$stars'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(3, (index) {
                                    return Flexible(
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 200 + (index * 100)),
                                        curve: Curves.elasticOut,
                                        child: Icon(
                                          index < stars ? Icons.star : Icons.star_border,
                                          color: index < stars ? Colors.yellow : Colors.white54,
                                          size: starSize,
                                        ),
                                      ),
                                    );
                                  }),
                                )
                              : SizedBox(
                                  key: const ValueKey('stars_empty'),
                                  height: starSize,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(3, (index) {
                                      return Flexible(
                                        child: Icon(
                                          Icons.star_border,
                                          color: Colors.white30,
                                          size: starSize,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                        ),
                      ),
                      
                      // High score display
                      if (isCompleted) ...[
                        SizedBox(height: widget.tileSize * 0.02),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${LevelProgressManager.getLevelHighScore(widget.levelNumber)}',
                              style: TextStyle(
                                fontSize: scoreFontSize,
                                color: Colors.white60,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getLevelColor(int level) {
    List<Color> colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[(level - 1) % colors.length];
  }

  String _getCategoryName(int level) {
    List<String> categoryOrder = [
      'NATURE', 'ANIMALS', 'FOOD', 'COLORS', 'SPORTS',
      'TECHNOLOGY', 'SPACE', 'VEHICLES', 'MUSIC', 'HOME'
    ];
    
    String category = categoryOrder[(level - 1) % categoryOrder.length];
    return _formatCategoryName(category);
  }

  void _navigateToLevel() {
    // Check if the level has valid words before navigating
    final words = WordDatasets.getLevelWords(widget.levelNumber);
    if (words.isEmpty) {
      Get.dialog(
        AlertDialog(
          title: const Text('Level Unavailable'),
          content: const Text('No words found for this level. Please try another level.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
        barrierDismissible: true,
      );
      return;
    }
    Get.to(
      () => GameScreen(
        gameMode: 'level',
        level: widget.levelNumber,
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 300),
    );
  }
}