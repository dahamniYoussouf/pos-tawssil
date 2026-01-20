import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/states/cart_state.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  static const double _barHeight = 72;
  static const double _itemSize = 48;
  static const double _iconSize = 26;
  static const double _indicatorHeight = 6;
  static const double _indicatorWidth = 79;
  static const double _horizontalPadding = 20;
  static const double _verticalPadding = 14;
  static const double _badgeOffset = -6;
  static const double _badgePadding = 4;
  static const double _badgeMinSize = 18;
  static const double _badgeFontSize = 10;
  final int currentIndex;
  final Function(int)? onTap;

  const CustomBottomNavigationBar({
    Key? key,
    this.currentIndex = 0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: _barHeight,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double itemWidth = constraints.maxWidth / 5;
              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    left: itemWidth * currentIndex +
                        (itemWidth -
                                _indicatorWidth -
                                centerOffset(currentIndex)) /
                            2,
                    child: Container(
                      height: _indicatorHeight,
                      width: _indicatorWidth,
                      decoration: BoxDecoration(
                        color: ColorApp.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _horizontalPadding,
                      vertical: _verticalPadding,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNavItem(
                          context,
                          iconPath: MediaRes.homeNavBarIcon,
                          index: 0,
                        ),
                        _buildNavItem(
                          context,
                          iconPath: MediaRes.searchNavBarIcon,
                          index: 1,
                        ),
                        _buildNavItem(
                          context,
                          iconPath: MediaRes.historyNavBarIcon,
                          index: 2,
                        ),
                        _buildCartNavItem(context, index: 3),
                        _buildNavItem(
                          context,
                          iconPath: MediaRes.profileNavBarIcon,
                          index: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  double centerOffset(int index) {
    return index == 0
        ? -7
        : index == 1
            ? 1
            : index == 2
                ? 5
                : index == 3
                    ? 5
                    : index == 4
                        ? 10
                        : 0;
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String iconPath,
    required int index,
  }) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap?.call(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _itemSize,
        height: _itemSize,
        alignment: Alignment.center,
        child: SvgPicture.asset(
          iconPath,
          width: _iconSize,
          height: _iconSize,
          colorFilter: ColorFilter.mode(
            isActive ? ColorApp.primary : ColorApp.navBarIconColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildCartNavItem(BuildContext context, {required int index}) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap?.call(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _itemSize,
        height: _itemSize,
        alignment: Alignment.center,
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            int totalItems = 0;
            if (state is CartUpdated) {
              totalItems = state.totalItems;
            }
            return Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  MediaRes.cartNavBarIcon,
                  width: _iconSize,
                  height: _iconSize,
                  colorFilter: ColorFilter.mode(
                    isActive ? ColorApp.primary : ColorApp.navBarIconColor,
                    BlendMode.srcIn,
                  ),
                ),
                if (totalItems > 0)
                  Positioned(
                    right: _badgeOffset,
                    top: _badgeOffset,
                    child: Container(
                      padding: const EdgeInsets.all(_badgePadding),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: _badgeMinSize,
                        minHeight: _badgeMinSize,
                      ),
                      child: Text(
                        '$totalItems',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _badgeFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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
