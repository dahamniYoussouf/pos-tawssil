import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/restaurant/cubit/restaurant_search_state.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';

class SearchEmptyWidget extends StatelessWidget {
  final RestaurantSearchResults state;

  const SearchEmptyWidget({
    Key? key,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ColorApp.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorApp.greyLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_outlined,
                size: 56,
                color: ColorApp.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localizations.noResults,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ColorApp.textBlack,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              '${localizations.noRestaurantFoundFor} "${state.searchQuery}"',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: ColorApp.textGrey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.tryDifferentSearchTerm,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: ColorApp.textGrey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

