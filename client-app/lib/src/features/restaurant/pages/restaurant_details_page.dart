import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:client_app/l10n/app_localizations.dart';
import '../models/restaurant_model.dart';
import '../models/menu_model.dart';
import '../cubit/restaurant_details_cubit.dart';
import '../cubit/restaurant_details_state.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/states/cart_state.dart';
import '../../order/pages/consult_order_page.dart';
import '../widgets/restaurant_details_header.dart';
import '../widgets/premium_banner.dart';
import '../widgets/menu_category_chips.dart';
import '../widgets/floating_cart_button.dart';
import '../widgets/restaurant_details_loading_widget.dart';
import '../widgets/restaurant_details_error_widget.dart';
import '../widgets/restaurant_details_menu_content_widget.dart';
import '../widgets/promo_section_widget.dart';
import '../helpers/cart_data_extractor.dart';
import '../usecases/navigate_to_cart_usecase.dart';

class RestaurantDetailsPage extends StatelessWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailsPage({Key? key, required this.restaurant})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RestaurantDetailsCubit()..loadRestaurantDetails(restaurant.id),
      child: _RestaurantDetailsView(restaurant: restaurant),
    );
  }
}

class _RestaurantDetailsView extends StatefulWidget {
  final RestaurantModel restaurant;

  const _RestaurantDetailsView({required this.restaurant});

  @override
  State<_RestaurantDetailsView> createState() => _RestaurantDetailsViewState();
}

class _RestaurantDetailsViewState extends State<_RestaurantDetailsView> {
  late final ValueNotifier<bool> _showTitleNotifier;

  @override
  void initState() {
    super.initState();
    _showTitleNotifier = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _showTitleNotifier.dispose();
    super.dispose();
  }

