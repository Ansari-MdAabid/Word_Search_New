// lib/widgets/word_celebration.dart - Fixed version with NO background blur

import 'package:flutter/material.dart';
import 'dart:math';

class WordCelebration extends StatefulWidget {
  final String celebrationWord;
  final String foundWord;
  final int points;
  final VoidCallback onComplete;

  const WordCelebration({
    super.key,
    required this.celebrationWord,
    required this.foundWord,
    required this.points,
    required this.onComplete,
  });

  @override
  State<WordCelebration> createState() => _WordCelebrationState();
}

class _WordCelebrationState extends State<WordCelebration>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _bounceController;
  late AnimationController _shineController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shineAnimation;

  final List<Particle> _particles = [];
  final Random _random = Random();

  // Enhanced celebration words
  static const List<String> _celebrationWords = [
    'AMAZING!', 'EXCELLENT!', 'FANTASTIC!', 'BRILLIANT!', 'AWESOME!', 
    'SUPERB!', 'PERFECT!', 'INCREDIBLE!', 'OUTSTANDING!', 'SPECTACULAR!',
    'WOW!', 'GREAT!', 'FABULOUS!', 'MARVELOUS!', 'WONDERFUL!'
  ];

  @override
  void initState() {
    super.initState();
    
    // Total duration: 2.5 seconds (0.3s entrance + 0.2s wait + 2s exit)
    const Duration totalDuration = Duration(milliseconds: 2500);
    
    _mainController = AnimationController(
      duration: totalDuration,
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _shineController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Scale animation - fast entrance (0-0.3s)
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.15, curve: Curves.elasticOut),
    ));

    // Fade animation - stays opaque for a while, then fades out at the end
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn), // Fade out in last 0.75s
    ));

    // Particle animation - quick burst at start
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.05, 0.4, curve: Curves.easeOut),
    ));

    // Bounce animation
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    // Shine animation
    _shineAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shineController,
      curve: Curves.easeInOut,
    ));

    _generateParticles();
    _startAnimations();
  }

  void _generateParticles() {
    _particles.clear();
    
    // Create particles around the center - using relative positions
    for (int i = 0; i < 20; i++) {
      _particles.add(
        Particle(
          x: 0.4 + (_random.nextDouble() * 0.2), // Keep particles centered
          y: 0.4 + (_random.nextDouble() * 0.2),
          vx: (_random.nextDouble() - 0.5) * 1.2,
          vy: (_random.nextDouble() - 0.5) * 1.2,
          color: _getRandomParticleColor(),
          size: _random.nextDouble() * 4 + 2, // Smaller size range for better compatibility
          rotation: _random.nextDouble() * 2 * pi,
        ),
      );
    }
  }

  Color _getRandomParticleColor() {
    final colors = [
      Colors.yellow.shade400,
      Colors.orange.shade400,
      Colors.red.shade400,
      Colors.pink.shade400,
      Colors.purple.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _startAnimations() {
    // Start main animation
    _mainController.forward();
    
    // Start bounce after a short delay
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        _bounceController.forward();
      }
    });

    // Start shine effect
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _shineController.forward();
      }
    });

    // Complete callback
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _bounceController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _bounceController]),
      builder: (context, child) {
        return DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Roboto'),
          child: Material(
            type: MaterialType.transparency,
            child: IgnorePointer(
              ignoring: false,
              child: Container(
                // Completely transparent background - NO BLUR!
                color: Colors.transparent,
                child: Stack(
                  children: [
                    ..._buildParticlesSafely(),
                    Center(
                      child: Transform.scale(
                        scale: _scaleAnimation.value * (1 + _bounceAnimation.value * 0.3),
                        child: Opacity(
                          opacity: (1 - _fadeAnimation.value).clamp(0.0, 1.0),
                          child: _buildCelebrationContent(),
                        ),
                      ),
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

  Widget _buildCelebrationContent() {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 400;
    
    final fontSize = _getResponsiveFontSize(screenWidth, isSmallScreen);
    final containerPadding = _getResponsivePadding(screenWidth, isSmallScreen);
    final borderRadius = isSmallScreen ? 12.0 : 16.0;

    return Container(
      padding: containerPadding,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700), // Solid Gold
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          // Add shadow for better visibility without blur
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        widget.celebrationWord,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 2,
          shadows: const [
            Shadow(
              color: Colors.black54,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  double _getResponsiveFontSize(double screenWidth, bool isSmallScreen) {
    if (isSmallScreen) return 28;
    if (screenWidth < 600) return 36;
    if (screenWidth < 800) return 44;
    return 48;
  }

  EdgeInsets _getResponsivePadding(double screenWidth, bool isSmallScreen) {
    if (isSmallScreen) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 15);
    }
    if (screenWidth < 600) {
      return const EdgeInsets.symmetric(horizontal: 30, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 50, vertical: 25);
  }

  List<Widget> _buildParticlesSafely() {
    try {
      return _buildParticles();
    } catch (e) {
      return [];
    }
  }

  List<Widget> _buildParticles() {
    if (_particles.isEmpty) return [];
    
    return _particles.map((particle) {
      double progress = _particleAnimation.value.clamp(0.0, 1.0);
      double x = (particle.x + particle.vx * progress * 0.25).clamp(0.0, 1.0);
      double y = (particle.y + particle.vy * progress * 0.25).clamp(0.0, 1.0);
      double opacity = (1.0 - progress).clamp(0.0, 1.0);
      double scale = (1.0 - progress * 0.2).clamp(0.3, 1.0);
      
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          double leftPosition = (x * screenSize.width - particle.size / 2)
              .clamp(0.0, screenSize.width - particle.size);
          double topPosition = (y * screenSize.height - particle.size / 2)
              .clamp(0.0, screenSize.height - particle.size);
          
          return Positioned(
            left: leftPosition,
            top: topPosition,
            child: Transform.rotate(
              angle: particle.rotation + progress * 2,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: particle.size.clamp(2.0, 15.0),
                    height: particle.size.clamp(2.0, 15.0),
                    decoration: BoxDecoration(
                      color: particle.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  static String getRandomCelebrationWord() {
    final random = Random();
    return _celebrationWords[random.nextInt(_celebrationWords.length)];
  }

  // Helper methods for different celebration styles
  static String getCelebrationWordByPoints(int points) {
    if (points >= 100) {
      return 'INCREDIBLE!';
    } else if (points >= 75) {
      return 'FANTASTIC!';
    } else if (points >= 50) {
      return 'EXCELLENT!';
    } else if (points >= 25) {
      return 'GREAT!';
    } else {
      return 'NICE!';
    }
  }
  
  static String getCelebrationWordByLength(int wordLength) {
    if (wordLength >= 8) {
      return 'SPECTACULAR!';
    } else if (wordLength >= 6) {
      return 'AMAZING!';
    } else if (wordLength >= 4) {
      return 'AWESOME!';
    } else {
      return 'GOOD!';
    }
  }
}

class Particle {
  final double x;
  final double y;
  final double vx;
  final double vy;
  final Color color;
  final double size;
  final double rotation;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
  });
}