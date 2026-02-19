import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';

class OnboardingPage extends StatefulWidget {
  final Widget nextPage;
  const OnboardingPage({super.key, required this.nextPage});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _img1Enter;

  late final Animation<double> _img1Exit;
  late final Animation<double> _img2Enter;

  late final Animation<double> _img2Exit;
  late final Animation<double> _pageEnter;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _img1Enter = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );

    _img1Exit = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.55, curve: Curves.easeInOut),
    );
    _img2Enter = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.55, curve: Curves.easeOut),
    );

    _img2Exit = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeInOut),
    );
    _pageEnter = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _controller.forward();
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_navigated) {
        _navigated = true;
        _navigateToApp();
      }
    });
  }

  void _navigateToApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextPage,
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: ColorApp.onboardingBg,
      body: GestureDetector(
        onTap: () {
          if (!_controller.isCompleted) {
            _controller.animateTo(1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn);
          }
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {

            final double img1X;
            if (_img1Exit.value > 0) {
              img1X = screenWidth * _img1Exit.value;
            } else {
              img1X = -screenWidth * (1 - _img1Enter.value);
            }
            final double img1Opacity = _img1Exit.value > 0
                ? (1 - _img1Exit.value).clamp(0.0, 1.0)
                : 1.0;

            final double img2X;
            if (_img2Enter.value < 1.0) {
              img2X = -screenWidth * (1 - _img2Enter.value);
            } else {
              img2X = 0;
            }
            final double img2Y = -screenHeight * _img2Exit.value;

            final double pageY = screenHeight * (1 - _pageEnter.value);

            return Stack(
              children: [
                Container(color: ColorApp.onboardingBg),

                if (img1Opacity > 0)
                  Positioned.fill(
                    child: Opacity(
                      opacity: img1Opacity,
                      child: Transform.translate(
                        offset: Offset(img1X, 0),
                        child: Center(
                          child: Image.asset(
                            MediaRes.splash1,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Image 2 (enters left→center, then exits upward)
                if (_img2Enter.value > 0)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(img2X, img2Y),
                      child: Center(
                        child: Image.asset(
                          MediaRes.splash2,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                // Next page (slides up from bottom)
                if (_pageEnter.value > 0)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(0, pageY),
                      child: widget.nextPage,
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