  Future<void> _navigateToCart(BuildContext context) async {
    final cartCubit = context.read<CartCubit>();
    final locationCubit = context.read<LocationCubit>();
    final useCase = NavigateToCartUseCase(
      cartCubit: cartCubit,
      locationCubit: locationCubit,
    );
    final result = await useCase.execute(widget.restaurant);
    if (result.isEmptyCart) {
      _showSnackBar(
        context,
        AppLocalizations.of(context)!.cartEmptyMessage,
        Colors.orange,
      );
      return;
    }
    if (result.isSuccess) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConsultOrderPage(
            restaurantName: result.restaurantName!,
            restaurantId: result.restaurantId!,
            deliveryAddress: result.deliveryAddress!,
            restaurantLocation: result.restaurantLocation!,
            deliveryLocation: result.deliveryLocation!,
          ),
        ),
      );
    } else {
      _showSnackBar(
        context,
        AppLocalizations.of(context)!.error,
        Colors.red,
      );
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<RestaurantDetailsCubit, RestaurantDetailsState>(
        builder: (context, state) {
          return BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final cartData = CartDataExtractor.extract(cartState);
              return Stack(
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      if (notification is ScrollUpdateNotification) {
                        final double scrollOffset = notification.metrics.pixels;
                        final bool shouldShowTitle = scrollOffset > 100;
                        if (shouldShowTitle != _showTitleNotifier.value) {
                          _showTitleNotifier.value = shouldShowTitle;
                        }
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      slivers: [
                        ValueListenableBuilder<bool>(
                          valueListenable: _showTitleNotifier,
                          builder: (BuildContext context, bool showTitle, _) {
                            return RestaurantDetailsHeader(
                              imageUrl: widget.restaurant.imageUrl,
                              restaurantName: widget.restaurant.name,
                              cuisineType:
                                  widget.restaurant.description.isNotEmpty
                                      ? widget.restaurant.description
                                      : 'Restaurant',
                              rating: widget.restaurant.rating,
                              onBackPressed: () {
                                context.read<CartCubit>().clearCart();
                                Navigator.pop(context);
                              },
                              onCartPressed: () => _navigateToCart(context),
                              onFavoritePressed: () {},
                              onSearchPressed: () {},
                              showTitle: showTitle,
                            );
                          },
                        ),
                        SliverToBoxAdapter(
                          child: PremiumBanner(),
                        ),
                        if (state is RestaurantDetailsLoaded)
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _CategoryChipsHeaderDelegate(
                              categories: context
                                  .read<RestaurantDetailsCubit>()
                                  .getCategoriesWithoutPromo(),
                              selectedCategoryId: state.selectedCategoryId,
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: _RestaurantDetailsContent(
                            restaurant: widget.restaurant,
                            state: state,
                            cartData: cartData,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!cartData.isEmpty)
                    FloatingCartButton(
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
}

class _RestaurantDetailsContent extends StatelessWidget {
  final RestaurantModel restaurant;
  final RestaurantDetailsState state;
  final CartData cartData;

  const _RestaurantDetailsContent({
    required this.restaurant,
    required this.state,
    required this.cartData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state is RestaurantDetailsLoaded)
          if ((state as RestaurantDetailsLoaded).selectedCategoryId == "all" ||
              (state as RestaurantDetailsLoaded).selectedCategoryId == null)
            _PromoSection(
              state: state as RestaurantDetailsLoaded,
              cartQuantities: cartData.quantities,
            ),
        Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          padding: EdgeInsets.only(
            bottom: !cartData.isEmpty ? 80 : 20,
          ),
          child: _RestaurantDetailsMenuSection(
            state: state,
            restaurantId: restaurant.id,
            cartQuantities: cartData.quantities,
          ),
        ),
      ],
    );
  }
}

class _RestaurantDetailsMenuSection extends StatelessWidget {
  final RestaurantDetailsState state;
  final String restaurantId;
  final Map<String, int> cartQuantities;

  const _RestaurantDetailsMenuSection({
    required this.state,
    required this.restaurantId,
    required this.cartQuantities,
  });

  @override
  Widget build(BuildContext context) {
    if (state is RestaurantDetailsLoading) {
      return const RestaurantDetailsLoadingWidget();
    }
    if (state is RestaurantDetailsError) {
      return RestaurantDetailsErrorWidget(
        message: (state as RestaurantDetailsError).message,
        restaurantId: restaurantId,
      );
    }
    if (state is RestaurantDetailsLoaded) {
      return RestaurantDetailsMenuContentWidget(
        cartQuantities: cartQuantities,
      );
    }
    return const SizedBox.shrink();
  }
}

class _PromoSection extends StatelessWidget {
  final RestaurantDetailsLoaded state;
  final Map<String, int> cartQuantities;

  const _PromoSection({
    required this.state,
    required this.cartQuantities,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RestaurantDetailsCubit>();
    final promoItems = cubit.getPromoItems();
    if (promoItems.isEmpty) {
      return const SizedBox.shrink();
    }
    return PromoSectionWidget(
      promoItems: promoItems,
      cartQuantities: cartQuantities,
      favoriteFoods: state.favoriteFoods,
      onFavoriteToggle: (foodId) {
        context.read<RestaurantDetailsCubit>().toggleFavorite(foodId);
      },
    );
  }
}

class _CategoryChipsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<MenuItemCategory> categories;
  final String? selectedCategoryId;

  _CategoryChipsHeaderDelegate({
    required this.categories,
    required this.selectedCategoryId,
  });

  @override
  double get minExtent => 70;

  @override
  double get maxExtent => 70;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: MenuCategoryChips(
        categories: categories,
        selectedCategoryId: selectedCategoryId,
      ),
    );
  }

  @override
  bool shouldRebuild(_CategoryChipsHeaderDelegate oldDelegate) {
    if (categories.length != oldDelegate.categories.length ||
        selectedCategoryId != oldDelegate.selectedCategoryId) {
      return true;
    }
    for (int i = 0; i < categories.length; i++) {
      if (categories[i].id != oldDelegate.categories[i].id ||
          categories[i].nom != oldDelegate.categories[i].nom) {
        return true;
      }
    }
    return false;
  }
}
