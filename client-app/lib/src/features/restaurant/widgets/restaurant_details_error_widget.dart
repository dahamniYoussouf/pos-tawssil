import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import '../cubit/restaurant_details_cubit.dart';

class RestaurantDetailsErrorWidget extends StatelessWidget {
  final String message;
  final String restaurantId;

  const RestaurantDetailsErrorWidget({
    Key? key,
    required this.message,
    required this.restaurantId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context
                    .read<RestaurantDetailsCubit>()
                    .loadRestaurantDetails(restaurantId);
              },
              child: Text(AppLocalizations.of(context)!.retryAction),
            ),
          ],
        ),
      ),
    );
  }
}

