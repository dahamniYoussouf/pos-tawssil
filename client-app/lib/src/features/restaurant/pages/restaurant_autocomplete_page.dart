// pages/restaurant_autocomplete_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/restaurant_model.dart';
import '../repositories/restaurant_repository.dart';
import '../../auth/services/user_service.dart';
import '../widgets/restaurant_search_bar.dart';
import 'restaurant_details_page.dart';
import 'package:client_app/src/core/res/color_app.dart';

class RestaurantAutocompletePage extends StatefulWidget {
  const RestaurantAutocompletePage({Key? key}) : super(key: key);

  @override
  State<RestaurantAutocompletePage> createState() =>
      _RestaurantAutocompletePageState();
}

class _RestaurantAutocompletePageState
    extends State<RestaurantAutocompletePage> {
  final TextEditingController _searchController = TextEditingController();
  final RestaurantRepository _restaurantRepository = RestaurantRepository();
  final UserService _userService = UserService();

  List<RestaurantModel> _filteredRestaurants = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounce;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _filteredRestaurants = [];
        _hasSearched = false;
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      // Get user coordinates for nearby search
      final coords = await _userService.getCurrentCoordinates();

      List<RestaurantModel> results = [];

      // Use the unified API with search query
      final result = await _restaurantRepository.getNearbyRestaurants(
        lat: coords?['lat'],
        lng: coords?['lng'],
        radius: 5000,
        q: query.trim(),
        pageSize: 20,
      );

      result.fold(
        (error) {
          // Error occurred, results will remain empty
          setState(() {
            _errorMessage = error;
          });
        },
        (restaurants) {
          results = restaurants;
        },
      );

      // Sort results: premium first, then by rating
      results.sort((a, b) {
        if (a.isPremium && !b.isPremium) return -1;
        if (!a.isPremium && b.isPremium) return 1;
        return b.rating.compareTo(a.rating);
      });

      setState(() {
        _filteredRestaurants = results.take(20).toList(); // Limit to 20 results
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _filteredRestaurants = [];
        _isLoading = false;
        _errorMessage = 'Erreur lors de la recherche';
      });
    }
  }

  void _onSearch(String query) {
    _debounce?.cancel();

    if (query.trim().length < 2) {
      setState(() {
        _filteredRestaurants = [];
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _onRestaurantSelected(RestaurantModel restaurant) {
    // Navigate to restaurant details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantDetailsPage(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1F1F1F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rechercher un restaurant',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F1F1F),
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Column(
        children: [
          // Search Bar Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: RestaurantSearchBar(
              controller: _searchController,
              onSearch: _onSearch,
              hintText: 'Rechercher des restaurants...',
            ),
          ),

          // Results Section
          Expanded(
            child: _buildResultsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_isLoading) {
      return Container(
        color: Color(0xFFF8F9FA),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorApp.primary),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Recherche en cours...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        color: Color(0xFFF8F9FA),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Une erreur s\'est produite',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _performSearch(_searchController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorApp.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: Icon(Icons.refresh, size: 18),
                label: Text(
                  'Réessayer',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return Container(
        color: Color(0xFFF8F9FA),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ColorApp.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_outlined,
                  size: 48,
                  color: ColorApp.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Trouvez votre restaurant idéal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tapez au moins 2 caractères pour commencer\nvotre recherche',
                style: TextStyle(
                  fontSize: 15,
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

    if (_hasSearched && _filteredRestaurants.isEmpty) {
      return Container(
        color: Color(0xFFF8F9FA),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_outlined,
                  size: 48,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Aucun résultat trouvé',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: 'Aucun restaurant trouvé pour "'),
                    TextSpan(
                      text: _searchController.text,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: ColorApp.primary,
                      ),
                    ),
                    TextSpan(text: '"\nEssayez avec d\'autres mots-clés'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results header
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Text(
                  '${_filteredRestaurants.length} restaurant${_filteredRestaurants.length > 1 ? 's' : ''} trouvé${_filteredRestaurants.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorApp.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pertinence',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ColorApp.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Results list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _filteredRestaurants.length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final restaurant = _filteredRestaurants[index];
                return _buildRestaurantTile(restaurant);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantTile(RestaurantModel restaurant) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onRestaurantSelected(restaurant),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant Image
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      restaurant.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: ColorApp.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.restaurant_outlined,
                            color: ColorApp.primary,
                            size: 28,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // Restaurant Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Premium Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF1F1F1F),
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (restaurant.isPremium) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'PREMIUM',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      SizedBox(height: 6),

                      // Description
                      Text(
                        restaurant.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 8),

                      // Address (if available)
                      if (restaurant.address != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                restaurant.address!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                      ],

                      // Rating and Delivery Time
                      Row(
                        children: [
                          // Rating
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Colors.amber.shade600,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  restaurant.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: 12),

                          // Delivery Time
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: ColorApp.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: ColorApp.primary,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  '${restaurant.deliveryMin}-${restaurant.deliveryMax} min',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: ColorApp.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Spacer(),

                          // Arrow Icon
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
