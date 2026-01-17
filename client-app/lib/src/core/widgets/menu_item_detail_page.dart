import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/widgets/menu_item_detail_options_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/restaurant/models/menu_model.dart';
import '../../features/cart/cubit/cart_cubit.dart';
import '../../features/cart/states/cart_state.dart';
import '../../features/restaurant/cubit/restaurant_details_cubit.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'menu_item_detail_image_section.dart';
import 'menu_item_detail_item_header.dart';
import 'menu_item_detail_rating_section.dart';
import 'menu_item_detail_description_section.dart';
import 'menu_item_detail_note_section.dart';
import 'menu_item_detail_bottom_bar.dart';

class MenuItemDetailPage extends StatelessWidget {
  final MenuModel menuItem;

  const MenuItemDetailPage({
    Key? key,
    required this.menuItem,
  }) : super(key: key);

  // Hardcoded fallback data
  static const String defaultImageUrl =
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800';
  static const String defaultName = 'Plat Arabi';
  static const String defaultDescription =
      'A delicious Plat Arabi served on a toasted bun with fresh lettuce, tomato slices, and mayonnaise. Juicy grilled chicken patty seasoned to perfection for a mouthwatering experience.';
  static const double defaultPrice = 650.0;
  static const double defaultOldPrice = 700.0;
  static const double defaultRating = 4.9;
  static const int defaultReviewCount = 1205;

  @override
  Widget build(BuildContext context) {
    return _MenuItemDetailPageContent(menuItem: menuItem);
  }
}

class _MenuItemDetailPageContent extends StatefulWidget {
  final MenuModel menuItem;

  const _MenuItemDetailPageContent({
    Key? key,
    required this.menuItem,
  }) : super(key: key);

  @override
  State<_MenuItemDetailPageContent> createState() =>
      _MenuItemDetailPageContentState();
}

