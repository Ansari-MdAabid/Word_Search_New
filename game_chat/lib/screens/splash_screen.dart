// lib/screens/enhanced_splash_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/sound_manager.dart';
import 'home_screen.dart';
import 'dart:math' as math;

class EnhancedSplashScreen extends StatefulWidget {
  const EnhancedSplashScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedSplashScreen> createState() => _EnhancedSplashScreenState();
}

class _EnhancedSplashScreenState extends State<EnhancedSplashScreen> 
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _mainController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  late AnimationController _buttonController;
  
  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _titleSlide;
  late Animation<double> _subtitleSlide;
  late Animation<double> _particleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _buttonFade;
  late Animation<double> _progressAnimation;
  
  // State variables
  String _status = 'Preparing your adventure...';
  bool _showContinueButton = false;
  bool _userHasInteracted = false;
  double _loadingProgress = 0.0;
  final SoundManager _soundManager = SoundManager();
  
  // Enhanced color scheme
  static const Color primaryColor = Color(0xFF0F172A);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color secondaryColor = Color(0xFF8B5CF6);
  static const Color highlightColor = Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEnhancedSplashSequence();
  }

  void _initializeAnimations() {
    // Main sequence controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );
    
    // Logo animation with more sophisticated timing
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    _logoScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController, 
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    
    _logoRotation = Tween<double>(begin: 2 * math.pi, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController, 
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Text animations with staggered timing
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _titleSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController, 
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    
    _subtitleSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController, 
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // Particle system
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    // Glow effect
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Button animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Progress animation
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startEnhancedSplashSequence() async {
    try {
      // Start the main sequence
      _mainController.forward();
      
      // Phase 1: Logo entrance (0-800ms)
      await Future.delayed(const Duration(milliseconds: 200));
      _logoController.forward();
      
      // Phase 2: Text entrance (400-1200ms) 
      await Future.delayed(const Duration(milliseconds: 400));
      _textController.forward();
      setState(() => _status = 'Loading magical words...');
      _updateProgress(0.2);
      
      // Phase 3: Simulated loading with progress
      await _simulateLoading();
      
      // Phase 4: Final preparations
      setState(() => _status = 'Almost ready...');
      _updateProgress(0.9);
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Phase 5: Ready to play
      setState(() => _status = 'Ready to embark on your word journey!');
      _updateProgress(1.0);
      
      // Check platform and show appropriate UI
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() => _showContinueButton = true);
        _buttonController.forward();
      } else {
        await Future.delayed(const Duration(milliseconds: 1200));
        _navigateToHome();
      }
      
    } catch (e) {
      print('Enhanced splash sequence error: $e');
      setState(() {
        _status = 'Ready to play!';
        _showContinueButton = true;
      });
      _buttonController.forward();
    }
  }

  // Updated simulate loading method using Map entries (most compatible)
  Future<void> _simulateLoading() async {
    final loadingSteps = <String, double>{
      'Initializing game engine...': 0.3,
      'Loading word databases...': 0.5,
      'Preparing sound effects...': 0.7,
      'Setting up game modes...': 0.8,
      'Finalizing components...': 0.9,
    };

    for (var entry in loadingSteps.entries) {
      setState(() => _status = entry.key);
      _updateProgress(entry.value);
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  void _updateProgress(double progress) {
    setState(() => _loadingProgress = progress);
  }

  Future<void> _handleUserInteraction() async {
    if (_userHasInteracted) return;
    
    _userHasInteracted = true;
    
    try {
      setState(() => _status = 'Initializing audio system...');
      
      // Initialize audio - ensure it's ready
      await _soundManager.init();
      await _soundManager.playButtonClick();
      
      setState(() => _status = 'Welcome aboard!');
      await Future.delayed(const Duration(milliseconds: 800));
      
      _navigateToHome();
      
    } catch (e) {
      print('Audio initialization error: $e');
      setState(() => _status = 'Starting without audio...');
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Get.offAll(
        () => const HomeScreen(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 1000),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              Color(0xFF1E293B),
              Color(0xFF334155),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Enhanced animated background
            _buildEnhancedBackground(),
            
            SafeArea(
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      
                      // Enhanced logo with glow effect
                      _buildEnhancedLogo(),
                      
                      const SizedBox(height: 50),
                      
                      // Enhanced title section
                      _buildEnhancedTitle(),
                      
                      const SizedBox(height: 40),
                      
                      // Enhanced progress section
                      _buildProgressSection(),
                      
                      const Spacer(flex: 2),
                      
                      // Continue button with better styling
                      if (_showContinueButton) _buildEnhancedButton(),
                      
                      const SizedBox(height: 20),
                      
                      // Enhanced app info
                      _buildEnhancedAppInfo(),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom logos section
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomLogos(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomLogos() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Image.asset(
              'assets/sounds/darshan_logo.jpeg',
              height: 50,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Image.asset(
              'assets/sounds/ased_logo.jpeg',
              height: 50,
              fit: BoxFit.contain,
              alignment: Alignment.centerRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedBackground() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: EnhancedParticlePainter(_particleAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildEnhancedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _glowController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Transform.rotate(
            angle: _logoRotation.value,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.95),
                    highlightColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: secondaryColor.withOpacity(0.2 * _glowAnimation.value),
                    blurRadius: 60,
                    spreadRadius: 15,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Animated background pattern
                  Positioned.fill(
                    child: CustomPaint(
                      painter: LogoBackgroundPainter(_glowAnimation.value),
                    ),
                  ),
                  // Main logo image with animation
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/sounds/app_logo.jpeg',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
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

  Widget _buildEnhancedTitle() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Column(
          children: [
            Transform.translate(
              offset: Offset(0, _titleSlide.value),
              child: Opacity(
                opacity: _textController.value.clamp(0.0, 1.0),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      highlightColor,
                      Colors.white,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'WORD SEARCH',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 4,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Transform.translate(
              offset: Offset(0, _subtitleSlide.value),
              child: Opacity(
                opacity: (_textController.value - 0.3).clamp(0.0, 1.0),
                child: Text(
                  'EVOLUTION',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: highlightColor,
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        // Status text with better styling
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: Text(
            _status,
            key: ValueKey(_status),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 25),
        
        // Enhanced progress bar
        Container(
          width: 250,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Progress fill
                  Container(
                    width: 250 * _loadingProgress,
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor, secondaryColor, highlightColor],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  // Animated shimmer effect
                  if (_loadingProgress < 1.0)
                    Positioned(
                      left: (250 * _loadingProgress) - 20,
                      child: Container(
                        width: 40,
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 15),
        
        // Progress percentage
        Text(
          '${(_loadingProgress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 14,
            color: highlightColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedButton() {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _buttonFade,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
            ),
            child: GestureDetector(
              onTap: _handleUserInteraction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.rocket_launch_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      'START ADVENTURE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
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

  Widget _buildEnhancedAppInfo() {
    return Column(
      children: [
        Text(
          'Discover hidden words across multiple dimensions',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     _buildFeatureChip('∞ Levels'),
        //     const SizedBox(width: 12),
        //     _buildFeatureChip('🎯 Themes'),
        //     const SizedBox(width: 12),
        //     _buildFeatureChip('🏆 Achievements'),
        //   ],
        // ),
      ],
    );
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlightColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Enhanced particle painter
class EnhancedParticlePainter extends CustomPainter {
  final double animation;
  
  EnhancedParticlePainter(this.animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Multiple layers of particles
    for (int layer = 0; layer < 3; layer++) {
      final layerOpacity = 0.15 - (layer * 0.05);
      final particleCount = 20 - (layer * 5);
      final speed = 1.0 + (layer * 0.5);
      
      for (int i = 0; i < particleCount; i++) {
        final progress = (animation * speed + i * 0.1) % 1.0;
        final x = (size.width * 0.1) + (size.width * 0.8) * ((i * 0.618034) % 1.0);
        final y = size.height * progress;
        final radius = 1.5 + (i % 4) * 0.5;
        
        // Gradient colors for particles
        final colors = [
          const Color(0xFF3B82F6),
          const Color(0xFF8B5CF6), 
          const Color(0xFF06B6D4),
        ];
        
        paint.color = colors[i % colors.length].withOpacity(
          layerOpacity * (1.0 - progress) * (0.5 + 0.5 * math.sin(animation * 2 * math.pi + i))
        );
        
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(EnhancedParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

// Logo background pattern painter
class LogoBackgroundPainter extends CustomPainter {
  final double animation;
  
  LogoBackgroundPainter(this.animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF3B82F6).withOpacity(0.05 * animation);
    
    // Animated grid pattern
    const gridSize = 12.0;
    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        final distance = math.sqrt(math.pow(x - size.width/2, 2) + math.pow(y - size.height/2, 2));
        final normalizedDistance = distance / (size.width * 0.5);
        final alpha = (1.0 - normalizedDistance) * animation;
        
        if (alpha > 0 && (x / gridSize + y / gridSize) % 2 == 0) {
          paint.color = const Color(0xFF06B6D4).withOpacity(0.1 * alpha);
          canvas.drawCircle(
            Offset(x + gridSize/2, y + gridSize/2), 
            2 * animation, 
            paint
          );
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(LogoBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}