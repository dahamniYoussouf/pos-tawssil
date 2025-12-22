import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/order/widgets/cart_item_card.dart';
import 'package:client_app/src/features/order/widgets/delivery_selection_option_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/media_res.dart';
import '../../cart/services/cart_service.dart';
import 'validate_order_page.dart';
import 'package:latlong2/latlong.dart';

class ConsultOrderPage extends StatefulWidget {
  final String? restaurantName;
  final String? restaurantId;
  final String? deliveryAddress;
  final LatLng? restaurantLocation;
  final LatLng? deliveryLocation;

  const ConsultOrderPage({
    Key? key,
    this.restaurantName,
    this.restaurantId,
    this.deliveryAddress,
    this.restaurantLocation,
    this.deliveryLocation,
  }) : super(key: key);

  @override
  State<ConsultOrderPage> createState() => _ConsultOrderPageState();
}

enum DeliveryOption {
  delivery,
  pickup,
}

class _ConsultOrderPageState extends State<ConsultOrderPage> {
  final CartService _cartService = CartService();
  String selectedPaymentMethod = 'cash_on_delivery';
  DeliveryOption selectedDeliveryOption = DeliveryOption.delivery;
  final double deliveryFee = 300.0;
  final double platformFee = 0.0;

  double get _subtotal => _cartService.totalPrice;

  double get _actualDeliveryFee =>
      selectedDeliveryOption == DeliveryOption.pickup ? 0.0 : deliveryFee;

  double get _total => _subtotal + platformFee + _actualDeliveryFee;

  String get _estimatedDeliveryTime {
    if (selectedDeliveryOption == DeliveryOption.pickup) {
      return '15-20 min';
    }
    return '25-30 min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.cartTitle,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _cartService,
        builder: (context, child) {
          if (_cartService.isEmpty) {
            return const EmptyCartWidget();
          }
          return SingleChildScrollView(
            // padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.orderSummary,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: ColorApp.black),
                        ),
                        GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                                decoration: BoxDecoration(
                                  color: ColorApp.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: ColorApp.primary),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Flexible(
                                  child: Text(
                                    AppLocalizations.of(context)!.addItem,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: ColorApp.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )))
                      ],
                    )),
                if (widget.restaurantName != null)
                  _RestaurantNameSection(name: widget.restaurantName!),
                const SizedBox(height: 12),
                ..._cartService.items.values.map((item) => CartItemCard(
                      item: item,
                      onQuantityDecrease: () {
                        if (item.quantity > 1) {
                          _cartService.updateQuantity(
                              item.menuItemId, item.quantity - 1);
                        } else {
                          _showRemoveItemDialog(item);
                        }
                      },
                      onQuantityIncrease: () {
                        _cartService.updateQuantity(
                            item.menuItemId, item.quantity + 1);
                      },
                      onRemove: () => _showRemoveItemDialog(item),
                      onEdit: () {},
                    )),
                const SizedBox(height: 12),
                DeliveryOptionSection(
                  selectedOption: selectedDeliveryOption.name,
                  onOptionSelected: (option) {
                    setState(() => selectedDeliveryOption =
                        DeliveryOption.values.byName(option));
                  },
                ),
                const SizedBox(height: 12),
                if (selectedDeliveryOption == DeliveryOption.delivery)
                  _DeliveryAddressSection(
                    address: widget.deliveryAddress ?? 'Baraki, Sidi Moussa',
                  ),
                _DeliveryTimeInfo(
                  showDeliveryFee:
                      selectedDeliveryOption == DeliveryOption.delivery,
                  deliveryFee: _actualDeliveryFee,
                  estimatedTime: _estimatedDeliveryTime,
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.grey[300], thickness: 1),
                _OrderDetailsSection(
                  subtotal: _subtotal,
                  platformFee: platformFee,
                  deliveryFee: selectedDeliveryOption == DeliveryOption.delivery
                      ? _actualDeliveryFee
                      : null,
                  total: _total,
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.grey[300], thickness: 1),
                const SizedBox(height: 12),
                _PaymentMethodSection(
                  selectedMethod: selectedPaymentMethod,
                  onMethodSelected: (method) {
                    setState(() => selectedPaymentMethod = method);
                  },
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.grey[300], thickness: 1),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _VerifyButton(
        onPressed: _handleOrderValidation,
        total: _total,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showRemoveItemDialog(CartItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeProduct),
        content: Text(AppLocalizations.of(context)!
            .removeProductConfirmation(item.menuItemName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              _cartService.removeItem(item.menuItemId);
              Navigator.pop(context);
              if (_cartService.isEmpty) {
                Navigator.pop(context);
              }
            },
            child: Text(
              AppLocalizations.of(context)!.remove,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _handleOrderValidation() {
    final now = DateTime.now();
    final orderType =
        selectedDeliveryOption == DeliveryOption.pickup ? 'PKP' : 'DEL';
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour}${now.minute}${now.second}';
    final orderNumber = '$orderType-$dateStr-$timeStr';
    final orderItems = _cartService.items.values.map((item) {
      return {
        'menu_item_id': item.menuItemId,
        'name': item.menuItemName, // For display purposes
        'quantity': item.quantity,
        'special_instructions': item.note,
        'price': item.price.toStringAsFixed(0), // For display purposes
      };
    }).toList();
    final l10n = AppLocalizations.of(context)!;
    final paymentMethodLabel = {
          'cash_on_delivery': l10n.cash,
          'baridi_mob': l10n.baridiMob,
          'bank_transfer': l10n.bankTransfer,
        }[selectedPaymentMethod] ??
        l10n.cash;

    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return FractionallySizedBox(
            heightFactor: 0.95,
            child: ValidateOrderPage(
              deliveryAddress: widget.deliveryAddress ?? '',
              estimatedTime: _estimatedDeliveryTime,
              orderNumber: orderNumber,
              totalPrice: _total,
              paymentMethod: paymentMethodLabel,
              paymentMethodCode: selectedPaymentMethod,
              orderItems: orderItems,
              orderType: orderType,
              deliveryFee: _actualDeliveryFee,
              pickupLocation: widget.restaurantLocation!,
              deliveryLocation: widget.deliveryLocation!,
              restaurantName: widget.restaurantName,
              restaurantId: widget.restaurantId,
            ),
          );
        });
  }
}

