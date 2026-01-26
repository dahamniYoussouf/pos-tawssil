import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/cart/cubit/cart_cubit.dart';
import 'package:client_app/src/features/cart/states/cart_state.dart';
import 'package:client_app/src/features/restaurant/cubit/homepage_cubit.dart';
import 'package:client_app/src/features/restaurant/cubit/homepage_state.dart';
import 'package:client_app/src/features/restaurant/models/menu_model.dart';
import 'package:client_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:client_app/src/features/restaurant/pages/restaurant_details_page.dart';
import 'package:client_app/src/features/restaurant/widgets/menu_item_card.dart';
import 'package:client_app/src/features/restaurant/widgets/restaurant_suggestion_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartMenuPage extends StatelessWidget {
  const CartMenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.white,
      appBar: AppBar(
        backgroundColor: ColorApp.white,
        title: Text(AppLocalizations.of(context)!.cart),
        centerTitle: true,
      ),
      body: BlocBuilder<HomepageCubit, HomepageState>(
        builder: (BuildContext context, HomepageState homepageState) {
          if (homepageState is HomepageLoading) {
            return const LoadingStateWidget();
          }
          if (homepageState is HomepageError) {
            return ErrorStateWidget(
              message: homepageState.message,
              onRetry: () => context.read<HomepageCubit>().loadHomepage(),
            );
          }
          final List<RestaurantModel> restaurants =
              homepageState is HomepageLoaded
                  ? homepageState.restaurants
                  : <RestaurantModel>[];
          return BlocBuilder<CartCubit, CartState>(
            builder: (BuildContext context, CartState cartState) {
              final List<CartItem> cartItems = _getCartItems(cartState);
              if (cartItems.isEmpty) {
                return const _EmptyCartView();
              }
              final Map<String, RestaurantModel> restaurantById =
                  _mapRestaurantsById(restaurants);
              final List<CartItem> filteredItems =
                  _filterCartItemsByRestaurant(cartItems, restaurantById);
              if (filteredItems.isEmpty) {
                return const _EmptyCartView();
              }
              final List<_RestaurantSectionData> sections =
                  _buildSections(filteredItems, restaurantById);
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: sections.length,
                itemBuilder: (BuildContext context, int index) {
                  return _RestaurantSection(
                    section: sections[index],
                    onMenuItemTap: (MenuModel menuItem) {
                      final RestaurantModel? restaurant =
                          restaurantById[menuItem.restaurantId];
                      if (restaurant == null) {
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                              RestaurantDetailsPage(restaurant: restaurant),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<CartItem> _getCartItems(CartState state) {
    if (state is CartUpdated) {
      return state.items.values.toList(growable: false);
    }
    return <CartItem>[];
  }

  Map<String, RestaurantModel> _mapRestaurantsById(
    List<RestaurantModel> restaurants,
  ) {
    return <String, RestaurantModel>{
      for (final RestaurantModel restaurant in restaurants)
        restaurant.id: restaurant,
    };
  }

  List<CartItem> _filterCartItemsByRestaurant(
    List<CartItem> cartItems,
    Map<String, RestaurantModel> restaurantById,
  ) {
    return cartItems
        .where((CartItem item) =>
            restaurantById.containsKey(item.menuItem.restaurantId))
        .toList(growable: false);
  }

  List<_RestaurantSectionData> _buildSections(
    List<CartItem> cartItems,
    Map<String, RestaurantModel> restaurantById,
  ) {
    final Map<String, List<CartItem>> groupedItems = <String, List<CartItem>>{};
    for (final CartItem item in cartItems) {
      groupedItems.putIfAbsent(item.menuItem.restaurantId, () => <CartItem>[]);
      groupedItems[item.menuItem.restaurantId]!.add(item);
    }
    final List<_RestaurantSectionData> sections = <_RestaurantSectionData>[];
    for (final MapEntry<String, List<CartItem>> entry in groupedItems.entries) {
      final RestaurantModel? restaurant = restaurantById[entry.key];
      if (restaurant == null) {
        continue;
      }
      sections.add(
        _RestaurantSectionData(
          restaurant: restaurant,
          items: entry.value,
        ),
      );
    }
    return sections;
  }
}

class _RestaurantSectionData {
  final RestaurantModel restaurant;
  final List<CartItem> items;

  _RestaurantSectionData({
    required this.restaurant,
    required this.items,
  });
}

class _RestaurantSection extends StatelessWidget {
  final _RestaurantSectionData section;
  final void Function(MenuModel) onMenuItemTap;

  const _RestaurantSection({
    required this.section,
    required this.onMenuItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              section.restaurant.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Column(
            children: section.items
                .map(
                  (CartItem cartItem) => MenuItemCard(
                    item: cartItem.menuItem,
                    isFavorite: cartItem.menuItem.isFavorite,
                    isSelected: false,
                    isInCart: true,
                    quantity: cartItem.quantity,
                    onTap: () => onMenuItemTap(cartItem.menuItem),
                    onFavoriteToggle: () {},
                    rating: cartItem.menuItem.rating,
                    ratingCount: section.restaurant.ratingCount,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.emptyCart,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.addProductsToContinue,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
