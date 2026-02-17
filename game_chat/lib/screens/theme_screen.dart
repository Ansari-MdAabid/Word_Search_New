// lib/screens/theme_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/word_datasets.dart';
import 'game_screen.dart';
import '../widgets/animated_background.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  int _selectedGridSize = 6;
  final List<int> _gridSizes = [6, 8, 10, 12];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
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
                          'Choose Theme',
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
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Grid Size Selector
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Grid Size',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _gridSizes.map((size) {
                        bool isSelected = size == _selectedGridSize;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedGridSize = size),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              '${size}x$size',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Categories Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: WordDatasets.categories.length,
                    itemBuilder: (context, index) {
                      String category = WordDatasets.categories.keys.elementAt(index);
                      return _ThemeTile(
                        category: category,
                        gridSize: _selectedGridSize,
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

class _ThemeTile extends StatefulWidget {
  final String category;
  final int gridSize;

  const _ThemeTile({
    required this.category,
    required this.gridSize,
  });

  @override
  State<_ThemeTile> createState() => _ThemeTileState();
}

class _ThemeTileState extends State<_ThemeTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

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
    Color categoryColor = _getCategoryColor(widget.category);
    IconData categoryIcon = _getCategoryIcon(widget.category);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _animationController.forward();
            },
            onTapUp: (_) {
              setState(() => _isPressed);
              _animationController.reverse();
              _navigateToGame();
            },
            onTapCancel: () {
              setState(() => _isPressed);
              _animationController.reverse();
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    categoryColor,
                    categoryColor.withOpacity(0.7),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: categoryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    categoryIcon,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatCategoryName(widget.category),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${WordDatasets.categories[widget.category]!.length} words',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    Map<String, Color> categoryColors = {
      'ANIMALS': Colors.green,
      'NATURE': Colors.teal,
      'FOOD': Colors.orange,
      'SPORTS': Colors.blue,
      'COLORS': Colors.purple,
      'TECHNOLOGY': Colors.indigo,
      'SPACE': Colors.deepPurple,
      'VEHICLES': Colors.red,
      'MUSIC': Colors.pink,
      'HOME': Colors.brown,
    };
    return categoryColors[category] ?? Colors.grey;
  }

  IconData _getCategoryIcon(String category) {
    Map<String, IconData> categoryIcons = {
      'ANIMALS': Icons.pets,
      'NATURE': Icons.nature,
      'FOOD': Icons.restaurant,
      'SPORTS': Icons.sports_soccer,
      'COLORS': Icons.palette,
      'TECHNOLOGY': Icons.computer,
      'SPACE': Icons.rocket_launch,
      'VEHICLES': Icons.directions_car,
      'MUSIC': Icons.music_note,
      'HOME': Icons.home,
    };
    return categoryIcons[category] ?? Icons.category;
  }

  void _navigateToGame() {
    Get.to(
      () => GameScreen(
        gameMode: 'theme',
        category: widget.category,
        gridSize: widget.gridSize,
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 300),
    );
  }
}