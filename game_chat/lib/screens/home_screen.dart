import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'level_screen.dart';
import '../widgets/infinite_mode_popup.dart';
import '../widgets/daily_puzzle_popup.dart';
import 'theme_screen.dart';
import 'settings_screen.dart';
import 'feedback_screen.dart';
import 'about_us_screen.dart';
import '../services/sound_manager.dart';
import '../widgets/animated_background.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late SoundManager _soundManager;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late List<AnimationController> _cardControllers;
  
  bool _musicInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _soundManager = SoundManager();
    _setupAnimations();
    _initializeBackgroundMusic();
  }

  void _setupAnimations() {
    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardControllers = List.generate(8, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 800 + (index * 150)),
        vsync: this,
      );
    });

    _startEntranceAnimation();
  }

  // Initialize background music when home screen loads
  Future<void> _initializeBackgroundMusic() async {
    if (_musicInitialized) return;
    
    try {
      print('HomeScreen: Initializing background music...');
      
      // Initialize SoundManager first
      await _soundManager.init();
      
      // Wait a bit for everything to settle
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Start background music - this should continue throughout the app
      await _soundManager.startBackgroundMusic();
      
      _musicInitialized = true;
      print('HomeScreen: Background music started successfully');
      
    } catch (e) {
      print('HomeScreen: Error starting background music: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle app lifecycle for music
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _soundManager.onAppPause();
        break;
      case AppLifecycleState.resumed:
        _soundManager.onAppResume();
        break;
      case AppLifecycleState.detached:
        _soundManager.onAppPause();
        break;
      default:
        break;
    }
  }

  void _startEntranceAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _fadeController.forward();
      for (int i = 0; i < _cardControllers.length; i++) {
        Future.delayed(Duration(milliseconds: 200 + (i * 100)), () {
          if (mounted) _cardControllers[i].forward();
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _floatController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    // Don't stop background music here - let it continue throughout the app
    // Only stop when user explicitly disables it in settings
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: const SizedBox(height: 35)),
              SliverToBoxAdapter(child: _buildMainPlayButton()),
              SliverToBoxAdapter(child: const SizedBox(height: 35)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: _buildGameModesList(),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _fadeController.value) * -30),
          child: Opacity(
            opacity: _fadeController.value.clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildTitle()),
                  const SizedBox(width: 8),
                  Flexible(child: _buildHeaderButtons(context)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Transform.translate(
            offset: Offset(0, math.sin(_floatController.value * math.pi) * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.white, Colors.cyan.shade300],
                  ).createShader(bounds),
                  child: const Text(
                    'WORD SEARCH',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.cyan.shade300, Colors.purple.shade300],
                  ).createShader(bounds),
                  child: const Text(
                    'EVOLUTION',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderButtons(BuildContext context) {
    // Dynamic sizing based on screen width
    double screenWidth = MediaQuery.of(context).size.width;
    double buttonSize = (screenWidth * 0.11).clamp(32.0, 44.0);
    double spacing = (screenWidth * 0.03).clamp(6.0, 12.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeaderButton(
          icon: Icons.info_outline,
          color: Colors.blue,
          size: buttonSize,
          onTap: () {
            _soundManager.playButtonClick();
            Get.to(() => const AboutUsScreen());
          },
        ),
        SizedBox(width: spacing),
        _buildHeaderButton(
          icon: Icons.feedback_outlined,
          color: Colors.orange,
          size: buttonSize,
          onTap: () {
            _soundManager.playButtonClick();
            Get.to(() => const FeedbackScreen());
          },
        ),
        SizedBox(width: spacing),
        _buildHeaderButton(
          icon: Icons.share_outlined,
          color: Colors.green,
          size: buttonSize,
          onTap: () {
            _soundManager.playButtonClick();
            Share.share('Check out Word Search: Evolution! The ultimate word search experience. #WordSearch #Gaming');
          },
        ),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.45,
        ),
      ),
    );
  }

  Widget _buildMainPlayButton() {
    return _buildAnimatedCard(
      1,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return _PremiumButton(
              onTap: () {
                _soundManager.playButtonClick();
                Get.to(() => const LevelScreen());
              },
              child: Container(
                height: 95,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.cyan.withOpacity(0.4),
                      Colors.purple.withOpacity(0.3),
                      Colors.indigo.withOpacity(0.2),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.4 + 0.3 * _pulseController.value),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.95),
                              Colors.cyan.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'START ADVENTURE',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Continue your word journey',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGameModesList() {
    final modes = [
      _GameMode('Daily Challenge', Icons.today, Colors.blue, 'Fresh puzzle daily', 1),
      _GameMode('Infinite Mode', Icons.all_inclusive, Colors.purple, 'Endless adventures', 2),
      _GameMode('Themes', Icons.palette, Colors.orange, 'Personalize experience', 3),
      _GameMode('Settings', Icons.settings, Colors.green, 'Game preferences', 4),
      // _GameMode('About Us', Icons.info_outline, Colors.cyan, 'Learn about our story', 5),
      // _GameMode('Feedback', Icons.feedback_outlined, Colors.pink, 'Share your thoughts', 6),
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAnimatedCard(
              index + 2,
              child: _buildModeCard(modes[index]),
            ),
          );
        },
        childCount: modes.length,
      ),
    );
  }

  Widget _buildModeCard(_GameMode mode) {
    return _PremiumButton(
      onTap: () {
        _soundManager.playButtonClick();
        switch (mode.id) {
          case 1:
            DailyPuzzle.showPopup();
            break;
          case 2:
            InfiniteMode.showPopup();
            break;
          case 3:
            Get.to(() => const ThemeScreen());
            break;
          case 4:
            Get.to(() => const SettingsScreen());
            break;
          case 5:
            Get.to(() => const AboutUsScreen());
            break;
          case 6:
            Get.to(() => const FeedbackScreen());
            break;
        }
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.15),
              mode.color.withOpacity(0.12),
              Colors.black.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: mode.color.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: mode.color.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      mode.color.withOpacity(0.8),
                      mode.color.withOpacity(0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: mode.color.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  mode.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mode.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.description,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(int index, {required Widget child}) {
    // Add bounds checking to prevent index out of range
    if (index >= _cardControllers.length) {
      return child;
    }

    return AnimatedBuilder(
      animation: _cardControllers[index],
      builder: (context, _) {
        final animation = CurvedAnimation(
          parent: _cardControllers[index],
          curve: Curves.elasticOut,
        );
        
        // Ensure all values are within valid ranges
        final translationOffset = (1 - animation.value.clamp(0.0, 1.0)) * 40;
        final scaleValue = (0.85 + (0.15 * animation.value.clamp(0.0, 1.0))).clamp(0.0, 1.0);
        final opacityValue = animation.value.clamp(0.0, 1.0);
        
        return Transform.translate(
          offset: Offset(0, translationOffset),
          child: Transform.scale(
            scale: scaleValue,
            child: Opacity(
              opacity: opacityValue,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _PremiumButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PremiumButton({required this.child, required this.onTap});

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) {
        return Transform.scale(
          scale: (1.0 - (_pressController.value * 0.03)).clamp(0.0, 1.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                _pressController.forward().then((_) {
                  _pressController.reverse();
                });
                widget.onTap();
              },
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _GameMode {
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final int id;

  _GameMode(this.title, this.icon, this.color, this.description, this.id);
}