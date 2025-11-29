import 'package:client_app/src/features/restaurant/cubit/category_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/auth/cubit/user_cubit.dart';
import 'package:client_app/src/features/auth/cubit/user_state.dart';
import 'package:client_app/src/features/restaurant/pages/restaurant_details_page.dart';
import 'restaurant_category_page.dart';
import '../cubit/restaurant_cubit.dart';
import '../cubit/restaurant_state.dart';
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
      if (restaurantCubit.state is! RestaurantLoaded) {
        restaurantCubit.loadNearbyRestaurants(radius: 5000);
      }
      if (categoryCubit.state is! CategoryLoaded) {
        categoryCubit.loadCategories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.white,
      body: SafeArea(child: BlocBuilder<UserCubit, UserState>(builder: (context, state) {
        if (state is UserLoading) {
          return _buildLoadingState(context);
        }
        if (state is UserError) {
          return _buildErrorState(
            context,
            state.message,
            onRetry: () => context.read<UserCubit>().fetchProfile(),
          );
        }
        if (state is UserLoaded) {
          return BlocBuilder<RestaurantCubit, RestaurantState>(
            builder: (context, state) {
              if (state is RestaurantLoading) {
                return _buildLoadingState(context);
              }
              if (state is RestaurantError) {
                return _buildErrorState(
                  context,
                  state.message,
                  onRetry: () => context.read<RestaurantCubit>().loadNearbyRestaurants(radius: 5000),
                );
              }
              if (state is RestaurantLoaded) {
                return RefreshIndicator(
                  color: ColorApp.primary,
                  backgroundColor: ColorApp.white,
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
                        RestaurantSuggestionHeader(),
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
                                  child: CircularProgressIndicator(color: ColorApp.primary),
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
          CircularProgressIndicator(color: ColorApp.primary),
          SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.loadingRestaurants),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message, {VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: ColorApp.redColor),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: ColorApp.redColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry ?? () => context.read<RestaurantCubit>().loadNearbyRestaurants(radius: 5000),
            child: Text(AppLocalizations.of(context)!.reload),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorApp.primary,
              foregroundColor: ColorApp.white,
            ),
          ),
        ],
      ),
    );
  }
}
