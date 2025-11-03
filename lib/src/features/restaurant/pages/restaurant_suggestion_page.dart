import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/src/features/restaurant/pages/restuarant_details.dart';
import '../models/restaurant_model.dart';
import '../models/category_model.dart';
import '../services/restaurant_service.dart';
import '../../auth/services/user_service.dart';
import '../widgets/custom_bottom_navigation_bar.dart';
import 'restaurant_search_screen.dart';
import 'resturant_category_page.dart';

class RestaurantSuggestionPage extends StatefulWidget {
  @override
  _RestaurantSuggestionPageState createState() => _RestaurantSuggestionPageState();
}

class _RestaurantSuggestionPageState extends State<RestaurantSuggestionPage> {
  final RestaurantService _restaurantService = RestaurantService();
  final UserService _userService = UserService();
  String selectedCategory = '';
  List<RestaurantModel> restaurants = [];
  List<CategoryModel> categories = [];
  bool isLoading = true;
  String? username;
  UserLocation? userLocation;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final loadedCategories = await _restaurantService.getCategories();
      // Try to load nearby restaurants from stored coordinates; falls back to all restaurants
      final coords = await _userService.getCurrentCoordinates();
      List<RestaurantModel> loadedRestaurants = await _restaurantService.getNearbyRestaurantsFromStoredLocation(radius: 5000);

      final currentUsername = await _userService.getCurrentUsername();
      final currentLocation = await _userService.getCurrentLocation();

      setState(() {
        categories = loadedCategories;
        restaurants = loadedRestaurants;
        username = currentUsername;
        userLocation = currentLocation;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildCategoryChip(CategoryModel category) {
    bool isSelected = selectedCategory == category.name;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantListPage(
              category: category,
              allRestaurants: restaurants, // Pass the fetched restaurants
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF006C4A) : Colors.white,
          border: Border.all(
            color: Color(0xFF006C4A),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                category.iconPath,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.restaurant, size: 28, color: Colors.grey);
                },
              ),
            ),
            SizedBox(width: 8),
            Text(
              category.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(RestaurantModel restaurant) {
    return Container(
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: restaurant.isPremium ? Color(0xFFFFD700) : Color(0xFF006C4A),
          width: restaurant.isPremium ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Image.network(
                      restaurant.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                            color: Color(0xFF006C4A),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.restaurant,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (restaurant.isPremium)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 0,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 10, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'PREMIUM',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (restaurant.isPremium)
                            Container(
                              margin: EdgeInsets.only(left: 4),
                              child: Icon(Icons.verified, size: 14, color: Color(0xFFFFD700)),
                            ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        restaurant.description,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      SizedBox(width: 2),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.delivery_dining, size: 12, color: Colors.grey[600]),
                      SizedBox(width: 2),
                      Text(
                        '${restaurant.deliveryMin}-${restaurant.deliveryMax} min',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF006C4A)),
                    SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.loadingRestaurants),
                  ],
                ),
              )
            : RefreshIndicator(
                color: Color(0xFF006C4A),
                backgroundColor: Colors.white,
                strokeWidth: 3.0,
                displacement: 40.0,
                edgeOffset: 0.0,
                triggerMode: RefreshIndicatorTriggerMode.onEdge,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Header Section
                      Container(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Greeting + location
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_userService.getGreetingMessage()}, ${username ?? 'khouloud'}',
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
                                    // Cart icon with circular border
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
                            SizedBox(height: 18), // Search Bar - Navigate to Search Page
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RestaurantSearchPage(),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Color(0xFF006C4A),
                                    width: 1.5,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(Icons.search, color: Colors.black, size: 26),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(context)!.searchRestaurantPlaceholder,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Promo banner
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF006C4A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Livraison Gratuite à votre 3ème Commande !',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'après deux commandes, la livraison de votre troisième commande est offerte.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Image.asset(
                              "assets/icons/pizza.png",
                              width: 90,
                              height: 90,
                            ),
                          ],
                        ),
                      ),

                      // Categories
                      if (categories.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.categories,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 15),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: categories.map((category) => _buildCategoryChip(category)).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: 20),

                      // Restaurants Grid
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.newToDiscover(restaurants.length),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 16),
                            if (restaurants.isEmpty)
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.restaurant, size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(AppLocalizations.of(context)!.noRestaurantFound, style: const TextStyle(color: Colors.grey)),
                                      ElevatedButton(
                                      onPressed: _loadData,
                                      child: Text(AppLocalizations.of(context)!.reload),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF006C4A),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.8,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: restaurants.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RestaurantDetailsPage(restaurant: restaurants[index]),
                                        ),
                                      );
                                    },
                                    child: _buildRestaurantCard(restaurants[index]),
                                  );
                                },
                              ),
                            SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(),
    );
  }
}
