import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/states/cart_state.dart';
import 'package:client_app/src/core/res/color_app.dart';

class CustomBottomNavigationBar extends StatelessWidget {
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
        child: Container(
          height: 65,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: AppLocalizations.of(context)!.home,
                index: 0,
              ),
              _buildNavItem(
                context,
                icon: Icons.favorite_border,
                activeIcon: Icons.favorite,
                label: AppLocalizations.of(context)!.favorites,
                index: 1,
              ),
              _buildNavItem(
                context,
                icon: Icons.history,
                activeIcon: Icons.history,
                label: AppLocalizations.of(context)!.history,
                index: 2,
              ),
              _buildCartNavItem(context, index: 3),
              _buildNavItem(
                context,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: AppLocalizations.of(context)!.profile,
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap?.call(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive ? ColorApp.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? ColorApp.primary : Colors.grey[600],
          size: 26,
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
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive ? ColorApp.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            int totalItems = 0;
            if (state is CartUpdated) {
              totalItems = state.totalItems;
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                  color: isActive ? ColorApp.primary : Colors.grey[600],
                  size: 26,
                ),
                if (totalItems > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$totalItems',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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
