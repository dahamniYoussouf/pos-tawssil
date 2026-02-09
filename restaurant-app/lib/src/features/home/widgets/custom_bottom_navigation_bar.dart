import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/core/res/media_res.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  static const double _barHeight = 60;

  final int currentIndex;
  final Function(int)? onTap;

  const CustomBottomNavigationBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double horizontalPadding = 20;

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
                final double itemWidth = constraints.maxWidth / 5;
                final double indicatorWidth = itemWidth * 0.4;

                return Stack(
                  children: [
                    // Top Indicator Line
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      top: 0,
                      left: itemWidth * currentIndex +
                          (itemWidth - indicatorWidth) / 2,
                      child: Container(
                        height: 4,
                        width: indicatorWidth,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.only(
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
                          iconPath: MediaRes.navOrders,
                          activeIconPath: MediaRes.navOrdersActive,
                          index: 0,
                        ),
                        _buildNavItem(
                          context,
                          iconPath: MediaRes.navHistory,
                          activeIconPath: MediaRes.navHistoryActive,
                          index: 1,
                        ),
                        _buildNavItem(
                          context,
                          iconPath: MediaRes.navAnalytics,
                          activeIconPath: MediaRes.navAnalyticsActive,
                          index: 2,
                        ),
                        _buildNavItem(
                          context,
                          iconPath: MediaRes.navMenu,
                          activeIconPath: MediaRes.navMenuActive,
                          index: 3,
                        ),
                        _buildNavItem(
                          context,
                          iconPath: MediaRes.navProfile,
                          activeIconPath: MediaRes.navProfileActive,
                          index: 4,
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
    required String iconPath,
    required String activeIconPath,
    required int index,
  }) {
    final isActive = currentIndex == index;

    final double iconSize = index == 0 ? 30 : 25;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap?.call(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: _barHeight,
          alignment: Alignment.center,
          child: SvgPicture.asset(
            isActive ? activeIconPath : iconPath,
            width: iconSize,
            height: iconSize,
            colorFilter: ColorFilter.mode(
              isActive ? AppColors.primaryColor : const Color(0xFF6B7280),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