class _MenuItemDetailPageContentState
    extends State<_MenuItemDetailPageContent> {
  final ValueNotifier<int> _quantity = ValueNotifier<int>(1);
  final ValueNotifier<String> _note = ValueNotifier<String>('');
  final ValueNotifier<bool> _isFavorite = ValueNotifier<bool>(false);
  final ValueNotifier<Set<String>> _selectedOptions =
      ValueNotifier<Set<String>>({});

  @override
  void initState() {
    super.initState();
    // Restore cart state if item is already in cart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cartCubit = context.read<CartCubit>();
      final cartItem = cartCubit.getItem(widget.menuItem.id);

      if (cartItem != null) {
        // Restore quantity
        _quantity.value = cartItem.quantity;

        // Restore note
        if (cartItem.note != null && cartItem.note!.isNotEmpty) {
          _note.value = cartItem.note!;
        }

        // Restore selected options (additions)
        if (cartItem.additions.isNotEmpty) {
          final selectedOptionIds =
              cartItem.additions.map((addition) => addition.id).toSet();
          _selectedOptions.value = selectedOptionIds;
        }
      }
    });
  }

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
    _isFavorite.dispose();
    _selectedOptions.dispose();
    super.dispose();
  }

  String get _itemName => widget.menuItem.nom.isEmpty
      ? MenuItemDetailPage.defaultName
      : widget.menuItem.nom;

  String get _itemDescription => widget.menuItem.description?.isNotEmpty == true
      ? widget.menuItem.description!
      : MenuItemDetailPage.defaultDescription;

  String get _itemImageUrl => widget.menuItem.imageUrl.isNotEmpty &&
          widget.menuItem.imageUrl != 'https://via.placeholder.com/150'
      ? widget.menuItem.imageUrl
      : MenuItemDetailPage.defaultImageUrl;

  double get _itemPrice => widget.menuItem.prix > 0
      ? widget.menuItem.prix
      : MenuItemDetailPage.defaultPrice;

  double get _itemOldPrice => MenuItemDetailPage.defaultOldPrice;

  bool get _hasDiscount => _itemOldPrice > _itemPrice;

  void _incrementQuantity() {
    final cartCubit = context.read<CartCubit>();
    final newQuantity = _quantity.value + 1;
    _quantity.value = newQuantity;

    // If item is already in cart, update cart quantity
    if (cartCubit.hasItem(widget.menuItem.id)) {
      final note = _note.value.isNotEmpty ? _note.value : null;
      final selectedAdditions = _selectedOptions.value
          .map((optionId) => widget.menuItem.additions
              .where((add) => add.id == optionId)
              .toList())
          .expand((list) => list)
          .toList();

      cartCubit.addOrSetItem(
        menuItem: widget.menuItem,
        menuItemId: widget.menuItem.id,
        menuItemName: widget.menuItem.nom,
        price: widget.menuItem.prix,
        imageUrl: widget.menuItem.imageUrl,
        quantity: newQuantity,
        note: note,
        additions: selectedAdditions.isNotEmpty ? selectedAdditions : null,
      );
    }
  }

  void _decrementQuantity() {
    if (_quantity.value > 1) {
      final cartCubit = context.read<CartCubit>();
      final newQuantity = _quantity.value - 1;
      _quantity.value = newQuantity;

      // If item is already in cart, update cart quantity
      if (cartCubit.hasItem(widget.menuItem.id)) {
        if (newQuantity <= 0) {
          cartCubit.removeItem(widget.menuItem.id);
        } else {
          final note = _note.value.isNotEmpty ? _note.value : null;
          final selectedAdditions = _selectedOptions.value
              .map((optionId) => widget.menuItem.additions
                  .where((add) => add.id == optionId)
                  .toList())
              .expand((list) => list)
              .toList();

          cartCubit.addOrSetItem(
            menuItem: widget.menuItem,
            menuItemId: widget.menuItem.id,
            menuItemName: widget.menuItem.nom,
            price: widget.menuItem.prix,
            imageUrl: widget.menuItem.imageUrl,
            quantity: newQuantity,
            note: note,
            additions: selectedAdditions.isNotEmpty ? selectedAdditions : null,
          );
        }
      }
    }
  }

  void _toggleFavorite() {
    _isFavorite.value = !_isFavorite.value;
  }

  void _toggleOption(String optionId) {
    final currentOptions = Set<String>.from(_selectedOptions.value);
    final additions =
        widget.menuItem.additions.where((add) => add.id == optionId).toList();

    if (additions.isEmpty) return;
    final addition = additions.first;

    final cartCubit = context.read<CartCubit>();
    if (currentOptions.contains(optionId)) {
      currentOptions.remove(optionId);
      if (cartCubit.hasItem(widget.menuItem.id)) {
        cartCubit.removeAddition(widget.menuItem.id, addition);
      }
    } else {
      currentOptions.add(optionId);
      if (cartCubit.hasItem(widget.menuItem.id)) {
        cartCubit.addAddition(widget.menuItem.id, addition);
      }
    }
    _selectedOptions.value = currentOptions;
  }

  void _addToCart() {
    final detailsCubit = context.read<RestaurantDetailsCubit>();
    final cartCubit = context.read<CartCubit>();
    final quantity = _quantity.value;
    final note = _note.value.isNotEmpty ? _note.value : null;
    final selectedAdditions = _selectedOptions.value
        .map((optionId) => widget.menuItem.additions
            .where((add) => add.id == optionId)
            .toList())
        .expand((list) => list)
        .toList();

    cartCubit.addOrSetItem(
      menuItem: widget.menuItem,
      menuItemId: widget.menuItem.id,
      menuItemName: widget.menuItem.nom,
      price: widget.menuItem.prix,
      imageUrl: widget.menuItem.imageUrl,
      quantity: quantity,
      note: note,
      additions: selectedAdditions.isNotEmpty ? selectedAdditions : null,
    );

    detailsCubit.setSelectedItemId(widget.menuItem.id);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        detailsCubit.setSelectedItemId(null);
      }
    });
    Navigator.pop(context);
  }

  void _removeFromCart() {
    final cartCubit = context.read<CartCubit>();
    cartCubit.removeItem(widget.menuItem.id);
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
                  ValueListenableBuilder<bool>(
                    valueListenable: _isFavorite,
                    builder: (context, isFavorite, _) {
                      return MenuItemDetailImageSection(
                        imageUrl: _itemImageUrl,
                        onBackPressed: () => Navigator.pop(context),
                        onFavoritePressed: _toggleFavorite,
                        isFavorite: isFavorite,
                      );
                    },
                  ),
                  _buildContentSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<int>(
        valueListenable: _quantity,
        builder: (context, quantity, _) {
          return BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              final cartCubit = context.read<CartCubit>();
              final isInCart = cartCubit.hasItem(widget.menuItem.id);
              final localizations = AppLocalizations.of(context)!;

              return MenuItemDetailBottomBar(
                quantity: quantity,
                onDecrementQuantity: _decrementQuantity,
                onIncrementQuantity: _incrementQuantity,
                onButtonPressed: isInCart ? _removeFromCart : _addToCart,
                buttonText: isInCart
                    ? localizations.removeFromCart
                    : localizations.addToCart,
                isRemoveButton: isInCart,
              );
            },
          );
        },
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
            rating: MenuItemDetailPage.defaultRating,
            reviewCount: MenuItemDetailPage.defaultReviewCount,
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
          ValueListenableBuilder<Set<String>>(
            valueListenable: _selectedOptions,
            builder: (context, selectedOptions, _) {
              return MenuItemDetailOptionsSection(
                options: widget.menuItem.additions
                    .map((addition) => AdditionalOption(
                          id: addition.id,
                          name: addition.nom,
                          price: addition.prix,
                        ))
                    .toList(),
                selectedOptions: selectedOptions,
                onOptionToggled: _toggleOption,
              );
            },
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder<String>(
            valueListenable: _note,
            builder: (context, note, _) {
              return MenuItemDetailNoteSection(
                note: note,
                onNoteChanged: (value) {
                  _note.value = value;
                },
              );
            },
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
