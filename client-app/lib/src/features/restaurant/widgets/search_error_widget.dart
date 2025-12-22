import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/restaurant/cubit/restaurant_search_state.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import '../cubit/restaurant_search_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchErrorWidget extends StatelessWidget {
  final RestaurantSearchError state;
  final String currentQuery;

  const SearchErrorWidget({
    Key? key,
    required this.state,
    required this.currentQuery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorApp.redColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: ColorApp.redColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localizations.searchError,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ColorApp.textBlack,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              state.message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: ColorApp.textGrey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (currentQuery.isNotEmpty) {
                  context.read<RestaurantSearchCubit>().searchRestaurants(
                        query: currentQuery,
                        pageSize: 50,
                      );
                } else {
                  context.read<RestaurantSearchCubit>().clearError();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorApp.primary,
                foregroundColor: ColorApp.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                localizations.retry,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ColorApp.white,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

