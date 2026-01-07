import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final isAllSelected =
        state.selectedCategoryId == null || state.selectedCategoryId == "all";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAllSelected)
          MenuListView(
            groupedItems: cubit.getItemsGroupedByCategory(),
            showCategoryHeaders: true,
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
        else
          MenuListView(
            items: cubit.getFilteredItems(),
            showCategoryHeaders: false,
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
          ),
      ],
    );
  }
}