class EmptyCartWidget extends StatelessWidget {
  const EmptyCartWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.emptyCart,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.addProductsToContinue,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantNameSection extends StatelessWidget {
  final String name;

  const _RestaurantNameSection({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
    );
  }
}

class _DeliveryAddressSection extends StatelessWidget {
  final String address;

  const _DeliveryAddressSection({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorApp.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(MediaRes.locationIcon,
                        width: 20, height: 20),
                    SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.deliveryAddress,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ColorApp.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorApp.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.arrow_forward_ios, color: ColorApp.primary),
          ),
        ],
      ),
    );
  }
}

class _DeliveryTimeInfo extends StatelessWidget {
  final bool showDeliveryFee;
  final double deliveryFee;
  final String estimatedTime;

  const _DeliveryTimeInfo({
    required this.showDeliveryFee,
    required this.deliveryFee,
    required this.estimatedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showDeliveryFee)
                Row(
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 16, color: ColorApp.black),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.deliveryFee,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: ColorApp.black,
                      ),
                    ),
                  ],
                ),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: ColorApp.black),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.estimatedTime,
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorApp.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showDeliveryFee)
                Text(
                  '${deliveryFee.toStringAsFixed(0)} DA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: ColorApp.black,
                  ),
                ),
              Text(
                estimatedTime,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: ColorApp.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderDetailsSection extends StatelessWidget {
  final double subtotal;
  final double platformFee;
  final double? deliveryFee;
  final double total;

  const _OrderDetailsSection({
    required this.subtotal,
    required this.platformFee,
    this.deliveryFee,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.orderDetails,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: ColorApp.black,
            ),
          ),
          const SizedBox(height: 12),
          PriceRowWidget(
            label: AppLocalizations.of(context)!.subtotal,
            price: '${subtotal.toStringAsFixed(0)} DA',
          ),
          const SizedBox(height: 8),
          PriceRowWidget(
            label: AppLocalizations.of(context)!.platformFee,
            price: '${platformFee.toStringAsFixed(0)} DA',
          ),
          if (deliveryFee != null) ...[
            const SizedBox(height: 8),
            PriceRowWidget(
              label: AppLocalizations.of(context)!.deliveryFee,
              price: '${deliveryFee!.toStringAsFixed(0)} DA',
            ),
          ],
          const SizedBox(height: 12),
          PriceRowWidget(
            label: AppLocalizations.of(context)!.total,
            price: '${total.toDouble().toStringAsFixed(0)} DA',
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class PriceRowWidget extends StatelessWidget {
  final String label;
  final String price;
  final bool isTotal;

  const PriceRowWidget({
    Key? key,
    required this.label,
    required this.price,
    this.isTotal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodSection extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodSelected;

  const _PaymentMethodSection({
    required this.selectedMethod,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            AppLocalizations.of(context)!.paymentMethod,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
            height: 70,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                PaymentOptionWidget(
                  label: AppLocalizations.of(context)!.cash,
                  icon: MediaRes.cashIcon,
                  value: 'cash_on_delivery',
                  isSelected: selectedMethod == 'cash_on_delivery',
                  onTap: () => onMethodSelected('cash_on_delivery'),
                  radiusLeft: 12,
                ),
                PaymentOptionWidget(
                  label: AppLocalizations.of(context)!.baridiMob,
                  icon: MediaRes.cardIcon,
                  value: 'baridi_mob',
                  isSelected: selectedMethod == 'baridi_mob',
                  onTap: () => onMethodSelected('baridi_mob'),
                  radiusRight: 12,
                ),
              ],
            )),
      ],
    );
  }
}

class PaymentOptionWidget extends StatelessWidget {
  final String label;
  final String icon;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;
  final double? radiusLeft;
  final double? radiusRight;

  const PaymentOptionWidget({
    Key? key,
    required this.label,
    required this.icon,
    required this.value,
    required this.isSelected,
    required this.onTap,
    this.radiusLeft,
    this.radiusRight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
          padding:
              const EdgeInsets.only(left: 32, right: 32, top: 4, bottom: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00695C).withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radiusLeft ?? 0),
              bottomLeft: Radius.circular(radiusLeft ?? 0),
              topRight: Radius.circular(radiusRight ?? 0),
              bottomRight: Radius.circular(radiusRight ?? 0),
            ),
            border: Border.all(
              color: isSelected ? const Color(0xFF00695C) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(icon),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF00695C) : Colors.black,
                  ),
                ),
              ),
            ],
          )),
    );
  }
}

class _VerifyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double total;

  const _VerifyButton({required this.onPressed, required this.total});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onPressed,
        child: Card(
          elevation: 5,
          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          color: ColorApp.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                color: ColorApp.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${total.toDouble().toStringAsFixed(2)} DA',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: ColorApp.textBlack),
                  ),
                  const SizedBox(width: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: ColorApp.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      AppLocalizations.of(context)!.verifyAndFinalize,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                    ),
                  )
                ],
              )),
        ));
  }
}
