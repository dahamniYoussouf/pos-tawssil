// lib/screens/order_screen.dart - Version am├⌐lior├⌐e avec design Tawsil
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/order_provider.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../models/menu_item.dart';
import '../models/order_item_addition.dart';
import '../config/app_theme.dart';
import 'orders_history_screen.dart';
import 'stats_screen.dart';

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
  StreamSubscription<SyncStatus>? _syncSub;

  @override
  void initState() {
    super.initState();

    final syncService = context.read<SyncService>();
    _syncSub = syncService.statusStream.listen((status) async {
      if (status.success && !status.isSyncing) {
        final items = await _db.getMenuItems();
        if (!mounted) return;
        setState(() {
          _menuItems = items;
          _isLoading = false;
          _errorMessage = items.isEmpty
              ? 'Aucun article trouv?. V?rifiez votre connexion API.'
              : null;
        });
      }
    });

    _syncAndLoadMenuItems();
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  Future<void> _syncAndLoadMenuItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 1) Charger imm?diatement le cache local pour afficher les items sans action manuelle
    try {
      final cached = await _db.getMenuItems();
      if (mounted && cached.isNotEmpty) {
        setState(() {
          _menuItems = cached;
          _isLoading = false;
        });
      }
    } catch (_) {
      // ignore cache read errors, we will try after sync
    }

    // 2) Tenter la synchronisation API puis recharger le cache
    try {
      final syncService = context.read<SyncService>();
      await syncService.syncAll();
      
      final items = await _db.getMenuItems();
      if (!mounted) return;
      setState(() {
        _menuItems = items;
        _isLoading = false;
        if (items.isEmpty) {
          _errorMessage = 'Aucun article trouv?. V?rifiez votre connexion API.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_menuItems.isEmpty) {
          _errorMessage = 'Erreur: ${e.toString()}';
        }
      });
    }
  }




  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('cashier_id');
      await prefs.remove('restaurant_id');
      await prefs.remove('cashier_name');
      await prefs.remove('cashier_code');
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de d?connexion: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _syncOrdersOnly() async {
    final syncService = context.read<SyncService>();
    try {
      await syncService.syncOrdersToApi();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commandes synchronis?es'),
          backgroundColor: Color(0xFF00A859),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de sync: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
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
            icon: const Icon(Icons.query_stats_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StatsScreen(),
                ),
              );
            },
            tooltip: 'Statistiques',
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: _syncOrdersOnly,
            tooltip: 'Sync commandes',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'D?connexion',
          ),
        ],
      ),
      body: Column(
        children: [
          const _SyncStatusBanner(),
          Expanded(
            child: Row(
              children: [
                // Menu Items (Left)
                Expanded(
                  flex: 3,
                  child: _buildMenuSection(),
                ),
                
                // Order Summary (Right)
                const Padding(
                  padding: EdgeInsets.only(
                    right: TawsilSpacing.md,
                    top: TawsilSpacing.md,
                    bottom: TawsilSpacing.md,
                  ),
                  child: SizedBox(
                    width: 380,
                    child: _OrderSummary(),
                  ),
                ),
              ],
            ),
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
              label: const Text('R├⌐essayer'),
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
        childAspectRatio: 0.62,
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
    final availableAdditions =
        menuItem.additions.where((a) => a.isAvailable).toList();

    return Card(
      elevation: TawsilElevation.sm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
      ),
      child: InkWell(
        onTap: () => _handleAdd(context),
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(TawsilBorderRadius.lg),
                topRight: Radius.circular(TawsilBorderRadius.lg),
              ),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: menuItem.photoUrl != null
                        ? Image.network(
                            menuItem.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  if (availableAdditions.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A859),
                          borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '+${availableAdditions.length} extras',
                          style: TawsilTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(TawsilSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    menuItem.nom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TawsilTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (availableAdditions.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...availableAdditions.take(3).map((add) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
                              border: Border.all(color: TawsilColors.border),
                              color: TawsilColors.background,
                            ),
                            child: Text(
                              add.nom,
                              style: TawsilTextStyles.bodySmall,
                            ),
                          );
                        }),
                        if (availableAdditions.length > 3)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
                              color: TawsilColors.background,
                              border: Border.all(color: TawsilColors.border),
                            ),
                            child: Text(
                              '+${menuItem.additions.length - 3} autres',
                              style: TawsilTextStyles.bodySmall.copyWith(
                                color: TawsilColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menuItem.prix.isFinite
                                ? '${menuItem.prix.toStringAsFixed(0)} DA'
                                : '-- DA',
                            style: TawsilTextStyles.priceMedium,
                          ),
                          if (availableAdditions.isNotEmpty)
                            Text(
                              'Extras disponibles',
                              style: TawsilTextStyles.bodySmall.copyWith(
                                color: TawsilColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A859),
                          borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _handleAdd(context),
                            borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.add_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
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
      ),
    );
  }

  Future<void> _handleAdd(BuildContext context) async {
    final orderProvider = context.read<OrderProvider>();
    List<OrderItemAddition> selectedAdditions = const [];
    int quantity = 1;

    final hasAvailableAdditions =
        menuItem.additions.any((add) => add.isAvailable);

    if (hasAvailableAdditions) {
      final selection = await _showAdditionsSheet(context, menuItem);
      if (selection == null) return;
      selectedAdditions = selection.additions;
      quantity = selection.quantity;
    }

    orderProvider.addItem(menuItem, additions: selectedAdditions, quantity: quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${menuItem.nom} ajouté'),
        duration: const Duration(milliseconds: 900),
        backgroundColor: const Color(0xFF00A859),
        behavior: SnackBarBehavior.floating,
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
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(TawsilBorderRadius.lg),
          bottomLeft: Radius.circular(TawsilBorderRadius.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(-4, 4),
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
                const Text('Commande enregistr├⌐e avec succ├¿s !'),
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
    final additionsTotal = item.additions.fold<double>(
      0,
      (double sum, OrderItemAddition add) => sum + add.total,
    );
    final lineTotal = (item.prixUnitaire * item.quantite) + additionsTotal;
    final extrasLabel = additionsTotal > 0
        ? ' | Extras +${additionsTotal.toStringAsFixed(0)} DA'
        : '';

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
                if (item.instructionsSpeciales != null &&
                    item.instructionsSpeciales.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.instructionsSpeciales,
                    style: TawsilTextStyles.bodySmall.copyWith(
                      color: TawsilColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (item.additions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: item.additions.map<Widget>((add) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: TawsilColors.background,
                          borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
                          border: Border.all(color: TawsilColors.border),
                        ),
                        child: Text(
                          '${add.nom} x${add.quantity} (+${add.total.toStringAsFixed(0)} DA)',
                          style: TawsilTextStyles.bodySmall,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${lineTotal.toStringAsFixed(0)} DA',
                  style: TawsilTextStyles.priceMedium,
                ),
                Text(
                  'Base ${item.prixUnitaire.toStringAsFixed(0)} DA$extrasLabel',
                  style: TawsilTextStyles.bodySmall.copyWith(
                    color: TawsilColors.textSecondary,
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

Future<_AdditionSelection?> _showAdditionsSheet(
  BuildContext context,
  MenuItem menuItem,
) async {
  final additions = menuItem.additions.where((a) => a.isAvailable).toList();
  int itemQty = 1;
  final Map<String, int> selected = {for (final a in additions) a.id: 0};

  return showModalBottomSheet<_AdditionSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(TawsilBorderRadius.xl)),
    ),
    builder: (context) {
      return SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            final extrasPerUnit = additions.fold<double>(
              0,
              (sum, add) => sum + (add.prix * (selected[add.id] ?? 0)),
            );
            final total = (menuItem.prix + extrasPerUnit) * itemQty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: TawsilSpacing.lg,
                right: TawsilSpacing.lg,
                top: TawsilSpacing.lg,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: menuItem.photoUrl != null
                                ? Image.network(
                                    menuItem.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _additionPlaceholder(),
                                  )
                                : _additionPlaceholder(),
                          ),
                        ),
                        const SizedBox(width: TawsilSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                menuItem.nom,
                                style: TawsilTextStyles.headingMedium,
                              ),
                              if (menuItem.description != null && menuItem.description!.isNotEmpty)
                                Text(
                                  menuItem.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TawsilTextStyles.bodySmall.copyWith(
                                    color: TawsilColors.textSecondary,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '${menuItem.prix.toStringAsFixed(0)} DA',
                                style: TawsilTextStyles.priceMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TawsilSpacing.lg),
                    Text('Quantit?', style: TawsilTextStyles.headingSmall),
                    const SizedBox(height: TawsilSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: TawsilColors.background,
                        borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
                        border: Border.all(color: TawsilColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _QuantityButton(
                            icon: Icons.remove_rounded,
                            onPressed: itemQty > 1
                                ? () => setState(() => itemQty -= 1)
                                : () {},
                          ),
                          Text('$itemQty', style: TawsilTextStyles.headingMedium),
                          _QuantityButton(
                            icon: Icons.add_rounded,
                            onPressed: () => setState(() => itemQty += 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TawsilSpacing.lg),
                    Text('Extras & Suppl?ments', style: TawsilTextStyles.headingSmall),
                    const SizedBox(height: TawsilSpacing.sm),
                    ...additions.map((add) {
                      final qty = selected[add.id] ?? 0;
                      final selectedFlag = qty > 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: TawsilSpacing.sm),
                        padding: const EdgeInsets.all(TawsilSpacing.md),
                        decoration: BoxDecoration(
                          color: selectedFlag ? const Color(0xFF00A859).withOpacity(0.06) : Colors.white,
                          borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                          border: Border.all(
                            color: selectedFlag ? const Color(0xFF00A859) : TawsilColors.border,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() {
                                selected[add.id] = selectedFlag ? 0 : 1;
                              }),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedFlag ? const Color(0xFF00A859) : TawsilColors.border,
                                    width: 2,
                                  ),
                                  color: selectedFlag ? const Color(0xFF00A859).withOpacity(0.2) : Colors.transparent,
                                ),
                                child: selectedFlag
                                    ? const Icon(Icons.check, size: 14, color: Color(0xFF00A859))
                                    : null,
                              ),
                            ),
                            const SizedBox(width: TawsilSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    add.nom,
                                    style: TawsilTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  if (add.description != null && add.description!.isNotEmpty)
                                    Text(
                                      add.description!,
                                      style: TawsilTextStyles.bodySmall.copyWith(
                                        color: TawsilColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: TawsilSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+${add.prix.toStringAsFixed(0)} DA',
                                  style: TawsilTextStyles.bodyMedium.copyWith(
                                    color: const Color(0xFF00A859),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (selectedFlag)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _QuantityButton(
                                          icon: Icons.remove_rounded,
                                          onPressed: qty > 1
                                              ? () => setState(() => selected[add.id] = qty - 1)
                                              : () => setState(() => selected[add.id] = 0),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                          child: Text('$qty', style: TawsilTextStyles.bodyMedium),
                                        ),
                                        _QuantityButton(
                                          icon: Icons.add_rounded,
                                          onPressed: () => setState(() => selected[add.id] = qty + 1),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: TawsilSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(TawsilSpacing.md),
                      decoration: BoxDecoration(
                        color: TawsilColors.background,
                        borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                        border: Border.all(color: TawsilColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: TawsilTextStyles.headingMedium),
                          Text(
                            '${total.toStringAsFixed(0)} DA',
                            style: TawsilTextStyles.priceMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TawsilSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, _AdditionSelection(quantity: 1, additions: const [])),
                            child: const Text('Sans extra'),
                          ),
                        ),
                        const SizedBox(width: TawsilSpacing.sm),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final additionsSelected = additions.where((a) => (selected[a.id] ?? 0) > 0).map((a) {
                                return OrderItemAddition(
                                  additionId: a.id,
                                  nom: a.nom,
                                  prix: a.prix,
                                  quantity: selected[a.id] ?? 1,
                                );
                              }).toList();

                              Navigator.pop(
                                context,
                                _AdditionSelection(
                                  quantity: itemQty,
                                  additions: additionsSelected,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A859),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Ajouter au panier'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TawsilSpacing.md),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}



Widget _additionPlaceholder() {
  return Container(
    color: const Color(0xFF00A859).withOpacity(0.08),
    child: const Center(
      child: Icon(Icons.fastfood_rounded, color: Color(0xFF00A859), size: 28),
    ),
  );
}

class _AdditionSelection {
  final int quantity;
  final List<OrderItemAddition> additions;
  const _AdditionSelection({required this.quantity, required this.additions});
}

class _SyncStatusBanner extends StatelessWidget {
  const _SyncStatusBanner();

  @override
  Widget build(BuildContext context) {
    final syncService = context.read<SyncService>();

    return StreamBuilder<SyncStatus>(
      stream: syncService.statusStream,
      initialData: syncService.currentStatus(),
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (status == null) return const SizedBox.shrink();

        final bool isWarning = !status.success && !status.isSyncing;
        final Color bgColor = status.isSyncing
            ? Colors.blue.shade50
            : (isWarning ? Colors.orange.shade50 : Colors.green.shade50);
        final Color iconColor = status.isSyncing
            ? Colors.blue
            : (isWarning ? Colors.orange : const Color(0xFF00A859));
        final IconData icon = status.isSyncing
            ? Icons.sync_rounded
            : (isWarning ? Icons.wifi_off_rounded : Icons.check_circle_rounded);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: TawsilSpacing.md,
            vertical: TawsilSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              bottom: BorderSide(color: TawsilColors.border),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: TawsilSpacing.sm),
              Expanded(
                child: Text(
                  status.message,
                  style: TawsilTextStyles.bodySmall.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: status.isSyncing ? null : () => syncService.syncAll(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Sync'),
                style: TextButton.styleFrom(
                  foregroundColor: iconColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


