import 'package:flutter/material.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';

class OrderCardShimmer extends StatefulWidget {
  const OrderCardShimmer({super.key});

  @override
  State<OrderCardShimmer> createState() => _OrderCardShimmerState();
}

class _OrderCardShimmerState extends State<OrderCardShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
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
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.borderLight, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(180, 22),
                const SizedBox(height: 8),
                _box(130, 14),
                const SizedBox(height: 20),
                _box(80, 16),
                const SizedBox(height: 12),
                _itemRow(),
                const SizedBox(height: 8),
                _itemRow(),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(70, 12),
                        const SizedBox(height: 4),
                        _box(90, 16),
                      ],
                    ),
                    const Spacer(),
                    _box(80, 36, radius: 20),
                    const SizedBox(width: 8),
                    _box(80, 36, radius: 20),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _itemRow() {
    return Row(
      children: [
        Expanded(child: _box(140, 15)),
        const SizedBox(width: 12),
        _box(50, 15),
      ],
    );
  }

  Widget _box(double width, double height, {double radius = 6}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.greyLight.withValues(alpha: _animation.value),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
