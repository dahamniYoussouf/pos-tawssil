import 'package:flutter/material.dart';
import 'package:delivery_app/src/core/res/media_res.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _phase1;

  late final Animation<double> _phase2;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _phase1 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );

    _phase2 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    );

    // Wait 0.5s then start the animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _controller.forward();
    });

    // When fully done, navigate
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishOnboarding();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          _controller.animateTo(1.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeIn);
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final double splash1StartX = screenWidth;
            final double splash1PeekX = screenWidth * 0.7;
            final double splash1EndX = -screenWidth;

            final double splash1X;
            if (_phase2.value > 0) {
              splash1X =
                  splash1PeekX + (splash1EndX - splash1PeekX) * _phase2.value;
            } else {
              splash1X = splash1StartX +
                  (splash1PeekX - splash1StartX) * _phase1.value;
            }

            final double splash2X = screenWidth * (1.0 - _phase2.value);

            return Stack(
              children: [
                Transform.translate(
                  offset: Offset(splash2X, 0),
                  child: SizedBox(
                    width: screenWidth,
                    height: screenHeight,
                    child: Image.asset(
                      MediaRes.splash2,
                      fit: BoxFit.contain,
                      width: screenWidth,
                      height: screenHeight,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(splash1X, 0),
                  child: SizedBox(
                    width: screenWidth,
                    height: screenHeight,
                    child: Image.asset(
                      MediaRes.splash1,
                      fit: BoxFit.contain,
                      width: screenWidth,
                      height: screenHeight,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
