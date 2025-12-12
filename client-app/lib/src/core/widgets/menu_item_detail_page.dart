import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import '../../features/restaurant/models/menu_model.dart';

class AdditionalOption {
  final String id;
  final String name;
  final double price;

  const AdditionalOption({
    required this.id,
    required this.name,
    required this.price,
  });
}

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
    Navigator.pop(context, {
      'menuItem': widget.menuItem,
      'quantity': _quantity,
      'note': _note,
      'selectedOptions': _selectedOptions.toList(),
    });
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
                  _buildImageSection(),
                  _buildContentSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildBottomBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          width: double.infinity,
          height: 300,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Image.network(
              _itemImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: ColorApp.grey,
                  child: const Icon(
                    Icons.restaurant,
                    size: 80,
                    color: ColorApp.grey,
                  ),
                );
              },
            ),
          ),
        ),
        _buildBackButton(),
        _buildFavoriteButton(),
      ],
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 35,
      left: 16,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ColorApp.greyLight.withOpacity(0.5),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ColorApp.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(
            Icons.arrow_back,
            color: ColorApp.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: ColorApp.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: ColorApp.grey,
            width: 1,
          ),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? ColorApp.redColor : ColorApp.primary,
            size: 24,
          ),
          onPressed: _toggleFavorite,
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildItemHeader(),
          const SizedBox(height: 28),
          _buildRatingSection(),
          const SizedBox(height: 24),
          _buildDescriptionSection(),
          const SizedBox(height: 24),
          _buildAdditionalOptionsSection(),
          const SizedBox(height: 24),
          _buildNoteSection(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildItemHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _itemName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: ColorApp.black,
          ),
        ),
        const SizedBox(height: 8),
        if (_itemDescription.isNotEmpty)
          Text(
            _itemDescription,
            style: TextStyle(
              fontSize: 12,
              color: ColorApp.grey,
              height: 1.4,
            ),
          ),
        const SizedBox(height: 12),
        _buildPriceSection(),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Row(
      children: [
        if (_hasDiscount) ...[
          Text(
            '${_itemOldPrice.toStringAsFixed(0)} DA',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: ColorApp.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          '${_itemPrice.toStringAsFixed(0)} DA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _hasDiscount ? ColorApp.greenColor : ColorApp.black,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.star,
              color: ColorApp.premiumColor,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '${_defaultRating} (${_formatReviewCount(_defaultReviewCount)})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: ColorApp.black,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            // TODO: Navigate to reviews page
          },
          child: Text(
            'See All Review',
            style: TextStyle(
              fontSize: 14,
              color: ColorApp.greyLight,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _itemDescription,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: ColorApp.grey,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                // TODO: Show full description
              },
              child: Text(
                AppLocalizations.of(context)!.showAll,
                style: TextStyle(
                  fontSize: 14,
                  color: ColorApp.grey,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.end,
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildAdditionalOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Options :',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: ColorApp.black,
          ),
        ),
        const SizedBox(height: 12),
        ...defaultAdditionalOptions.map((option) {
          return _buildOptionItem(option);
        }),
      ],
    );
  }

  Widget _buildOptionItem(AdditionalOption option) {
    final bool isSelected = _selectedOptions.contains(option.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _toggleOption(option.id),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? ColorApp.primary.withOpacity(0.05) : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: ColorApp.black,
                  ),
                ),
              ),
              Text(
                option.price > 0
                    ? '+ ${option.price.toStringAsFixed(0)} DA'
                    : 'Free',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: option.price > 0 ? ColorApp.primary : ColorApp.grey,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? ColorApp.primary : ColorApp.grey,
                    width: 2,
                  ),
                  color: isSelected ? ColorApp.primary : ColorApp.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: ColorApp.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(MediaRes.noteIcon,
                  width: 22, height: 22, color: ColorApp.black),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.noteForKitchen,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: ColorApp.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: ColorApp.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.noteForKitchen,
                hintStyle: TextStyle(
                  color: ColorApp.grey,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: ColorApp.backgroundGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorApp.greyBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorApp.greyBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorApp.primary),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: ColorApp.black,
              ),
              onChanged: (value) {
                setState(() {
                  _note = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: ColorApp.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              _buildQuantitySelector(),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorApp.primary,
                    foregroundColor: ColorApp.white,
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                    shadowColor: ColorApp.transparent,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(MediaRes.cartIcon,
                          width: 20, height: 20, color: ColorApp.white),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!.addToCart,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildQuantitySelector() {
    return Container(
      height: 52,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: _decrementQuantity,
              color: ColorApp.black,
              padding: EdgeInsets.zero,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$_quantity',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ColorApp.black,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: _incrementQuantity,
              color: ColorApp.black,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  String _formatReviewCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

const List<AdditionalOption> defaultAdditionalOptions = [
  AdditionalOption(id: '1', name: 'Add Cheese', price: 100.0),
  AdditionalOption(id: '2', name: 'Add Tomato', price: 50.0),
  AdditionalOption(id: '3', name: 'Add Ketchup', price: 0.0),
];
