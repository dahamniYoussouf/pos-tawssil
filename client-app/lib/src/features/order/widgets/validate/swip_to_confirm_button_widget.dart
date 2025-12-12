import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';

class ValidateOrderActionBar extends StatelessWidget {
  const ValidateOrderActionBar(
      {super.key,
      required this.isLoading,
      required this.onConfirm,
      required this.label,
      required this.swipeButtonKey});
  final bool isLoading;
  final VoidCallback onConfirm;
  final String label;
  final GlobalKey<SwipeToConfirmButtonState> swipeButtonKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: isLoading
            ? Container(
                height: 56,
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: const Center(
                    child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(ColorApp.primary))))
            : SwipeToConfirmButton(
                key: swipeButtonKey, label: label, onConfirm: onConfirm));
  }
}

class SwipeToConfirmButton extends StatefulWidget {
  const SwipeToConfirmButton(
      {super.key, required this.label, required this.onConfirm});
  final String label;
  final VoidCallback onConfirm;

  @override
  SwipeToConfirmButtonState createState() => SwipeToConfirmButtonState();
}

class SwipeToConfirmButtonState extends State<SwipeToConfirmButton> {
  double _dragPosition = 0.0;

  void reset() {
    if (!mounted) return;
    setState(() => _dragPosition = 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final double maxWidth = constraints.maxWidth;
      final double buttonHeight = 56.0;
      final double iconSize = 44.0;
      final double padding = 6.0;
      final double maxDragDistance = maxWidth - iconSize - (padding * 2);
      final double threshold = maxDragDistance * 0.85;
      final double clampedPosition = _dragPosition.clamp(0.0, maxDragDistance);
      return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            setState(() => _dragPosition =
                (_dragPosition + details.delta.dx).clamp(0.0, maxDragDistance));
          },
          onHorizontalDragEnd: (_) {
            if (_dragPosition >= threshold) {
              setState(() => _dragPosition = maxDragDistance);
              widget.onConfirm();
            } else {
              setState(() => _dragPosition = 0.0);
            }
          },
          child: Container(
              height: buttonHeight,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                  color: ColorApp.white,
                  border: Border.all(color: ColorApp.primary),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]),
              child: Stack(clipBehavior: Clip.none, children: <Widget>[
                Positioned.fill(
                    child: Center(
                        child: Text(widget.label,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: ColorApp.primary,
                                letterSpacing: 0.5)))),
                AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    left: padding + clampedPosition,
                    top: padding,
                    child: GestureDetector(
                        onTap: () {
                          if (_dragPosition < threshold) {
                            setState(() => _dragPosition = maxDragDistance);
                            Future<void>.delayed(
                                const Duration(milliseconds: 300), () {
                              if (!mounted) return;
                              widget.onConfirm();
                            });
                          }
                        },
                        child: Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                                color: ColorApp.primary,
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ]),
                            child: const Icon(Icons.arrow_forward_ios,
                                color: Colors.white, size: 20))))
              ])));
    });
  }
}
