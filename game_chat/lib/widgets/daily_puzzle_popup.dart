import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/game_screen.dart';
import '../services/daily_puzzle_manager.dart';
import '../screens/home_screen.dart';

class DailyPuzzle {
  static Future<void> showPopup() async {
    // Check if ALL difficulties are completed
    final isAllCompleted = await DailyPuzzleManager.isCompletedToday();
    final canPlay = await DailyPuzzleManager.canPlayToday();
    
    if (isAllCompleted && !canPlay) {
      // Show completion message only when ALL difficulties are done
      final timeUntilNext = await DailyPuzzleManager.getTimeUntilNextPuzzle();
      String message = 'All difficulties completed today!';
      
      if (timeUntilNext != null) {
        final hours = timeUntilNext.inHours;
        final minutes = timeUntilNext.inMinutes % 60;
        message += '\nNext puzzle in ${hours}h ${minutes}m';
      }
      
      Get.snackbar(
        'Daily Puzzle Complete',
        message,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
      return;
    }
    
    // Show popup - user can still play remaining difficulties
    Get.dialog(
      const _DailyPuzzleDialog(),
      barrierDismissible: true,
    );
  }
}

class _DailyPuzzleDialog extends StatefulWidget {
  const _DailyPuzzleDialog();

  @override
  State<_DailyPuzzleDialog> createState() => _DailyPuzzleDialogState();
}

class _DailyPuzzleDialogState extends State<_DailyPuzzleDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  String _selectedDifficulty = 'normal';
  bool _canPlayToday = true;
  bool _isAllCompleted = false;
  String _statusMessage = 'Loading...';
  bool _isLoading = true;
  
  // Track completion status for each difficulty
  Map<String, bool> _difficultyCompletionStatus = {
    'easy': false,
    'normal': false,
    'hard': false,
  };
  
  final Map<String, DifficultyInfo> _difficulties = {
    'easy': DifficultyInfo(
      title: 'Easy Mode',
      description: '6×6 grid • 6 words • 3-5 letters each',
      color: Colors.green,
      icon: Icons.sentiment_satisfied,
      gridSize: 6,
      wordCount: 6,
    ),
    'normal': DifficultyInfo(
      title: 'Normal Mode',
      description: '8×8 grid • 8 words • 4-7 letters each',
      color: Colors.orange,
      icon: Icons.sentiment_neutral,
      gridSize: 8,
      wordCount: 8,
    ),
    'hard': DifficultyInfo(
      title: 'Hard Mode',
      description: '10×10 grid • 10 words • 5+ letters each',
      color: Colors.red,
      icon: Icons.sentiment_very_dissatisfied,
      gridSize: 10,
      wordCount: 10,
    ),
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _checkDailyPuzzleStatus();
    _animationController.forward();
  }

