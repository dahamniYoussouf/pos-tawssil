import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:frontend/l10n/app_localizations.dart';
import '../models/restaurant_model.dart';
import '../models/menu_model.dart';
import '../services/restaurant_service.dart';
import '../../cart/services/cart_service.dart';
import '../../cart/widgets/cart_icon.dart';
import '../../../core/widgets/menu_item_detail_page.dart';
import '../../../core/widgets/Consulter_le_panier.dart';

class RestaurantDetailsPage extends StatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantDetailsPage({Key? key, required this.restaurant}) : super(key: key);

  @override
  _RestaurantDetailsPageState createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  final RestaurantService _service = RestaurantService();
  final CartService _cartService = CartService();
  Set<String> favoriteFoods = {};
  List<MenuModel> _menuItems = [];
  List<MenuItemCategory> _categories = [];
  // Map from normalized category name key -> set of original category ids seen
  Map<String, Set<String>> _categoryIdMap = {};
  // Map from display id (used in _categories list) -> normalized name key
  Map<String, String> _displayIdToKey = {};
  String? _selectedCategoryId;
  bool _loading = true;
  String? _error;

  String? _selectedItemId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _service.getMenuItems(restaurantId: widget.restaurant.id);

      setState(() {
        _menuItems = items;
        // Build a normalized map of categories to avoid duplicates caused by
        // varying casing or multiple category ids with the same display name.
        _categoryIdMap.clear();
        _displayIdToKey.clear();

        final Map<String, MenuItemCategory> displayMap = {};

        for (var item in items) {
          final cat = item.category;
          final cid = (item.categoryId.isNotEmpty ? item.categoryId : (cat?.id ?? '')).toString();
          final name = (cat?.nom ?? '').toString();

          final nameKey = name.isNotEmpty ? name.toLowerCase().trim() : cid.toLowerCase().trim();

          // Add underlying id to set
          _categoryIdMap.putIfAbsent(nameKey, () => <String>{});
          if (cid.isNotEmpty) _categoryIdMap[nameKey]!.add(cid);

          // Build display category entry (first encountered)
          if (!displayMap.containsKey(nameKey)) {
            final displayId = cid.isNotEmpty ? cid : nameKey;
            final displayName = name.isNotEmpty ? name : nameKey;
            displayMap[nameKey] = MenuItemCategory(id: displayId, nom: displayName);
            _displayIdToKey[displayId] = nameKey;
          } else {
            // ensure mapping exists for this cid as well (if different id)
            final existing = displayMap[nameKey]!;
            final existingId = existing.id;
            // Map the current cid to the same nameKey so filtering works
            if (cid.isNotEmpty) _displayIdToKey[cid] = nameKey;
            _displayIdToKey[existingId] = nameKey;
          }
        }

        _categories = displayMap.values.toList();

        if (_categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load menu items. Please try again.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void toggleFavorite(String foodId) {
    setState(() {
      if (favoriteFoods.contains(foodId)) {
        favoriteFoods.remove(foodId);
      } else {
        favoriteFoods.add(foodId);
      }
    });
  }

  // Navigate to menu item detail page
  Future<void> _navigateToMenuItemDetail(MenuModel item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuItemDetailPage(menuItem: item),
      ),
    );

    // Handle result from menu item detail page
    if (result != null && result is Map<String, dynamic>) {
      final menuItem = result['menuItem'] as MenuModel;
      final quantity = result['quantity'] as int;
      final note = result['note'] as String;

      _cartService.addItem(
        menuItemId: menuItem.id,
        menuItemName: menuItem.nom,
        price: menuItem.prix,
        imageUrl: menuItem.imageUrl,
        quantity: quantity,
        note: note.isNotEmpty ? note : null,
      );

      setState(() {
        // Highlight the item briefly
        _selectedItemId = menuItem.id;
      });

      // Reset selection after a short delay
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _selectedItemId = null;
          });
        }
      });
    }
  }

  int get _totalItems {
    return _cartService.totalItems;
  }

  double get _totalPrice {
    return _cartService.totalPrice;
  }

  void _navigateToCart() {
    if (_cartService.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cartEmptyMessage),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsulterLePanier(
          restaurantName: widget.restaurant.name,
          restaurantId: widget.restaurant.id,
          deliveryAddress: 'Baraki, Sidi Moussa', // TODO: Get from user location service
          restaurantLocation: LatLng(
            widget.restaurant.lat ?? 0.0,
            widget.restaurant.lng ?? 0.0,
          ),
          deliveryLocation: const LatLng(36.7538, 3.0588), // TODO: Get from user location
        ),
      ),
    );
  }

  Widget _buildFoodItem(MenuModel item) {
    bool isFavorite = favoriteFoods.contains(item.id);
    bool isSelected = _selectedItemId == item.id;
    int quantity = _cartService.getQuantity(item.id);
    bool isInCart = quantity > 0;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _navigateToMenuItemDetail(item),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: isSelected || isInCart
                  ? Border.all(
                      color: Color(0xFF006C4A),
                      width: 2,
                    )
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food Image with Add Button overlay
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 60,
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.restaurant, size: 30, color: Colors.grey[400]),
                            );
                          },
                        ),
                      ),
                    ),

                    // Add button overlay at bottom-right corner of image
                    Positioned(
                      bottom: -3,
                      right: -3,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: item.disponible ? Color(0xFF006C4A) : Colors.grey[300],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: isInCart
                              ? Text(
                                  '$quantity',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 14,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(width: 12),

                // Food Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        item.nom,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),

                      SizedBox(height: 4),

                      // Description
                      if (item.description != null && item.description!.isNotEmpty)
                        Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      SizedBox(height: 6),

                      // Price
                      Text(
                        item.priceFormatted,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),

                      // Additional info
                      if (!item.disponible) ...[
                        SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)!.notAvailable,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (isInCart) ...[
                        SizedBox(height: 2),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFF006C4A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.quantityInCart(quantity),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF006C4A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(width: 8),

                // Heart icon on the right
                GestureDetector(
                  onTap: () => toggleFavorite(item.id),
                  child: Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.grey[400],
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Separator line
        Container(
          height: 1,
          color: Colors.grey[200],
          margin: EdgeInsets.only(left: 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: Colors.white,
                leading: Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  CartIcon(
                    onPressed: _navigateToCart,
                    iconColor: Colors.black,
                    iconSize: 20,
                    showBackground: true,
                  ),
                  Container(
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.favorite_outline, color: Colors.black, size: 20),
                      onPressed: () {},
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.search, color: Colors.black, size: 20),
                      onPressed: () {},
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.network(
                    widget.restaurant.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.restaurant, size: 80, color: Colors.grey[400]),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Info
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.restaurant.name,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.amber),
                                  SizedBox(width: 2),
                                  Text(
                                    widget.restaurant.rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Poulet, Syrian Food',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  AppLocalizations.of(context)!.deliveryFeeLabel,
                                  '200 DA',
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _buildInfoCard(
                                  AppLocalizations.of(context)!.deliveryTimeLabel,
                                  '${widget.restaurant.deliveryMin}-${widget.restaurant.deliveryMax} min',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Premium Banner
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF006C4A), Color(0xFF00E676)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${AppLocalizations.of(context)!.switchToPremium} ',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: AppLocalizations.of(context)!.premium,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  AppLocalizations.of(context)!.moreServices,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Tawsil',
                              style: TextStyle(
                                color: Color(0xFF006C4A),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12),

                    // Categories horizontal bar
                    if (_categories.isNotEmpty)
                      Container(
                        height: 50,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final selected = cat.id == _selectedCategoryId;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = cat.id;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(right: 8),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected ? Colors.black : Colors.grey[300]!,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    cat.nom,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Menu list
                    Container(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      padding: EdgeInsets.only(bottom: _cartService.isNotEmpty ? 80 : 20),
                      child: _loading
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _error != null
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                                        SizedBox(height: 16),
                                        Text(
                                          _error!,
                                          style: TextStyle(color: Colors.red),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _loadData,
                                          child: Text(AppLocalizations.of(context)!.retryAction),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : _buildMenuList(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Floating Cart Button - Only shown when cart has items
          if (_cartService.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: _navigateToCart,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF006C4A),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$_totalItems',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.viewCart,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_totalPrice.toStringAsFixed(0)} DA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    final filteredItems = _selectedCategoryId == null
        ? _menuItems
        : _menuItems.where((item) {
            final selectedId = _selectedCategoryId!;
            // Find the normalized key for the selected display id
            final nameKey = _displayIdToKey[selectedId] ?? selectedId.toLowerCase().trim();
            final allowedIds = _categoryIdMap[nameKey] ?? <String>{};

            // Accept if item.categoryId is in allowedIds
            if (allowedIds.contains(item.categoryId)) return true;

            // Or accept if category name normalized matches
            final itemCatName = item.category?.nom.toLowerCase().trim() ?? '';
            if (itemCatName.isNotEmpty && itemCatName == nameKey) return true;

            // If backend didn't provide categoryId, accept when selectedId equals the display key
            if (item.categoryId.isEmpty && selectedId.toLowerCase().trim() == nameKey) return true;

            return false;
          }).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text(
                'No menu items available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 8, bottom: 8),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        return _buildFoodItem(filteredItems[index]);
      },
    );
  }
}
