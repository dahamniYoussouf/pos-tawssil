import 'package:flutter/material.dart';

class DashedVerticalDivider extends StatelessWidget {
  final double height;
  final double dashHeight;
  final double dashSpace;
  final double width;
  final Color color;

  const DashedVerticalDivider({
    super.key,
    this.height = 100,
    this.dashHeight = 5,
    this.dashSpace = 3,
    this.width = 1,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _DashedVerticalDividerPainter(
        dashHeight,
        dashSpace,
        color,
      ),
    );
  }
}

class _DashedVerticalDividerPainter extends CustomPainter {
  final double dashHeight;
  final double dashSpace;
  final Color color;

  _DashedVerticalDividerPainter(
    this.dashHeight,
    this.dashSpace,
    this.color,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
