import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/restaurant/models/homepage_models.dart';
import 'package:client_app/src/features/restaurant/models/restaurant_model.dart';
import 'package:client_app/src/features/restaurant/pages/restaurant_details_page.dart';
import 'package:client_app/src/features/restaurant/widgets/restaurant_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/homepage_cubit.dart';
import '../cubit/homepage_state.dart';

class RestaurantsByCategoryPage extends StatefulWidget {
  final HomeCategoryModel? category;
  final List<RestaurantModel>? initialRestaurants;

  const RestaurantsByCategoryPage({
    Key? key,
    this.category,
    this.initialRestaurants,
  }) : super(key: key);

  @override
  State<RestaurantsByCategoryPage> createState() =>
      _RestaurantsByCategoryPageState();
}

class _RestaurantsByCategoryPageState extends State<RestaurantsByCategoryPage> {
  bool isLoading = false;
  List<RestaurantModel> restaurants = [];

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (widget.initialRestaurants != null &&
          widget.initialRestaurants!.isNotEmpty) {
        // Filter restaurants locally if we have initial data
        if (widget.category != null) {
          // Filter by category name/slug matching
          restaurants = widget.initialRestaurants!.where((restaurant) {
            final categoryName = widget.category!.name.toLowerCase();
            final categorySlug = widget.category!.slug.toLowerCase();
            final restaurantName = restaurant.name.toLowerCase();
            final restaurantDesc = restaurant.description.toLowerCase();

            return restaurantName.contains(categoryName) ||
                restaurantDesc.contains(categoryName) ||
                restaurantName.contains(categorySlug) ||
                restaurantDesc.contains(categorySlug);
          }).toList();
        } else {
          // Show all restaurants
          restaurants = widget.initialRestaurants!;
        }
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      } else if (widget.category != null) {
        // Load from API with category filter
        await context.read<HomepageCubit>().loadHomepage(
          homeCategories: [widget.category!.id],
        );
      } else {
        // Load all restaurants from API
        await context.read<HomepageCubit>().loadHomepage();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading restaurants: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: ColorApp.white,
      appBar: AppBar(
        backgroundColor: ColorApp.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorApp.textBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category?.name ?? localizations.allRestaurants,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: ColorApp.textBlack,
              ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<HomepageCubit, HomepageState>(
        listenWhen: (previous, current) {
          // Only listen when we're loading from API (not using initialRestaurants)
          return widget.initialRestaurants == null ||
              widget.initialRestaurants!.isEmpty;
        },
        listener: (context, state) {
          if (state is HomepageLoaded) {
            if (mounted) {
              setState(() {
                restaurants = state.restaurants;
                isLoading = false;
              });
            }
          } else if (state is HomepageError) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: ColorApp.primary),
              )
            : restaurants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          localizations.noRestaurantNear,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRestaurants,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorApp.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(localizations.tryAgain),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await _loadRestaurants();
                    },
                    color: ColorApp.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        return RestaurantListItem(
                          restaurant: restaurants[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RestaurantDetailsPage(
                                  restaurant: restaurants[index],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
