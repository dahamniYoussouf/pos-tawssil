import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/restaurant.dart';
import '../models/category.dart';
import '../blocs/restaurant/restaurant_cubit.dart';
import '../widgets/cart_icon.dart';
import 'restuarant_details.dart';

class RestaurantListPage extends StatefulWidget {
  final Category category;
  final List<Restaurant>? allRestaurants;

  const RestaurantListPage({
    Key? key,
    required this.category,
    this.allRestaurants,
  }) : super(key: key);

  @override
  _RestaurantListPageState createState() => _RestaurantListPageState();
}

class _RestaurantListPageState extends State<RestaurantListPage> {
  bool isLoading = true;
  List<Restaurant> restaurants = [];

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  void _loadRestaurants() async {
    setState(() {
      isLoading = true;
    });
    try {
      if (widget.allRestaurants != null && widget.allRestaurants!.isNotEmpty) {
        final filteredRestaurants = widget.allRestaurants!.where((restaurant) {
          final categoryName = widget.category.name.toLowerCase();
          final restaurantName = restaurant.name.toLowerCase();
          final restaurantDesc = restaurant.description.toLowerCase();
          return restaurantName.contains(categoryName) ||
              restaurantDesc.contains(categoryName) ||
              _matchesCategoryKeywords(
                  categoryName, restaurantName, restaurantDesc);
        }).toList();
        setState(() {
          restaurants = filteredRestaurants;
          isLoading = false;
        });
      } else {
        // Simulate API call delay
        await Future.delayed(Duration(seconds: 1));
        // TODO: Replace with actual API/cubit call
        setState(() {
          restaurants = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _matchesCategoryKeywords(
      String categoryName, String restaurantName, String restaurantDesc) {
    switch (categoryName) {
      case 'pizza':
        return restaurantName.contains('pizz') ||
            restaurantDesc.contains('pizz') ||
            restaurantName.contains('italia') ||
            restaurantDesc.contains('italia');
      case 'burger':
        return restaurantName.contains('burger') ||
            restaurantDesc.contains('burger') ||
            restaurantName.contains('fast') ||
            restaurantDesc.contains('fast');
      case 'sushi':
        return restaurantName.contains('sushi') ||
            restaurantDesc.contains('sushi') ||
            restaurantName.contains('japan') ||
            restaurantDesc.contains('japan') ||
            restaurantName.contains('asia') ||
            restaurantDesc.contains('asia');
      case 'desserts':
      case 'dessert':
        return restaurantName.contains('dessert') ||
            restaurantDesc.contains('dessert') ||
            restaurantName.contains('cake') ||
            restaurantDesc.contains('cake') ||
            restaurantName.contains('sweet') ||
            restaurantDesc.contains('sweet') ||
            restaurantName.contains('patiss') ||
            restaurantDesc.contains('patiss');
      case 'drinks':
      case 'drink':
        return restaurantName.contains('drink') ||
            restaurantDesc.contains('drink') ||
            restaurantName.contains('juice') ||
            restaurantDesc.contains('juice') ||
            restaurantName.contains('coffee') ||
            restaurantDesc.contains('coffee') ||
            restaurantName.contains('café') ||
            restaurantDesc.contains('café');
      default:
        return restaurantName.contains(categoryName) ||
            restaurantDesc.contains(categoryName);
    }
  }

  Widget _buildRestaurantItem(Restaurant restaurant) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsPage(restaurant: restaurant),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: restaurant.isPremium ? Color(0xFFFFD700) : Color(0xFFE0E0E0),
            width: restaurant.isPremium ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              spreadRadius: 0,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    restaurant.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF006C4A),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: Icon(Icons.restaurant,
                            size: 32, color: Colors.grey[400]),
                      );
                    },
                  ),
                ),
                if (restaurant.isPremium)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.star, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (restaurant.isPremium)
                        Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.verified,
                            size: 14,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    restaurant.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.access_time,
                          size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        '${restaurant.deliveryMin}-${restaurant.deliveryMax} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.favorite_border,
                color: Color(0xFF1F1F1F),
                size: 22,
              ),
              padding: EdgeInsets.all(8),
              constraints: BoxConstraints(),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ajouté aux favoris'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1F1F1F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.name,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F1F1F),
          ),
        ),
        centerTitle: true,
        actions: [
          CartIcon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Navigation vers le panier')),
              );
            },
            iconColor: Color(0xFF1F1F1F),
            iconSize: 20,
            showBackground: false,
          ),
          IconButton(
            icon: Icon(Icons.search, color: Color(0xFF1F1F1F)),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF006C4A)),
                  SizedBox(height: 16),
                  Text(
                    'Chargement des restaurants...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : restaurants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'Aucun restaurant trouvé près de vous.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRestaurants,
                        child: Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF006C4A),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    return _buildRestaurantItem(restaurants[index]);
                  },
                ),
    );
  }
}
