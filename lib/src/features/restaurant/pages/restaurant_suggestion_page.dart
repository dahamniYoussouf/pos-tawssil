import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/src/features/auth/cubit/user_cubit.dart';
import 'package:frontend/src/features/auth/cubit/user_state.dart';
import 'package:frontend/src/features/restaurant/pages/restaurant_details_page.dart';
import 'restaurant_search_page.dart';
import 'restaurant_category_page.dart';
import '../cubit/restaurant_cubit.dart';
import '../cubit/category_cubit.dart';
import '../widgets/restaurant_suggestion_header.dart';
import '../widgets/promo_banner.dart';
import '../widgets/category_chips_list.dart';
import '../widgets/restaurant_grid.dart';

class RestaurantSuggestionPage extends StatefulWidget {
  const RestaurantSuggestionPage({Key? key}) : super(key: key);

  @override
  State<RestaurantSuggestionPage> createState() => _RestaurantSuggestionPageState();
}

class _RestaurantSuggestionPageState extends State<RestaurantSuggestionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserCubit>().fetchProfile();
      final restaurantCubit = context.read<RestaurantCubit>();
      final categoryCubit = context.read<CategoryCubit>();
      if (restaurantCubit.state is RestaurantInitial) {
        restaurantCubit.loadNearbyRestaurants(radius: 5000);
      }
      if (categoryCubit.state is CategoryInitial) {
        categoryCubit.loadCategories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: BlocBuilder<UserCubit, UserState>(builder: (context, state) {
        if (state is UserLoading) {
          return _buildLoadingState(context);
        }
        if (state is UserError) {
          return _buildErrorState(context, state.message);
        }
        if (state is UserLoaded) {
          return BlocBuilder<RestaurantCubit, RestaurantState>(
            builder: (context, state) {
              if (state is RestaurantLoading) {
                return _buildLoadingState(context);
              }
              if (state is RestaurantError) {
                return _buildErrorState(context, state.message);
              }
              if (state is RestaurantLoaded) {
                return RefreshIndicator(
                  color: Color(0xFF006C4A),
                  backgroundColor: Colors.white,
                  strokeWidth: 3.0,
                  displacement: 40.0,
                  edgeOffset: 0.0,
                  triggerMode: RefreshIndicatorTriggerMode.onEdge,
                  onRefresh: () async {
                    await Future.wait([
                      context.read<RestaurantCubit>().loadNearbyRestaurants(radius: 5000),
                      context.read<CategoryCubit>().loadCategories(),
                    ]);
                  },
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        RestaurantSuggestionHeader(
                          userLocation: state.userLocation,
                          onSearchTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RestaurantSearchPage(),
                              ),
                            );
                          },
                        ),
                        PromoBanner(),
                        BlocBuilder<CategoryCubit, CategoryState>(
                          builder: (context, categoryState) {
                            if (categoryState is CategoryLoaded) {
                              return CategoryChipsList(
                                categories: categoryState.categories,
                                onCategoryTap: (category) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RestaurantListPage(
                                        category: category,
                                        allRestaurants: state.restaurants,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                            if (categoryState is CategoryLoading) {
                              return SizedBox(
                                height: 100,
                                child: Center(
                                  child: CircularProgressIndicator(color: Color(0xFF006C4A)),
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                        SizedBox(height: 20),
                        RestaurantGrid(
                          restaurants: state.restaurants,
                          onRestaurantTap: (restaurant) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RestaurantDetailsPage(restaurant: restaurant),
                              ),
                            );
                          },
                          onReload: () => context.read<RestaurantCubit>().loadNearbyRestaurants(radius: 5000),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return _buildLoadingState(context);
            },
          );
        }
        return _buildLoadingState(context);
      })),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF006C4A)),
          SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.loadingRestaurants),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<RestaurantCubit>().loadNearbyRestaurants(radius: 5000),
            child: Text(AppLocalizations.of(context)!.reload),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF006C4A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
