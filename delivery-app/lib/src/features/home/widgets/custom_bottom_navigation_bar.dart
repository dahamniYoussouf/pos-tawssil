import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  static const double _barHeight = 72;

  final int currentIndex;
  final Function(int)? onTap;

  const CustomBottomNavigationBar({
    Key? key,
    this.currentIndex = 0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double horizontalPadding = 30; // Side spacing as requested
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: SizedBox(
            height: _barHeight,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double itemWidth = constraints.maxWidth / 4;
                final double indicatorWidth =
                    itemWidth * 0.7; // Wider indicator
                return Stack(
                  children: [
                    // Top Indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      top: 0,
                      left: itemWidth * currentIndex +
                          (itemWidth - indicatorWidth) / 2,
                      child: Container(
                        height: 5, // Thinner line
                        width: indicatorWidth,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    // Navigation Items
                    Row(
                      children: [
                        _buildNavItem(
                          context,
                          icon: Icons.map_outlined,
                          index: 0,
                        ),
                        _buildNavItem(
                          context,
                          iconPath: MediaRes.historyNavBarIcon,
                          index: 1,
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.history,
                          index: 2,
                        ),
                        _buildNavItem(
                          context,
                          icon: Icons.person_outline,
                          index: 3,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    IconData? icon,
    String? iconPath,
    required int index,
  }) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap?.call(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: _barHeight,
          alignment: Alignment.center,
          child: iconPath != null
              ? SvgPicture.asset(
                  iconPath,
                  width: 30,
                  height: 30,
                  colorFilter: ColorFilter.mode(
                    isActive ? AppColors.primaryColor : const Color(0xFF6B7280),
                    BlendMode.srcIn,
                  ),
                )
              : Icon(
                  icon,
                  size: 30, // Slightly larger icons
                  color: isActive
                      ? AppColors.primaryColor
                      : const Color(0xFF6B7280), // Matching grey in pic
                ),
        ),
      ),
    );
  }
}
