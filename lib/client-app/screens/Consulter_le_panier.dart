import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import 'Valider_la_commande.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ConsulterLePanier extends StatefulWidget {
  final String? restaurantName;
  final String? restaurantId;
  final String? deliveryAddress;
  final LatLng? restaurantLocation;
  final LatLng? deliveryLocation;

  const ConsulterLePanier({
    Key? key,
    this.restaurantName,
    this.restaurantId,
    this.deliveryAddress,
    this.restaurantLocation,
    this.deliveryLocation,
  }) : super(key: key);

  @override
  State<ConsulterLePanier> createState() => _ConsulterLePanierState();
}

class _ConsulterLePanierState extends State<ConsulterLePanier> {
  final CartService _cartService = CartService();
  String selectedPaymentMethod = 'cash_on_delivery';
  String selectedDeliveryOption = 'delivery';
  final double deliveryFee = 300.0;
  final double platformFee = 0.0;

  double get _subtotal => _cartService.totalPrice;
  
  double get _actualDeliveryFee => selectedDeliveryOption == 'pickup' ? 0.0 : deliveryFee;
  
  double get _total => _subtotal + platformFee + _actualDeliveryFee;

  String get _estimatedDeliveryTime {
    if (selectedDeliveryOption == 'pickup') {
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
        title: const Text(
          'Panier',
          style: TextStyle(
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
            return _buildEmptyCart();
          }
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant name
                if (widget.restaurantName != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.restaurantName!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),

                // Delivery address
                if (selectedDeliveryOption == 'delivery')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 20, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adresse de livraison',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.deliveryAddress ?? 'Baraki, Sidi Moussa',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Product section header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Produit${_cartService.items.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Product items from cart
                ..._cartService.items.values.map((item) => _buildCartItem(item)).toList(),

                const SizedBox(height: 12),

                // Delivery time info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (selectedDeliveryOption == 'delivery')
                        Row(
                          children: [
                            Icon(Icons.local_shipping_outlined, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Frais de livraison',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Temps estimé',
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

                const SizedBox(height: 4),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (selectedDeliveryOption == 'delivery')
                        Text(
                          '${_actualDeliveryFee.toStringAsFixed(0)} DA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      Text(
                        _estimatedDeliveryTime,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.grey[300], thickness: 1),
                const SizedBox(height: 12),

                // Order details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Détails de la commande',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPriceRow('Sous-total', '${_subtotal.toStringAsFixed(0)} DA'),
                      const SizedBox(height: 8),
                      _buildPriceRow('Frais de plateforme', '${platformFee.toStringAsFixed(0)} DA'),
                      if (selectedDeliveryOption == 'delivery') ...[
                        const SizedBox(height: 8),
                        _buildPriceRow('Frais de livraison', '${_actualDeliveryFee.toStringAsFixed(0)} DA'),
                      ],
                      const SizedBox(height: 12),
                      _buildPriceRow('Total', '${_total.toStringAsFixed(0)} DA', isTotal: true),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.grey[300], thickness: 1),
                const SizedBox(height: 12),

                // Payment method
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: const Text(
                    'Méthode de paiement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _buildPaymentOption('Espèces', Icons.money, 'cash_on_delivery'),
                _buildPaymentOption('Baridi Mob', Icons.phone_android, 'baridi_mob'),
                _buildPaymentOption('Virement bancaire', Icons.account_balance, 'bank_transfer'),

                const SizedBox(height: 20),
                Divider(color: Colors.grey[300], thickness: 1),
                const SizedBox(height: 12),

                // Delivery option
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: const Text(
                    'Option de livraison',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _buildDeliveryOption('Sur place (sans livraison)', Icons.store, 'pickup'),
                _buildDeliveryOption('Livraison', Icons.pedal_bike, 'delivery'),

                const SizedBox(height: 30),

                // Verify and finalize button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleOrderValidation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00695C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Vérifier et Finaliser',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
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
              'Votre panier est vide',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des produits pour continuer',
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

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
              image: item.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(item.imageUrl),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    )
                  : null,
            ),
            child: item.imageUrl.isEmpty
                ? Icon(Icons.restaurant, color: Colors.grey[400])
                : null,
          ),
          const SizedBox(width: 12),
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItemName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(0)} DA',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Note: ${item.note}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Quantity controls
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 18),
                  onPressed: () {
                    if (item.quantity > 1) {
                      _cartService.updateQuantity(item.menuItemId, item.quantity - 1);
                    } else {
                      _showRemoveItemDialog(item);
                    }
                  },
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () {
                    _cartService.updateQuantity(item.menuItemId, item.quantity + 1);
                  },
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveItemDialog(CartItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer le produit'),
        content: Text('Voulez-vous retirer "${item.menuItemName}" du panier?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _cartService.removeItem(item.menuItemId);
              Navigator.pop(context);
              if (_cartService.isEmpty) {
                Navigator.pop(context); // Return to previous screen
              }
            },
            child: const Text(
              'Retirer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _handleOrderValidation() {
    // Generate order number
    final now = DateTime.now();
    final orderType = selectedDeliveryOption == 'pickup' ? 'PKP' : 'DEL';
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour}${now.minute}${now.second}';
    final orderNumber = '$orderType-$dateStr-$timeStr';

    // Prepare order items for validation screen
    final orderItems = _cartService.items.values.map((item) {
      return {
        'name': item.menuItemName,
        'quantity': item.quantity,
        'price': item.price.toStringAsFixed(0),
        'note': item.note,
      };
    }).toList();

    // Payment method label
    final paymentMethodLabel = {
      'cash_on_delivery': 'Espèces',
      'baridi_mob': 'Baridi Mob',
      'bank_transfer': 'Virement bancaire',
    }[selectedPaymentMethod] ?? 'Espèces';

    // Navigate to validation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ValiderLaCommandePage(
          deliveryAddress: widget.deliveryAddress ?? 'Baraki, Sidi Moussa',
          estimatedTime: _estimatedDeliveryTime,
          orderNumber: orderNumber,
          totalPrice: _total,
          paymentMethod: paymentMethodLabel,
          orderItems: orderItems,
          pickupLocation: widget.restaurantLocation,
          deliveryLocation: widget.deliveryLocation,
          restaurantName: widget.restaurantName,
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String label, IconData icon, String value) {
    final isSelected = selectedPaymentMethod == value;
    return InkWell(
      onTap: () {
        setState(() => selectedPaymentMethod = value);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00695C).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00695C) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? const Color(0xFF00695C) : Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF00695C) : Colors.black,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF00695C),
                size: 22,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: Colors.grey[400],
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOption(String label, IconData icon, String value) {
    final isSelected = selectedDeliveryOption == value;
    return InkWell(
      onTap: () {
        setState(() => selectedDeliveryOption = value);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00695C).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00695C) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? const Color(0xFF00695C) : Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF00695C) : Colors.black,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF00695C),
                size: 22,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: Colors.grey[400],
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}