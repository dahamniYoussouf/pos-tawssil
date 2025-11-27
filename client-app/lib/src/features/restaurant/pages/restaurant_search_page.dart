import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/restaurant/cubit/restaurant_search_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/features/auth/cubit/user_cubit.dart';
import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:client_app/src/features/locations/cubit/location_state.dart';
import 'package:client_app/src/features/auth/services/user_service.dart';
import '../widgets/restaurant_search_card.dart';
import '../cubit/restaurant_search_cubit.dart';
import 'restaurant_details_page.dart';

class RestaurantSearchPage extends StatefulWidget {
  final String? initialQuery;

  const RestaurantSearchPage({
    Key? key,
    this.initialQuery,
  }) : super(key: key);

  @override
  State<RestaurantSearchPage> createState() => _RestaurantSearchPageState();
}

class _RestaurantSearchPageState extends State<RestaurantSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  Timer? _debounceTimer;
  static const int _maxResults = 50;

  @override
  void initState() {
    super.initState();
    _initializeSearch();
    _loadUserLocation();
  }

  void _initializeSearch() {
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
    _searchController.addListener(_onSearchChanged);
  }

  void _loadUserLocation() {
    context.read<LocationCubit>().loadSavedLocation();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      context.read<RestaurantSearchCubit>().clearSearch();
      return;
    }

    // Debounce search to avoid too many API calls
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      context.read<RestaurantSearchCubit>().clearSearch();
      return;
    }

    // Get location from LocationCubit if available
    final locationState = context.read<LocationCubit>().state;
    double? lat;
    double? lng;
    String? address;

    if (locationState is LocationSuccess) {
      if (locationState.fullAddress.isNotEmpty) {
        address = locationState.fullAddress;
      } else if (locationState.latitude != null && locationState.longitude != null) {
        lat = locationState.latitude;
        lng = locationState.longitude;
      }
    }

    context.read<RestaurantSearchCubit>().searchRestaurants(
          query: query.trim(),
          lat: lat,
          lng: lng,
          address: address,
          pageSize: _maxResults,
        );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(localizations.searchRestaurants),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(localizations),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorApp.primary,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: ColorApp.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: localizations.searchRestaurantPlaceholder,
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<RestaurantSearchCubit, RestaurantSearchState>(
                builder: (context, state) => _buildContent(state, localizations),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: BlocBuilder<LocationCubit, LocationState>(
                  builder: (context, locationState) {
                    final userCubit = context.read<UserCubit>();
                    final firstName = userCubit.profileModel?.firstName ?? localizations.user;
                    final greeting = _userService.getGreetingMessage(localizations);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $firstName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (locationState is LocationSuccess)
                          Text(
                            '${locationState.area}, ${locationState.city}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(RestaurantSearchState state, AppLocalizations localizations) {
    if (state is RestaurantSearchLoading) {
      return _buildLoadingState(state, localizations);
    }

    if (state is RestaurantSearchError) {
      return _buildErrorState(state, localizations);
    }

    if (state is RestaurantSearchResults) {
      if (state.restaurants.isEmpty) {
        return _buildEmptyState(state, localizations);
      }
      return _buildResultsList(state);
    }

    // Initial state
    return _buildInitialState(localizations);
  }

  Widget _buildLoadingState(RestaurantSearchLoading state, AppLocalizations localizations) {
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
            Text(
              localizations.searching,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${localizations.searchingFor} "${state.query}"',
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

  Widget _buildErrorState(RestaurantSearchError state, AppLocalizations localizations) {
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
            Text(
              localizations.searchError,
              style: const TextStyle(
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final query = _searchController.text.trim();
                if (query.isNotEmpty) {
                  _performSearch(query);
                } else {
                  context.read<RestaurantSearchCubit>().clearError();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006C4A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(localizations.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(RestaurantSearchResults state, AppLocalizations localizations) {
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
            Text(
              localizations.noResults,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${localizations.noRestaurantFoundFor} "${state.searchQuery}"',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.tryDifferentSearchTerm,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(RestaurantSearchResults state) {
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

  Widget _buildInitialState(AppLocalizations localizations) {
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
            Text(
              localizations.searchRestaurants,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              localizations.searchRestaurantsHint,
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
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
