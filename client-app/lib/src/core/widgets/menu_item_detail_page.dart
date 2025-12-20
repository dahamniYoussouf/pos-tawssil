import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/widgets/menu_item_detail_options_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/restaurant/models/menu_model.dart';
import '../../features/cart/cubit/cart_cubit.dart';
import '../../features/restaurant/cubit/restaurant_details_cubit.dart';
import 'menu_item_detail_image_section.dart';
import 'menu_item_detail_item_header.dart';
import 'menu_item_detail_rating_section.dart';
import 'menu_item_detail_description_section.dart';
import 'menu_item_detail_note_section.dart';
import 'menu_item_detail_bottom_bar.dart';

class MenuItemDetailPage extends StatefulWidget {
  final MenuModel menuItem;

  const MenuItemDetailPage({
    Key? key,
    required this.menuItem,
  }) : super(key: key);

  @override
  State<MenuItemDetailPage> createState() => _MenuItemDetailPageState();
}

class _MenuItemDetailPageState extends State<MenuItemDetailPage> {
  int _quantity = 1;
  String _note = '';
  bool _isFavorite = false;
  final Set<String> _selectedOptions = {};

  // Hardcoded fallback data
  static const String _defaultImageUrl =
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800';
  static const String _defaultName = 'Plat Arabi';
  static const String _defaultDescription =
      'A delicious Plat Arabi served on a toasted bun with fresh lettuce, tomato slices, and mayonnaise. Juicy grilled chicken patty seasoned to perfection for a mouthwatering experience.';
  static const double _defaultPrice = 650.0;
  static const double _defaultOldPrice = 700.0;
  static const double _defaultRating = 4.9;
  static const int _defaultReviewCount = 1205;

  String get _itemName =>
      widget.menuItem.nom.isEmpty ? _defaultName : widget.menuItem.nom;

  String get _itemDescription => widget.menuItem.description?.isNotEmpty == true
      ? widget.menuItem.description!
      : _defaultDescription;

  String get _itemImageUrl => widget.menuItem.imageUrl.isNotEmpty &&
          widget.menuItem.imageUrl != 'https://via.placeholder.com/150'
      ? widget.menuItem.imageUrl
      : _defaultImageUrl;

  double get _itemPrice =>
      widget.menuItem.prix > 0 ? widget.menuItem.prix : _defaultPrice;

  double get _itemOldPrice => _defaultOldPrice;

  bool get _hasDiscount => _itemOldPrice > _itemPrice;

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _toggleOption(String optionId) {
    setState(() {
      if (_selectedOptions.contains(optionId)) {
        _selectedOptions.remove(optionId);
      } else {
        _selectedOptions.add(optionId);
      }
    });
  }

  void _addToCart() {
    final cartCubit = context.read<CartCubit>();
    final detailsCubit = context.read<RestaurantDetailsCubit>();
    cartCubit.addOrSetItem(
      menuItemId: widget.menuItem.id,
      menuItemName: widget.menuItem.nom,
      price: widget.menuItem.prix,
      imageUrl: widget.menuItem.imageUrl,
      quantity: _quantity,
      note: _note.isNotEmpty ? _note : null,
    );
    detailsCubit.setSelectedItemId(widget.menuItem.id);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        detailsCubit.setSelectedItemId(null);
      }
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MenuItemDetailImageSection(
                    imageUrl: _itemImageUrl,
                    onBackPressed: () => Navigator.pop(context),
                    onFavoritePressed: _toggleFavorite,
                    isFavorite: _isFavorite,
                  ),
                  _buildContentSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: MenuItemDetailBottomBar(
        quantity: _quantity,
        onDecrementQuantity: _decrementQuantity,
        onIncrementQuantity: _incrementQuantity,
        onAddToCart: _addToCart,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          MenuItemDetailItemHeader(
            itemName: _itemName,
            itemDescription: _itemDescription,
            itemPrice: _itemPrice,
            itemOldPrice: _itemOldPrice,
            hasDiscount: _hasDiscount,
          ),
          const SizedBox(height: 28),
          MenuItemDetailRatingSection(
            rating: _defaultRating,
            reviewCount: _defaultReviewCount,
            onSeeAllReviews: () {
              // TODO: Navigate to reviews page
            },
          ),
          const SizedBox(height: 24),
          MenuItemDetailDescriptionSection(
            description: _itemDescription,
            onShowAll: () {
              // TODO: Show full description
            },
          ),
          const SizedBox(height: 24),
          MenuItemDetailOptionsSection(
            options: widget.menuItem.additions
                .map((addition) => AdditionalOption(
                      id: addition.id,
                      name: addition.nom,
                      price: addition.prix,
                    ))
                .toList(),
            selectedOptions: _selectedOptions,
            onOptionToggled: _toggleOption,
          ),
          const SizedBox(height: 24),
          MenuItemDetailNoteSection(
            note: _note,
            onNoteChanged: (value) {
              setState(() {
                _note = value;
              });
            },
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
