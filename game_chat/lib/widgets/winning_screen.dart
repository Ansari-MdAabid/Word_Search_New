// lib/widgets/winning_screen.dart - Updated version with better navigation handling

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/game_screen.dart';
import '../screens/home_screen.dart';
import '../services/level_progress_manager.dart';

class WinningScreen extends StatefulWidget {
  final String gameMode;
  final int? level;
  final String? category;
  final String? difficulty;
  final int? gridSize;
  final int finalScore;
  final int starsEarned;
  final VoidCallback onReplay;
  final VoidCallback onHome;
  final VoidCallback? onNextLevel;

  const WinningScreen({
    super.key,
    required this.gameMode,
    this.level,
    this.category,
    this.difficulty,
    this.gridSize,
    required this.finalScore,
    required this.starsEarned,
    required this.onReplay,
    required this.onHome,
    this.onNextLevel,
  });

  @override
  State<WinningScreen> createState() => _WinningScreenState();
}

class _WinningScreenState extends State<WinningScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _starController;
  late AnimationController _buttonController;
  late AnimationController _starsAllocationController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _starScaleAnimation;
  late Animation<double> _buttonSlideAnimation;

  bool _isDisposed = false;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    print('DEBUG: WinningScreen initState called');
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _starController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _starsAllocationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeInOut,
    ));

    _starScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _starController,
      curve: Curves.elasticOut,
    ));

    _buttonSlideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOutBack,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    if (_isDisposed) return;
    
    print('DEBUG: Starting WinningScreen animations');
    _mainController.forward();
    
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && !_isDisposed) _starController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && !_isDisposed) _starsAllocationController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_isDisposed) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    print('DEBUG: WinningScreen dispose called');
    _isDisposed = true;
    _mainController.dispose();
    _starController.dispose();
    _buttonController.dispose();
    _starsAllocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: WinningScreen build called');
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _starController,
          _buttonController,
          _starsAllocationController
        ]),
        builder: (context, child) {
          return Container(
            color: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
            child: SafeArea(
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                      maxWidth: 500,
                    ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Trophy Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.yellow.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.yellow,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              size: 48,
                              color: Colors.yellow,
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Congratulations Text
                          const Text(
                            'LEVEL COMPLETE!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            _getLevelText(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Stars with enhanced animation
                          Transform.scale(
                            scale: _starScaleAnimation.value,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (index) {
                                bool isEarned = index < widget.starsEarned;
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 400 + (index * 200)),
                                  curve: Curves.elasticOut,
                                  margin: const EdgeInsets.symmetric(horizontal: 6),
                                  child: TweenAnimationBuilder<double>(
                                    duration: Duration(milliseconds: 600 + (index * 300)),
                                    tween: Tween<double>(
                                      begin: 0.0,
                                      end: isEarned ? 1.0 : 0.3,
                                    ),
                                    curve: Curves.elasticOut,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: 0.5 + (value * 0.5),
                                        child: Icon(
                                          isEarned ? Icons.star : Icons.star_border,
                                          size: 40,
                                          color: Color.lerp(
                                            Colors.white30,
                                            isEarned ? Colors.yellow : Colors.white30,
                                            value,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Score Display
                          _buildScoreDisplay(),
                          
                          const SizedBox(height: 20),
                          
                          // Star allocation display (compressed)
                          if (widget.gameMode == 'level' && widget.level != null)
                            Opacity(
                              opacity: _starsAllocationController.value.clamp(0.0, 1.0),
                              child: _buildCompactStarRequirements(),
                            ),
                          
                          const SizedBox(height: 24),
                          
                          // Buttons - Fixed responsive layout
                          Transform.translate(
                            offset: Offset(0, 50 * _buttonSlideAnimation.value),
                            child: _buildButtonSection(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButtonSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool useColumnLayout = constraints.maxWidth < 350;
        double buttonSpacing = 10;
        
        return Column(
          children: [
            // Next Level Button (if available) - Always full width
            if (widget.onNextLevel != null && _shouldShowNextLevelButton()) ...[
              SizedBox(
                width: double.infinity,
                child: _WinButton(
                  title: 'Next Level',
                  icon: Icons.arrow_forward,
                  color: Colors.green,
                  onTap: () {
                    _closeAndExecute(() {
                      widget.onNextLevel!();
                    });
                  },
                ),
              ),
              SizedBox(height: buttonSpacing),
            ],
            
            // Action Buttons - Responsive layout
            if (useColumnLayout)
              // Column layout for small screens
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: _WinButton(
                      title: 'Replay',
                      icon: Icons.replay,
                      color: Colors.orange,
                      onTap: () {
                        _closeAndExecute(widget.onReplay);
                      },
                    ),
                  ),
                  SizedBox(height: buttonSpacing),
                  SizedBox(
                    width: double.infinity,
                    child: _WinButton(
                      title: 'Home',
                      icon: Icons.home,
                      color: Colors.blue,
                      onTap: () {
                        _closeAndExecute(widget.onHome);
                      },
                    ),
                  ),
                ],
              )
            else
              // Row layout for larger screens
              Row(
                children: [
                  Expanded(
                    child: _WinButton(
                      title: 'Replay',
                      icon: Icons.replay,
                      color: Colors.orange,
                      onTap: () {
                        _closeAndExecute(widget.onReplay);
                      },
                    ),
                  ),
                  SizedBox(width: buttonSpacing),
                  Expanded(
                    child: _WinButton(
                      title: 'Home',
                      icon: Icons.home,
                      color: Colors.blue,
                      onTap: () {
                        _closeAndExecute(widget.onHome);
                      },
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildCompactStarRequirements() {
    if (widget.level == null) return const SizedBox.shrink();
    
    int tier = _getLevelTier(widget.level!);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        children: [
          const Text(
            'Star Requirements',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildCompactRequirement(1, 'Complete level', widget.starsEarned >= 1),
          _buildCompactRequirement(2, _getTwoStarRequirement(tier), widget.starsEarned >= 2),
          _buildCompactRequirement(3, _getThreeStarRequirement(tier), widget.starsEarned >= 3),
        ],
      ),
    );
  }

  Widget _buildCompactRequirement(int starNumber, String requirement, bool achieved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            achieved ? Icons.check_circle : Icons.radio_button_unchecked,
            color: achieved ? Colors.green : Colors.white60,
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              requirement,
              style: TextStyle(
                fontSize: 11,
                color: achieved ? Colors.white : Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay() {
    int previousHighScore = 0;
    bool isNewRecord = false;
    
    if (widget.gameMode == 'level' && widget.level != null) {
      try {
        previousHighScore = LevelProgressManager.getLevelHighScore(widget.level!);
        isNewRecord = widget.finalScore > previousHighScore;
      } catch (e) {
        debugPrint('Error getting high score: $e');
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 6),
              Text(
                'Score: ${widget.finalScore}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (isNewRecord) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text(
                    'NEW!',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          if (previousHighScore > 0 && !isNewRecord) ...[
            const SizedBox(height: 4),
            Text(
              'Previous Best: $previousHighScore',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white60,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getLevelText() {
    if (widget.gameMode == 'level' && widget.level != null) {
      return 'Level ${widget.level}';
    } else if (widget.gameMode == 'theme' && widget.category != null) {
      String categoryName = widget.category!.toLowerCase();
      categoryName = categoryName[0].toUpperCase() + categoryName.substring(1);
      return '$categoryName Theme';
    }
    return 'Challenge Complete';
  }

  bool _shouldShowNextLevelButton() {
    if (widget.gameMode == 'level' && widget.level != null) {
      try {
        return LevelProgressManager.hasNextLevel(widget.level!) && widget.starsEarned >= 1;
      } catch (e) {
        debugPrint('Error checking next level: $e');
        return false;
      }
    }
    return false;
  }

  void _closeAndExecute(VoidCallback callback) {
    if (_isDisposed || _isClosing) return;
    
    print('DEBUG: WinningScreen closing and executing callback');
    _isClosing = true;
    
    // Reverse animations
    _mainController.reverse();
    _starController.reverse();
    _buttonController.reverse();
    _starsAllocationController.reverse();
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && !_isDisposed) {
        callback();
      }
    });
  }

  // Helper methods
  int _getLevelTier(int level) {
    if (level <= 10) return 1;
    if (level <= 20) return 2;
    if (level <= 30) return 3;
    if (level <= 40) return 4;
    return 5;
  }

  String _getTwoStarRequirement(int tier) {
    int baseScore = [35, 45, 55, 65, 70][tier - 1];
    int maxHints = tier >= 5 ? 0 : tier >= 3 ? 1 : 2;
    return '${baseScore}+/word${maxHints > 0 ? ', ≤$maxHints hint' : ', no hints'}';
  }

  String _getThreeStarRequirement(int tier) {
    int excellentScore = ([35, 45, 55, 65, 70][tier - 1] * 1.4).round();
    return '${excellentScore}+/word, no hints, fast';
  }
}

class _WinButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _WinButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_WinButton> createState() => _WinButtonState();
}

class _WinButtonState extends State<_WinButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isTapping = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              if (!_isTapping) {
                _isTapping = true;
                _controller.forward();
              }
            },
            onTapUp: (_) {
              if (_isTapping) {
                _isTapping = false;
                _controller.reverse();
                widget.onTap();
              }
            },
            onTapCancel: () {
              if (_isTapping) {
                _isTapping = false;
                _controller.reverse();
              }
            },
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 44,
                maxHeight: 50,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
}