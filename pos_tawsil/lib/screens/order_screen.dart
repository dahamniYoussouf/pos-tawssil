// lib/screens/order_screen.dart - Version améliorée avec design Tawsil
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../models/menu_item.dart';
import '../config/app_theme.dart';
import 'orders_history_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final DatabaseService _db = DatabaseService();
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _syncAndLoadMenuItems();
  }

  Future<void> _syncAndLoadMenuItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final syncService = context.read<SyncService>();
      await syncService.syncMenuFromApi();
      
      final items = await _db.getMenuItems();
      setState(() {
        _menuItems = items;
        _isLoading = false;
        if (items.isEmpty) {
          _errorMessage = 'Aucun article trouvé. Vérifiez votre connexion API.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TawsilColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A859),
        elevation: 0,
        title: Row(
          children: [
            Image.network(
              'https://i.imgur.com/9KX5ZqH.png',
              height: 32,
              fit: BoxFit.contain,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            const Text('Nouvelle Commande'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrdersHistoryScreen(),
                ),
              );
            },
            tooltip: 'Historique',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _syncAndLoadMenuItems,
            tooltip: 'Synchroniser',
          ),
        ],
      ),
      body: Row(
        children: [
          // Menu Items (Left)
          Expanded(
            flex: 3,
            child: _buildMenuSection(),
          ),
          
          // Order Summary (Right)
          const SizedBox(
            width: 380,
            child: _OrderSummary(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF00A859)),
              ),
            ),
            const SizedBox(height: TawsilSpacing.md),
            Text(
              'Chargement du menu...',
              style: TawsilTextStyles.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: TawsilColors.textSecondary,
            ),
            const SizedBox(height: TawsilSpacing.md),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TawsilTextStyles.bodyMedium,
            ),
            const SizedBox(height: TawsilSpacing.lg),
            ElevatedButton.icon(
              onPressed: _syncAndLoadMenuItems,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A859),
              ),
            ),
          ],
        ),
      );
    }

    if (_menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 64,
              color: TawsilColors.textSecondary,
            ),
            const SizedBox(height: TawsilSpacing.md),
            Text(
              'Aucun article dans le menu',
              style: TawsilTextStyles.bodyMedium,
            ),
            const SizedBox(height: TawsilSpacing.lg),
            ElevatedButton.icon(
              onPressed: _syncAndLoadMenuItems,
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Synchroniser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A859),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(TawsilSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 3,
        mainAxisSpacing: TawsilSpacing.md,
        crossAxisSpacing: TawsilSpacing.md,
        childAspectRatio: 0.85,
      ),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        return _MenuItemCard(menuItem: item);
      },
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem menuItem;

  const _MenuItemCard({required this.menuItem});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: TawsilElevation.sm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
      ),
      child: InkWell(
        onTap: () {
          context.read<OrderProvider>().addItem(menuItem);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${menuItem.nom} ajouté'),
              duration: const Duration(milliseconds: 800),
              backgroundColor: const Color(0xFF00A859),
            ),
          );
        },
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(TawsilBorderRadius.lg),
                  topRight: Radius.circular(TawsilBorderRadius.lg),
                ),
                child: menuItem.photoUrl != null
                    ? Image.network(
                        menuItem.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(TawsilSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      menuItem.nom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TawsilTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${menuItem.prix.toStringAsFixed(0)} DA',
                          style: TawsilTextStyles.priceMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A859),
                            borderRadius: BorderRadius.circular(TawsilBorderRadius.sm),
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF00A859).withOpacity(0.1),
      child: const Center(
        child: Icon(
          Icons.fastfood_rounded,
          size: 48,
          color: Color(0xFF00A859),
        ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary();

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.currentOrder;

    return Container(
      decoration: BoxDecoration(
        color: TawsilColors.surface,
        boxShadow: [
          BoxShadow(
            color: TawsilColors.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(TawsilSpacing.md),
            decoration: const BoxDecoration(
              color: Color(0xFF00A859),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: TawsilSpacing.sm),
                    Text(
                      'Commande',
                      style: TawsilTextStyles.headingMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TawsilSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
                  ),
                  child: Text(
                    '${orderProvider.itemCount}',
                    style: TawsilTextStyles.badge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Items List
          Expanded(
            child: order == null || order.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: TawsilColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: TawsilSpacing.md),
                        Text(
                          'Panier vide',
                          style: TawsilTextStyles.bodyMedium.copyWith(
                            color: TawsilColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: TawsilSpacing.xs),
                        Text(
                          'Ajoutez des articles',
                          style: TawsilTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(TawsilSpacing.sm),
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return _OrderItemTile(item: item);
                    },
                  ),
          ),
          
          // Total & Actions
          Container(
            padding: const EdgeInsets.all(TawsilSpacing.md),
            decoration: BoxDecoration(
              color: TawsilColors.surface,
              boxShadow: [
                BoxShadow(
                  color: TawsilColors.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Total
                Container(
                  padding: const EdgeInsets.all(TawsilSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A859).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL',
                        style: TawsilTextStyles.headingMedium,
                      ),
                      Text(
                        '${orderProvider.total.toStringAsFixed(2)} DA',
                        style: TawsilTextStyles.priceLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TawsilSpacing.md),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: orderProvider.itemCount > 0
                            ? () => orderProvider.cancelOrder()
                            : null,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Annuler'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TawsilColors.error,
                          side: BorderSide(
                            color: orderProvider.itemCount > 0
                                ? TawsilColors.error
                                : TawsilColors.border,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: TawsilSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: orderProvider.itemCount > 0
                            ? () => _completeOrder(context)
                            : null,
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text('Valider'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A859),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(TawsilSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFF00A859).withOpacity(0.1),
                borderRadius: BorderRadius.circular(TawsilBorderRadius.sm),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF00A859),
              ),
            ),
            const SizedBox(width: TawsilSpacing.sm),
            const Text('Confirmer la commande'),
          ],
        ),
        content: const Text('Voulez-vous valider cette commande ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A859),
            ),
            child: const Text('Oui, valider'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<OrderProvider>().completeOrder(
          paymentMethod: 'cash_on_delivery',
          printTicket: true,
          openDrawer: true,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: TawsilSpacing.sm),
                const Text('Commande enregistrée avec succès !'),
              ],
            ),
            backgroundColor: const Color(0xFF00A859),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: TawsilColors.error,
          ),
        );
      }
    }
  }
}

class _OrderItemTile extends StatelessWidget {
  final dynamic item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TawsilSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItemName,
                  style: TawsilTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.prixUnitaire.toStringAsFixed(0)} DA',
                  style: TawsilTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF00A859),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TawsilSpacing.sm),
          
          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              color: TawsilColors.background,
              borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QuantityButton(
                  icon: Icons.remove_rounded,
                  onPressed: () {
                    context.read<OrderProvider>().updateItemQuantity(
                      item.id,
                      item.quantite - 1,
                    );
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TawsilSpacing.sm,
                  ),
                  child: Text(
                    '${item.quantite}',
                    style: TawsilTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.add_rounded,
                  onPressed: () {
                    context.read<OrderProvider>().updateItemQuantity(
                      item.id,
                      item.quantite + 1,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF00A859),
          ),
        ),
      ),
    );
  }
}