import 'package:client_app/src/core/utils/dependency_injection.dart';
import 'package:client_app/src/features/cart/services/cart_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:client_app/src/features/locations/cubit/location_state.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:client_app/l10n/app_localizations.dart';
import '../models/restaurant_model.dart';
import '../models/menu_model.dart';
import '../cubit/restaurant_details_cubit.dart';
import '../cubit/restaurant_details_state.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/states/cart_state.dart';
import '../../../core/widgets/menu_item_detail_page.dart';
import '../../order/pages/consult_order_page.dart';
import '../widgets/restaurant_details_header.dart';
import '../widgets/restaurant_info_section.dart';
import '../widgets/premium_banner.dart';
import '../widgets/menu_category_chips.dart';
import '../widgets/menu_list_view.dart';
import '../widgets/floating_cart_button.dart';

class RestaurantDetailsPage extends StatelessWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailsPage({Key? key, required this.restaurant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RestaurantDetailsCubit()..loadMenuItems(restaurant.id),
      child: _RestaurantDetailsView(restaurant: restaurant),
    );
  }
}

class _RestaurantDetailsView extends StatelessWidget {
  final RestaurantModel restaurant;

  const _RestaurantDetailsView({required this.restaurant});

  Future<void> _navigateToMenuItemDetail(BuildContext context, MenuModel item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuItemDetailPage(menuItem: item),
      ),
    );

    // Handle result from menu item detail page
    if (result != null && result is Map<String, dynamic>) {
      final menuItem = result['menuItem'] as MenuModel;
      final quantity = result['quantity'] as int? ?? 1;
      final note = result['note'] as String;

      // Add item to cart
      context.read<CartCubit>().addItem(
            menuItemId: menuItem.id,
            menuItemName: menuItem.nom,
            price: menuItem.prix,
            imageUrl: menuItem.imageUrl,
            note: note.isNotEmpty ? note : null,
          );

      // Update quantity if greater than 1
      if (quantity > 1) {
        context.read<CartCubit>().updateQuantity(menuItem.id, quantity);
      }

      // Highlight the item briefly
      context.read<RestaurantDetailsCubit>().setSelectedItemId(menuItem.id);

      // Reset selection after a short delay
      Future.delayed(Duration(milliseconds: 500), () {
        context.read<RestaurantDetailsCubit>().setSelectedItemId(null);
      });
    }
  }

  void _navigateToCart(BuildContext context) async {
    final cartState = context.read<CartCubit>().state;
    if (cartState is CartUpdated && cartState.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cartEmptyMessage),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await context.read<LocationCubit>().loadSavedLocation();
    final locationState = context.read<LocationCubit>().state;
    if (locationState is LocationSuccess) {
      String deliveryAddress = locationState.fullAddress;
      double latitude = locationState.latitude ?? 0.0;
      double longitude = locationState.longitude ?? 0.0;
      LatLng deliveryLocation = LatLng(latitude, longitude);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConsultOrderPage(
            restaurantName: restaurant.name,
            restaurantId: restaurant.id,
            deliveryAddress: deliveryAddress,
            restaurantLocation: LatLng(
              restaurant.lat ?? 0.0,
              restaurant.lng ?? 0.0,
            ),
            deliveryLocation: deliveryLocation,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.error),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<MenuModel> _getFilteredItems(
    RestaurantDetailsLoaded state,
    Map<String, Set<String>> categoryIdMap,
    Map<String, String> displayIdToKey,
  ) {
    if (state.selectedCategoryId == null) {
      return state.menuItems;
    }

    return state.menuItems.where((item) {
      final selectedId = state.selectedCategoryId!;
      // Find the normalized key for the selected display id
      final nameKey = displayIdToKey[selectedId] ?? selectedId.toLowerCase().trim();
      final allowedIds = categoryIdMap[nameKey] ?? <String>{};

      // Accept if item.categoryId is in allowedIds
      if (allowedIds.contains(item.categoryId)) return true;

      // Or accept if category name normalized matches
      final itemCatName = item.category?.nom.toLowerCase().trim() ?? '';
      if (itemCatName.isNotEmpty && itemCatName == nameKey) return true;

      // If backend didn't provide categoryId, accept when selectedId equals the display key
      if (item.categoryId.isEmpty && selectedId.toLowerCase().trim() == nameKey) return true;

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<RestaurantDetailsCubit, RestaurantDetailsState>(
        builder: (context, state) {
          return BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final totalItems = cartState is CartUpdated ? cartState.totalItems : 0;
              final totalPrice = cartState is CartUpdated ? cartState.totalPrice : 0.0;
              final isEmpty = cartState is CartUpdated ? cartState.isEmpty : true;

              // Build cart quantities map
              final cartQuantities = <String, int>{};
              if (cartState is CartUpdated) {
                for (var item in cartState.items.values) {
                  cartQuantities[item.menuItemId] = item.quantity;
                }
              }

              return Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      RestaurantDetailsHeader(
                        imageUrl: restaurant.imageUrl,
                        onBackPressed: () {
                          locator<CartService>().clearCart();
                          Navigator.pop(context);
                        },
                        onCartPressed: () => _navigateToCart(context),
                        onFavoritePressed: () {},
                        onSearchPressed: () {},
                      ),
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RestaurantInfoSection(restaurant: restaurant),
                            PremiumBanner(),
                            SizedBox(height: 12),
                            if (state is RestaurantDetailsLoaded) ...[
                              MenuCategoryChips(
                                categories: state.categories,
                                selectedCategoryId: state.selectedCategoryId,
                                onCategorySelected: (categoryId) {
                                  context.read<RestaurantDetailsCubit>().selectCategory(categoryId);
                                },
                              ),
                            ],
                            Container(
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height * 0.4,
                              ),
                              padding: EdgeInsets.only(bottom: !isEmpty ? 80 : 20),
                              child: _buildMenuContent(
                                context,
                                state,
                                cartQuantities,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!isEmpty)
                    FloatingCartButton(
                      totalItems: totalItems,
                      totalPrice: totalPrice,
                      onTap: () => _navigateToCart(context),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuContent(
    BuildContext context,
    RestaurantDetailsState state,
    Map<String, int> cartQuantities,
  ) {
    if (state is RestaurantDetailsLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state is RestaurantDetailsError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                state.message,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<RestaurantDetailsCubit>().loadMenuItems(restaurant.id);
                },
                child: Text(AppLocalizations.of(context)!.retryAction),
              ),
            ],
          ),
        ),
      );
    }

    if (state is RestaurantDetailsLoaded) {
      final cubit = context.read<RestaurantDetailsCubit>();
      final filteredItems = _getFilteredItems(
        state,
        cubit.categoryIdMap,
        cubit.displayIdToKey,
      );

      return MenuListView(
        items: filteredItems,
        favoriteFoods: state.favoriteFoods,
        selectedItemId: state.selectedItemId,
        cartQuantities: cartQuantities,
        onItemTap: (item) => _navigateToMenuItemDetail(context, item),
        onFavoriteToggle: (foodId) {
          context.read<RestaurantDetailsCubit>().toggleFavorite(foodId);
        },
      );
    }

    return SizedBox.shrink();
  }
}
