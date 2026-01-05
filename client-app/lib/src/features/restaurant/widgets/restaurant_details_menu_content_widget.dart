import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import '../../../core/widgets/menu_item_detail_page.dart';
import '../cubit/restaurant_details_cubit.dart';
import '../cubit/restaurant_details_state.dart';
import 'menu_list_view.dart';

class RestaurantDetailsMenuContentWidget extends StatelessWidget {
  final Map<String, int> cartQuantities;

  const RestaurantDetailsMenuContentWidget({
    Key? key,
    required this.cartQuantities,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RestaurantDetailsCubit>().state;
    if (state is! RestaurantDetailsLoaded) {
      return const SizedBox.shrink();
    }
    final cubit = context.read<RestaurantDetailsCubit>();
    final filteredItems = cubit.getFilteredItems();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filteredItems.isNotEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                AppLocalizations.of(context)!.ourDishes,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      letterSpacing: 0.0,
                      color: ColorApp.textBlack,
                    ),
              )),
        MenuListView(
          items: filteredItems,
          favoriteFoods: state.favoriteFoods,
          selectedItemId: state.selectedItemId,
          cartQuantities: cartQuantities,
          onItemTap: (item) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MenuItemDetailPage(menuItem: item),
              ),
            );
          },
          onFavoriteToggle: (foodId) {
            context.read<RestaurantDetailsCubit>().toggleFavorite(foodId);
          },
        )
      ],
    );
  }
}
