import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late AnimationController _waveController;
  
  late Animation<Color?> _primaryColor;
  late Animation<Color?> _secondaryColor;
  late Animation<double> _particleAnimation;
  late Animation<double> _waveAnimation;
  
  final List<FloatingParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    // Gradient animation controller
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // Particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Wave animation controller
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Color animations for gradient
    _primaryColor = ColorTween(
      begin: const Color(0xFF667eea),
      end: const Color(0xFF764ba2),
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));

    _secondaryColor = ColorTween(
      begin: const Color(0xFF2E3440),
      end: const Color(0xFF3B4252),
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));

    _waveAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    // Initialize floating particles
    _initializeParticles();
  }

  void _initializeParticles() {
    for (int i = 0; i < 15; i++) {
      _particles.add(FloatingParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 4 + 2,
        speed: _random.nextDouble() * 0.5 + 0.2,
        opacity: _random.nextDouble() * 0.6 + 0.2,
        direction: _random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _particleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _gradientController,
        _particleController,
        _waveController,
      ]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: [
                _primaryColor.value ?? const Color(0xFF667eea),
                _secondaryColor.value ?? const Color(0xFF2E3440),
                const Color(0xFF1A1A2E),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Wave pattern overlay
              CustomPaint(
                painter: WavePainter(_waveAnimation.value),
                size: Size.infinite,
              ),
              
              // Floating particles
              CustomPaint(
                painter: ParticlePainter(
                  _particles,
                  _particleAnimation.value,
                ),
                size: Size.infinite,
              ),
              
              // Subtle geometric pattern
              CustomPaint(
                painter: GeometricPatternPainter(_gradientController.value),
                size: Size.infinite,
              ),
              
              // Content overlay with slight blur effect
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.transparent,
                      Colors.black.withOpacity(0.05),
                    ],
                  ),
                ),
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
  }
}

class FloatingParticle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  final double direction;

  FloatingParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.direction,
  });

  void update() {
    x += math.cos(direction) * speed * 0.01;
    y += math.sin(direction) * speed * 0.01;

    // Wrap around screen
    if (x > 1.0) x = 0.0;
    if (x < 0.0) x = 1.0;
    if (y > 1.0) y = 0.0;
    if (y < 0.0) y = 1.0;
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    const waveHeight = 30.0;
    const waveLength = 100.0;

    for (int i = 0; i < 3; i++) {
      path.reset();
      final yOffset = size.height * 0.3 + (i * size.height * 0.2);
      final phase = animationValue * 2 * math.pi + (i * math.pi / 3);

      path.moveTo(0, yOffset);

      for (double x = 0; x <= size.width; x += 2) {
        final y = yOffset +
            waveHeight * math.sin((x / waveLength) * 2 * math.pi + phase);
        path.lineTo(x, y);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ParticlePainter extends CustomPainter {
  final List<FloatingParticle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      particle.update();

      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      final center = Offset(
        particle.x * size.width,
        particle.y * size.height,
      );

      // Draw particle without glow to keep it crisp
      canvas.drawCircle(center, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GeometricPatternPainter extends CustomPainter {
  final double animationValue;

  GeometricPatternPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 80.0;
    final rows = (size.height / spacing).ceil();
    final cols = (size.width / spacing).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = col * spacing;
        final y = row * spacing;
        final offset = animationValue * 2 * math.pi;
        final scale = 0.8 + 0.2 * math.sin(offset + (row + col) * 0.5);

        // Draw subtle hexagon pattern
        final path = Path();
        final centerX = x + spacing / 2;
        final centerY = y + spacing / 2;
        final radius = 15 * scale;

        for (int i = 0; i < 6; i++) {
          final angle = (i * math.pi / 3) + offset * 0.1;
          final pointX = centerX + radius * math.cos(angle);
          final pointY = centerY + radius * math.sin(angle);

          if (i == 0) {
            path.moveTo(pointX, pointY);
          } else {
            path.lineTo(pointX, pointY);
          }
        }
        path.close();

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}