  Future<void> _checkDailyPuzzleStatus() async {
    try {
      final canPlay = await DailyPuzzleManager.canPlayToday();
      final isAllCompleted = await DailyPuzzleManager.isCompletedToday();
      final statusMessage = await DailyPuzzleManager.getStatusMessage();
      
      // Check completion status for each difficulty
      for (String difficulty in _difficultyCompletionStatus.keys) {
        _difficultyCompletionStatus[difficulty] = await DailyPuzzleManager.isDifficultyCompleted(difficulty);
      }
      
      // Set default selection to first uncompleted difficulty
      String? firstUncompleted = _difficultyCompletionStatus.entries
          .firstWhere((entry) => !entry.value, orElse: () => MapEntry('normal', false))
          .key;
      
      setState(() {
        _canPlayToday = canPlay;
        _isAllCompleted = isAllCompleted;
        _statusMessage = statusMessage;
        _selectedDifficulty = firstUncompleted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _canPlayToday = true;
        _isAllCompleted = false;
        _statusMessage = 'Ready to play!';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isAllCompleted
                        ? [
                            Colors.grey.shade600,
                            Colors.grey.shade800,
                          ]
                        : [
                            const Color(0xFF667eea),
                            const Color(0xFF764ba2),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isAllCompleted 
                                ? Icons.check_circle
                                : Icons.calendar_today,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daily Puzzle',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _isLoading ? 'Loading...' : _statusMessage,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _closeDialog,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Status Message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isAllCompleted
                                ? Icons.schedule
                                : Icons.info_outline,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isAllCompleted
                                  ? 'You\'ve completed all difficulties today! Come back tomorrow for fresh challenges.'
                                  : 'Complete all three difficulty modes for today\'s full challenge!',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (_canPlayToday) ...[
                      const SizedBox(height: 24),
                      
                      // Difficulty Selection
                      const Text(
                        'Choose Difficulty',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Difficulty Options
                      Column(
                        children: _difficulties.entries.map((entry) {
                          String difficulty = entry.key;
                          DifficultyInfo info = entry.value;
                          bool isSelected = difficulty == _selectedDifficulty;
                          bool isCompleted = _difficultyCompletionStatus[difficulty] ?? false;
                          bool canPlay = !isCompleted;
                          
                          return _DifficultyOption(
                            difficulty: difficulty,
                            info: info,
                            isSelected: isSelected,
                            isCompleted: isCompleted,
                            enabled: canPlay,
                            onTap: canPlay ? () => setState(() => _selectedDifficulty = difficulty) : null,
                          );
                        }).toList(),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            title: 'Cancel',
                            onPressed: _closeDialog,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            textColor: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            title: _canPlayToday ? 'Start Puzzle' : 'All Complete',
                            onPressed: _canStartPuzzle() ? _startDailyPuzzle : null,
                            backgroundColor: _canStartPuzzle() 
                                ? Colors.white 
                                : Colors.grey.withOpacity(0.5),
                            textColor: _canStartPuzzle() 
                                ? const Color(0xFF667eea) 
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _canStartPuzzle() {
    if (!_canPlayToday) return false;
    return !(_difficultyCompletionStatus[_selectedDifficulty] ?? false);
  }

  void _closeDialog() {
    _animationController.reverse().then((_) => Get.back());
  }

  void _startDailyPuzzle() {
    if (!_canStartPuzzle()) return;
    
    _animationController.reverse().then((_) {
      Get.back();
      Get.to(
        () => GameScreen(
          gameMode: 'daily',
          difficulty: _selectedDifficulty,
          gridSize: _difficulties[_selectedDifficulty]!.gridSize,
        ),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 300),
      );
    });
  }
}

class DifficultyInfo {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final int gridSize;
  final int wordCount;

  DifficultyInfo({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.gridSize,
    required this.wordCount,
  });
}

class _DifficultyOption extends StatefulWidget {
  final String difficulty;
  final DifficultyInfo info;
  final bool isSelected;
  final bool isCompleted;
  final bool enabled;
  final VoidCallback? onTap;

  const _DifficultyOption({
    required this.difficulty,
    required this.info,
    required this.isSelected,
    required this.isCompleted,
    this.enabled = true,
    required this.onTap,
  });

  @override
  State<_DifficultyOption> createState() => _DifficultyOptionState();
}

class _DifficultyOptionState extends State<_DifficultyOption>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
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
            onTapDown: widget.enabled ? (_) => _controller.forward() : null,
            onTapUp: widget.enabled ? (_) {
              _controller.reverse();
              widget.onTap?.call();
            } : null,
            onTapCancel: () => _controller.reverse(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isCompleted
                    ? Colors.green.withOpacity(0.2)
                    : widget.isSelected
                        ? Colors.white.withOpacity(widget.enabled ? 0.2 : 0.1)
                        : Colors.white.withOpacity(widget.enabled ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isCompleted
                      ? Colors.green
                      : widget.isSelected
                          ? widget.info.color.withOpacity(widget.enabled ? 1.0 : 0.5)
                          : Colors.white.withOpacity(widget.enabled ? 0.3 : 0.1),
                  width: (widget.isSelected || widget.isCompleted) ? 2 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: widget.info.color.withOpacity(widget.enabled ? 0.3 : 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.isCompleted
                          ? Colors.green.withOpacity(0.8)
                          : widget.info.color.withOpacity(widget.enabled ? 0.8 : 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.isCompleted 
                          ? Icons.check_circle 
                          : widget.info.icon,
                      color: Colors.white.withOpacity(widget.enabled ? 1.0 : 0.7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.info.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.isSelected
                                ? Colors.white.withOpacity(widget.enabled ? 1.0 : 0.7)
                                : Colors.white.withOpacity(widget.enabled ? 0.7 : 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isCompleted 
                              ? 'Completed! ✓'
                              : widget.info.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isCompleted
                                ? Colors.green.shade200
                                : widget.isSelected
                                    ? Colors.white.withOpacity(widget.enabled ? 0.7 : 0.5)
                                    : Colors.white.withOpacity(widget.enabled ? 0.6 : 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isSelected && !widget.isCompleted)
                    Icon(
                      Icons.radio_button_checked,
                      color: Colors.white.withOpacity(widget.enabled ? 1.0 : 0.5),
                      size: 20,
                    )
                  else if (!widget.isSelected && !widget.isCompleted)
                    Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.white.withOpacity(widget.enabled ? 0.5 : 0.3),
                      size: 20,
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

class _ActionButton extends StatefulWidget {
  final String title;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;

  const _ActionButton({
    required this.title,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

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
            onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
            onTapUp: widget.onPressed != null ? (_) {
              _controller.reverse();
              widget.onPressed!();
            } : null,
            onTapCancel: () => _controller.reverse(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: widget.onPressed != null ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.textColor,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}