import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/src/features/auth/cubit/user_cubit.dart';
import 'package:frontend/src/features/auth/cubit/user_state.dart';
import '../../auth/services/user_service.dart';
import '../services/autocomplete_service.dart';
import '../widgets/restaurant_search_card.dart';
import '../widgets/autocomplete_dropdown.dart';
import '../cubit/restaurant_cubit.dart';
import 'restuarant_details.dart';

class RestaurantSearchPage extends StatefulWidget {
  final String? initialQuery;

  const RestaurantSearchPage({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<RestaurantSearchPage> createState() => _RestaurantSearchPageState();
}

class _RestaurantSearchPageState extends State<RestaurantSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  final AutocompleteService _autocompleteService = AutocompleteService();
  Timer? _debounce;
  UserLocation? userLocation;
  static const int _maxResults = 50; // safety cap for search results

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _searchController.addListener(_onSearchTextChanged);
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _onSearchChanged(widget.initialQuery!);
    }
  }

  void _onSearchTextChanged() {
    _onSearchChanged(_searchController.text);
  }

  Future<void> _loadUserData() async {
    try {
      final currentLocation = await _userService.getCurrentLocation();

      if (mounted) {
        setState(() {
          userLocation = currentLocation;
        });
      }
    } catch (e) {
      // Error loading user data
    }
  }

  void _onSuggestionSelected(String restaurantName) {
    // When user selects a suggestion, perform a search for that restaurant
    _searchController.text = restaurantName;
    context.read<RestaurantCubit>().searchRestaurants(restaurantName.trim(), maxResults: _maxResults);
  }

  void _onSearchChanged(String q) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (q.trim().isEmpty) {
        // Clear search results
        return;
      }

      // Use BLoC for search
      context.read<RestaurantCubit>().searchRestaurants(q.trim(), maxResults: _maxResults);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userCubit = context.read<UserCubit>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section (same as restaurant suggestion page)
            Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting + location + icons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Greeting and location
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_userService.getGreetingMessage(AppLocalizations.of(context)!)}, ${userCubit.state is UserLoaded ? (userCubit.state as UserLoaded).profile.firstName : AppLocalizations.of(context)!.user}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            if (userLocation != null)
                              Text(
                                '${userLocation!.area}, ${userLocation!.city}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Notification icon with circular border
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.notifications,
                                size: 22,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          // Message icon with circular border
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.message,
                                size: 22,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 18),

                  // Search Bar with Autocomplete
                  AutocompleteDropdown(
                    controller: _searchController,
                    onSearch: _autocompleteService.getRestaurantSuggestions,
                    onSuggestionSelected: _onSuggestionSelected,
                    hintText: 'Rechercher des restaurants, des aliments...',
                  ),
                ],
              ),
            ),

            // Search Results (No promo banner, no categories)
            Expanded(
              child: BlocConsumer<RestaurantCubit, RestaurantState>(
                listener: (context, state) {
                  // Handle any side effects if needed
                },
                builder: (context, state) {
                  return _buildBody(state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(RestaurantState state) {
    if (state is RestaurantSearchLoading) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF006C4A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  color: Color(0xFF006C4A),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recherche en cours...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Recherche de "${_searchController.text}"',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (state is RestaurantError) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Erreur de recherche',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                state.message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (state is RestaurantSearchResults) {
      if (state.restaurants.isEmpty) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant_outlined,
                    size: 56,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Aucun résultat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aucun restaurant trouvé pour',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"${state.searchQuery}"',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF006C4A),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Essayez un terme de recherche différent',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = state.restaurants[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantDetailsPage(restaurant: restaurant),
                ),
              );
            },
            child: RestaurantCard(restaurant: restaurant),
          );
        },
      );
    }

    // Default state (RestaurantInitial or other states)
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF006C4A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search,
                size: 56,
                color: Color(0xFF006C4A),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Rechercher des restaurants',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tapez le nom d\'un restaurant ou d\'un plat pour commencer votre recherche',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }
}
