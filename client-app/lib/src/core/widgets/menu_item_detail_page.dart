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
  final ValueNotifier<Map<String, Set<String>>> _selectedOptionsByGroup =
      ValueNotifier<Map<String, Set<String>>>({});

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

        // Restore selected options
        if (cartItem.selectedOptions.isNotEmpty) {
          _selectedOptionsByGroup.value =
              _buildSelectedOptionsByGroup(cartItem.selectedOptions);
        }
      }
    });
  }

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
    _isFavorite.dispose();
    _selectedOptionsByGroup.dispose();
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
      final selectedOptions =
          _buildSelectedOptionsFromMap(_selectedOptionsByGroup.value);
      cartCubit.addOrSetItem(
        menuItem: widget.menuItem,
        menuItemId: widget.menuItem.id,
        menuItemName: widget.menuItem.nom,
        price: widget.menuItem.prix,
        imageUrl: widget.menuItem.imageUrl,
        quantity: newQuantity,
        note: note,
        selectedOptions: selectedOptions,
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
          final selectedOptions =
              _buildSelectedOptionsFromMap(_selectedOptionsByGroup.value);
          cartCubit.addOrSetItem(
            menuItem: widget.menuItem,
            menuItemId: widget.menuItem.id,
            menuItemName: widget.menuItem.nom,
            price: widget.menuItem.prix,
            imageUrl: widget.menuItem.imageUrl,
            quantity: newQuantity,
            note: note,
            selectedOptions: selectedOptions,
          );
        }
      }
    }
  }

  void _toggleFavorite() {
    _isFavorite.value = !_isFavorite.value;
  }

  void _toggleOption(String groupId, String optionId, bool isRequired) {
    final Map<String, Set<String>> currentSelections =
        Map<String, Set<String>>.from(_selectedOptionsByGroup.value);
    final Set<String> groupSelections =
        Set<String>.from(currentSelections[groupId] ?? <String>{});
    if (isRequired) {
      if (groupSelections.contains(optionId)) {
        return;
      }
      currentSelections[groupId] = <String>{optionId};
    } else {
      if (groupSelections.contains(optionId)) {
        groupSelections.remove(optionId);
      } else {
        groupSelections.add(optionId);
      }
      currentSelections[groupId] = groupSelections;
    }
    final cartCubit = context.read<CartCubit>();
    _selectedOptionsByGroup.value = currentSelections;
    if (cartCubit.hasItem(widget.menuItem.id)) {
      final selectedOptions = _buildSelectedOptionsFromMap(currentSelections);
      cartCubit.updateSelectedOptions(widget.menuItem.id, selectedOptions);
    }
  }

  Map<String, Set<String>> _buildSelectedOptionsByGroup(
    List<MenuItemOption> selectedOptions,
  ) {
    final Map<String, Set<String>> selections = <String, Set<String>>{};
    for (final MenuItemOption option in selectedOptions) {
      final String? groupId =
          option.optionGroupId ?? _findGroupIdForOption(option.id);
      if (groupId == null) {
        continue;
      }
      selections.putIfAbsent(groupId, () => <String>{});
      selections[groupId]!.add(option.id);
    }
    return selections;
  }

  List<MenuItemOption> _buildSelectedOptionsFromMap(
    Map<String, Set<String>> selectedOptionsByGroup,
  ) {
    final List<MenuItemOption> selectedOptions = <MenuItemOption>[];
    for (final MenuItemOptionGroup group in widget.menuItem.optionGroups) {
      final Set<String> selectedIds =
          selectedOptionsByGroup[group.id] ?? <String>{};
      for (final MenuItemOption option in group.options) {
        if (selectedIds.contains(option.id)) {
          selectedOptions.add(option);
        }
      }
    }
    return selectedOptions;
  }

  bool _areRequiredOptionsSelected(
    Map<String, Set<String>> selectedOptionsByGroup,
  ) {
    for (final MenuItemOptionGroup group in widget.menuItem.optionGroups) {
      if (!group.isRequired) {
        continue;
      }
      if (group.options.isEmpty) {
        continue;
      }
      final Set<String> selectedIds =
          selectedOptionsByGroup[group.id] ?? <String>{};
      if (selectedIds.isEmpty) {
        return false;
      }
    }
    return true;
  }

  String? _findGroupIdForOption(String optionId) {
    for (final MenuItemOptionGroup group in widget.menuItem.optionGroups) {
      final bool hasOption =
          group.options.any((MenuItemOption option) => option.id == optionId);
      if (hasOption) {
        return group.id;
      }
    }
    return null;
  }

  void _addToCart() {
    final detailsCubit = context.read<RestaurantDetailsCubit>();
    final cartCubit = context.read<CartCubit>();
    final quantity = _quantity.value;
    final note = _note.value.isNotEmpty ? _note.value : null;
    final selectedOptions =
        _buildSelectedOptionsFromMap(_selectedOptionsByGroup.value);
    cartCubit.addOrSetItem(
      menuItem: widget.menuItem,
      menuItemId: widget.menuItem.id,
      menuItemName: widget.menuItem.nom,
      price: widget.menuItem.prix,
      imageUrl: widget.menuItem.imageUrl,
      quantity: quantity,
      note: note,
      selectedOptions: selectedOptions,
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
          return ValueListenableBuilder<Map<String, Set<String>>>(
            valueListenable: _selectedOptionsByGroup,
            builder: (context, selectedOptionsByGroup, __) {
              return BlocBuilder<CartCubit, CartState>(
                builder: (context, cartState) {
                  final cartCubit = context.read<CartCubit>();
                  final isInCart = cartCubit.hasItem(widget.menuItem.id);
                  final localizations = AppLocalizations.of(context)!;
                  final bool hasRequiredSelections =
                      _areRequiredOptionsSelected(selectedOptionsByGroup);
                  return MenuItemDetailBottomBar(
                    quantity: quantity,
                    onDecrementQuantity: _decrementQuantity,
                    onIncrementQuantity: _incrementQuantity,
                    onButtonPressed: isInCart ? _removeFromCart : _addToCart,
                    buttonText: isInCart
                        ? localizations.removeFromCart
                        : localizations.addToCart,
                    isRemoveButton: isInCart,
                    isButtonEnabled: isInCart ? true : hasRequiredSelections,
                  );
                },
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
          if (widget.menuItem.optionGroups.isNotEmpty)
            ValueListenableBuilder<Map<String, Set<String>>>(
              valueListenable: _selectedOptionsByGroup,
              builder: (context, selectedOptionsByGroup, _) {
                return MenuItemDetailOptionsSection(
                  optionGroups: widget.menuItem.optionGroups
                      .map((group) => OptionGroupData(
                            id: group.id,
                            name: group.nom,
                            isRequired: group.isRequired,
                            options: group.options
                                .map((option) => OptionItemData(
                                      id: option.id,
                                      name: option.nom,
                                      price: option.prix,
                                      isAvailable: option.isAvailable,
                                    ))
                                .toList(),
                          ))
                      .toList(),
                  selectedOptionsByGroup: selectedOptionsByGroup,
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
