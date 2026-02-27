import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    required this.onAnimationComplete,
    super.key,
  });

  final VoidCallback onAnimationComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 30,
      ),
    ]).animate(_controller);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.addListener(() {
      if (!_hasNavigated && _controller.value >= 0.95 && mounted) {
        _hasNavigated = true;
        widget.onAnimationComplete();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const logoPath = 'assets/icon/icone_noir_blanc.png';
    final loginBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;
          final blendProgress = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
          final backgroundColor = Color.lerp(
            const Color(0xFF0057B8),
            loginBackgroundColor,
            Curves.easeOut.transform(blendProgress),
          );

          return ColoredBox(
            color: backgroundColor ?? const Color(0xFF0057B8),
            child: Center(
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Image.asset(
                    logoPath,
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
