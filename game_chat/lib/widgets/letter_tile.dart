import 'package:flutter/material.dart';

class LetterTile extends StatelessWidget {
  final String letter;
  final bool isSelected;
  final bool isFound;
  final bool isLastSelected;
  final bool isHintHighlighted;
  final Color? foundColor;

  const LetterTile({
    super.key,
    required this.letter,
    this.isSelected = false,
    this.isFound = false,
    this.isLastSelected = false,
    this.isHintHighlighted = false,
    this.foundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: _getTileColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBorderColor(),
          width: _getBorderWidth(),
        ),
        boxShadow: _getTileShadow(),
      ),
      child: AnimatedScale(
        scale: _getTileScale(),
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: _getTileGradient(),
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: _getFontSize(),
                fontWeight: FontWeight.bold,
                color: _getTextColor(),
                letterSpacing: 1,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(letter),
                  // Hint pulsing animation
                  if (isHintHighlighted)
                    _HintPulseAnimation(
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.yellow,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTileColor() {
    if (isHintHighlighted) return Colors.yellow.shade100;
    if (isFound && foundColor != null) return foundColor!;
    if (isSelected) return Colors.blue.shade200;
    return Colors.white;
  }

  Color _getBorderColor() {
    if (isHintHighlighted) return Colors.yellow.shade600;
    if (isLastSelected) return Colors.deepPurple;
    if (isFound && foundColor != null) return foundColor!;
    if (isSelected) return Colors.blue.shade600;
    return Colors.white;
  }

  double _getBorderWidth() {
    if (isHintHighlighted) return 3;
    if (isLastSelected) return 3;
    return 2;
  }

  Color _getTextColor() {
    if (isHintHighlighted) return Colors.orange.shade800;
    if (isFound && foundColor != null) return Colors.white;
    if (isSelected) return Colors.blue.shade900;
    return Colors.grey.shade800;
  }

  double _getFontSize() {
    if (isHintHighlighted) return 22;
    if (isSelected) return 20;
    return 18;
  }

  double _getTileScale() {
    if (isHintHighlighted) return 1.15;
    if (isSelected) return 1.1;
    return 1.0;
  }

  List<BoxShadow> _getTileShadow() {
    if (isHintHighlighted) {
      return [
        BoxShadow(
          color: Colors.yellow.shade300,
          blurRadius: 8,
          offset: const Offset(0, 3),
          spreadRadius: 2,
        ),
      ];
    }
    if (isSelected) {
      return [
        BoxShadow(
          color: Colors.blue.shade200,
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
    }
    if (isFound && foundColor != null) {
      return [
        BoxShadow(
          color: foundColor!,
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.grey.shade300,
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ];
  }

  LinearGradient? _getTileGradient() {
    if (isHintHighlighted) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.yellow.shade100,
          Colors.yellow.shade200,
        ],
      );
    }
    if (isFound && foundColor != null) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          foundColor!,
          foundColor!,
        ],
      );
    }
    if (isSelected) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.blue.shade200,
          Colors.blue.shade300,
        ],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        Colors.grey.shade50,
      ],
    );
  }
}

// Custom widget for hint pulse animation
class _HintPulseAnimation extends StatefulWidget {
  final Widget child;

  const _HintPulseAnimation({required this.child});

  @override
  State<_HintPulseAnimation> createState() => _HintPulseAnimationState();
}

class _HintPulseAnimationState extends State<_HintPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}