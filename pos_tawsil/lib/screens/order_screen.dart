// lib/screens/order_screen.dart - Version améliorée avec design Tawsil
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/order_provider.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../services/api_service.dart';
import '../models/menu_item.dart';
import '../models/menu_item_promotion.dart';
import '../models/order_item_addition.dart';
import '../models/option_group.dart';
import '../config/app_theme.dart';
import 'orders_history_screen.dart';
import 'printer_settings_screen.dart';
import '../services/print_service.dart';

String _formatMoney(double value) {
  final fractional = (value - value.truncate()).abs();
  if (fractional > 0.001) {
    return value.toStringAsFixed(2);
  }
  return value.toStringAsFixed(0);
}

/// Returns a Material icon for a category name (Pizza, Burger, Salads, etc.)
IconData _categoryIconFromName(String? name, {bool isAll = false}) {
  if (isAll || name == null || name.isEmpty) return Icons.apps_rounded;
  final n = name.toLowerCase();
  if (n.contains('pizza')) return Icons.local_pizza_rounded;
  if (n.contains('burger')) return Icons.lunch_dining_rounded;
  if (n.contains('salad')) return Icons.eco_rounded;
  if (n.contains('dessert')) return Icons.cake_rounded;
  if (n.contains('drink') || n.contains('boisson')) return Icons.local_bar_rounded;
  if (n.contains('tacos')) return Icons.breakfast_dining_rounded;
  if (n.contains('sandwich') || n.contains('sandwish')) return Icons.bakery_dining_rounded;
  if (n.contains('promo')) return Icons.local_offer_rounded;
  return Icons.restaurant_menu_rounded;
}

/// Styled category icon: rounded container, themed colors, no images
Widget _buildCategoryIcon({required String? name, required bool isAll, required bool isSelected}) {
  final iconData = _categoryIconFromName(name, isAll: isAll);
  return Container(
    width: 36,
    height: 36,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: isSelected ? TawsilColors.primary.withOpacity(0.14) : TawsilColors.background,
      border: isSelected ? Border.all(color: TawsilColors.primary.withOpacity(0.35), width: 1.2) : null,
      boxShadow: isSelected ? [BoxShadow(color: TawsilColors.primary.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))] : null,
    ),
    child: Icon(iconData, size: 22, color: isSelected ? TawsilColors.primary : TawsilColors.textSecondary),
  );
}

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final DatabaseService _db = DatabaseService();
  final ApiService _apiService = ApiService();
  List<MenuItem> _menuItems = [];
  List<MenuItem> _filteredMenuItems = [];
  bool _isLoading = true;
  bool _isLoadingDashboard = true;
  String? _dashboardError;
  Map<String, dynamic>? _dashboardData;
  String? _errorMessage;
  StreamSubscription<SyncStatus>? _syncSub;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  Map<String, String> _categoryNames = {}; // Map categoryId -> nom
  Map<String, int> _categoryOrder = {}; // Map categoryId -> display order
  String _serviceType = 'dinein'; // dinein, takeout, delivery
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    final syncService = context.read<SyncService>();
    _syncSub = syncService.statusStream.listen((status) async {
      if (status.success && !status.isSyncing) {
        // Always reload categories when sync completes
        await _loadCategories();
        final restaurantId = await _apiService.getRestaurantId();
        final items = await _db.getMenuItemsForRestaurant(restaurantId);
        if (!mounted) return;
        setState(() {
          _menuItems = items;
          _filteredMenuItems = items;
          _isLoading = false;
          _errorMessage = items.isEmpty
              ? 'Aucun article trouvé. Vérifiez votre connexion API.'
              : null;
        });
        _filterMenuItems();
      }
    });

    _startClock();
    _syncAndLoadMenuItems();
    _loadDashboard();
  }

  Widget _buildSidebar() {
    // Build category list from known names or fallback to IDs present in menu
    final categoryEntries = <MapEntry<String?, String>>[
      const MapEntry(null, 'Toutes catégories')
    ];
    categoryEntries.addAll(_categoryNames.entries);
    if (categoryEntries.isEmpty && _menuItems.isNotEmpty) {
      final ids = _menuItems.map((e) => e.categoryId).toSet().toList();
      for (var i = 0; i < ids.length; i++) {
        categoryEntries.add(MapEntry(ids[i], _getCategoryDisplayName(ids[i])));
      }
    }
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: TawsilColors.surface,
        border: Border(right: BorderSide(color: TawsilColors.border)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                FractionallySizedBox(
                  widthFactor: 0.9,
                  child: Image.asset(
                    'assets/images/logo_green.webp',
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                // Small sync indicator
                const SizedBox(height: 4),
                const _SyncStatusBanner(compact: true),
              ],
            ),
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  // Nav shortcuts
              _SidebarNavButton(
                icon: Icons.receipt_long,
                label: 'Commandes',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OrdersHistoryScreen()),
                  );
                },
              ),
              _SidebarNavButton(
                icon: Icons.print,
                label: 'Imprimantes',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PrinterSettingsScreen()),
                  );
                },
              ),
                  Divider(color: TawsilColors.divider),
                  ...categoryEntries.map((entry) {
                    final isSelected = entry.key == _selectedCategoryId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 6),
                      child: Column(
                        children: [
                          IconButton(
                            icon: _buildCategoryIcon(
                              name: entry.value,
                              isAll: entry.key == null,
                              isSelected: isSelected,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedCategoryId = entry.key;
                              });
                              _filterMenuItems();
                            },
                          ),
                          Text(
                            entry.value,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? TawsilColors.primary
                                  : TawsilColors.textSecondary,
                              fontSize: 12,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          _SidebarNavButton(
            icon: Icons.logout,
            label: 'Logout',
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(String categoryId) {
    // Try to get a readable name from the ID (last part of UUID)
    if (categoryId.length > 8) {
      return 'Catégorie ${categoryId.substring(0, 8)}...';
    }
    return 'Catégorie';
  }

  Future<void> _fetchCategoryNameAsync(String categoryId) async {
    try {
      final name = await _db.getCategoryName(categoryId);
      if (name != null && mounted) {
        setState(() {
          _categoryNames[categoryId] = name;
        });
      }
    } catch (e) {
      print('⚠️ Failed to fetch category name for $categoryId: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final apiService = ApiService();
      final restaurantId = await apiService.getRestaurantId();
      // 1. Try to load from database first
      final categories = await _db.getFoodCategories(restaurantId: restaurantId);
      final categoryMap = <String, String>{};
      final categoryOrder = <String, int>{};
      var orderIndex = 0;

      if (categories.isNotEmpty) {
        for (var cat in categories) {
          final id = cat['id'] as String?;
          final nom = cat['nom'] as String?;
          final rawOrder = cat['ordre_affichage'];
          final orderValue = rawOrder is int
              ? rawOrder
              : int.tryParse(rawOrder?.toString() ?? '');
          if (id != null && nom != null) {
            categoryMap[id] = nom;
            categoryOrder[id] = orderValue ?? (100000 + orderIndex);
            orderIndex++;
          }
        }
      }

      // 2. If no categories in DB, try to fetch from API
      if (categoryMap.isEmpty) {
        try {
          final apiService = ApiService();
          final apiCategories = await apiService.fetchFoodCategories();
          for (var cat in apiCategories) {
            categoryMap[cat.id] = cat.nom;
            categoryOrder[cat.id] = cat.ordreAffichage ?? (100000 + orderIndex);
            orderIndex++;
            // Also save to database for next time
            await _db.insertFoodCategory({
              'id': cat.id,
              'restaurant_id': cat.restaurantId,
              'nom': cat.nom,
              'description': cat.description,
              'icone_url': cat.iconeUrl,
              'ordre_affichage': cat.ordreAffichage,
              'created_at': cat.createdAt.toIso8601String(),
              'updated_at': cat.updatedAt.toIso8601String(),
            });
          }
          print('✅ Fetched ${apiCategories.length} categories from API');
        } catch (e) {
          print('⚠️ Failed to fetch categories from API: $e');
        }
      }

      // 3. Check if we have categories for all menu items
      final menuItems = await _db.getMenuItemsForRestaurant(restaurantId);
      final menuCategoryIds = menuItems.map((item) => item.categoryId).toSet();
      final missingCategoryIds =
          menuCategoryIds.where((id) => !categoryMap.containsKey(id)).toList();

      // Try to fetch missing category names individually
      if (missingCategoryIds.isNotEmpty) {
        for (var catId in missingCategoryIds) {
          try {
            final name = await _db.getCategoryName(catId);
            if (name != null) {
              categoryMap[catId] = name;
              categoryOrder.putIfAbsent(catId, () => 100000 + orderIndex);
              orderIndex++;
            }
          } catch (e) {
            print('⚠️ Could not get name for category $catId: $e');
          }
        }
      }

      // 3. Update state
      if (mounted) {
        setState(() {
          _categoryNames = categoryMap;
          _categoryOrder = categoryOrder;
        });
      }

      print('✅ Loaded ${categoryMap.length} categories');
    } catch (e) {
      print('⚠️ Failed to load categories: $e');
    }
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardError = null;
    });
    try {
      final data = await _apiService.fetchCashierDashboardToday();
      if (!mounted) return;
      setState(() {
        _dashboardData = data;
        _isLoadingDashboard = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dashboardError = e.toString();
        _isLoadingDashboard = false;
      });
    }
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _clockTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  void _filterMenuItems() {
    setState(() {
      _filteredMenuItems = _menuItems.where((item) {
        // Filter by search query
        final matchesSearch = _searchQuery.isEmpty ||
            item.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (item.description
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false);

        // Filter by category
        final matchesCategory = _selectedCategoryId == null ||
            item.categoryId == _selectedCategoryId;

        // Only show available items
        return item.isAvailable && matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _syncAndLoadMenuItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 1) Charger immédiatement le cache local pour afficher les items sans action manuelle
    try {
      await _loadCategories();
      final restaurantId = await _apiService.getRestaurantId();
      final cached = await _db.getMenuItemsForRestaurant(restaurantId);
      if (mounted && cached.isNotEmpty) {
        setState(() {
          _menuItems = cached;
          _filteredMenuItems = cached;
          _isLoading = false;
        });
        _filterMenuItems();
      }
    } catch (_) {
      // ignore cache read errors, we will try after sync
    }

    // 2) Tenter la synchronisation API puis recharger le cache
    try {
      final syncService = context.read<SyncService>();
      await syncService.syncAll();

      final restaurantId = await _apiService.getRestaurantId();
      final items = await _db.getMenuItemsForRestaurant(restaurantId);
      if (!mounted) return;
      await _loadCategories();
      setState(() {
        _menuItems = items;
        _filteredMenuItems = items;
        _isLoading = false;
        if (items.isEmpty) {
          _errorMessage = 'Aucun article trouvé. Vérifiez votre connexion API.';
        }
      });
      _filterMenuItems();
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
          backgroundColor: TawsilColors.primary,
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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    final orderPanelWidth = width > 1200 ? 380.0 : (width > 900 ? 340.0 : 300.0);

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: TawsilColors.background,
        appBar: AppBar(
          backgroundColor: TawsilColors.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            'POS',
            style: TawsilTextStyles.headingMedium.copyWith(
              color: TawsilColors.textPrimary,
            ),
          ),
        ),
        drawer: Drawer(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TawsilSpacing.md,
                vertical: TawsilSpacing.sm,
              ),
              child: _buildSidebarContent(onCategoryTap: () => Navigator.of(context).pop()),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isLoading && _menuItems.isNotEmpty)
                _buildSearchAndFilterBar(),
              Expanded(child: _buildMenuSection()),
            ],
          ),
        ),
        floatingActionButton: _buildOrderFAB(context),
      );
    }

    return Scaffold(
      backgroundColor: TawsilColors.background,
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isLoading && _menuItems.isNotEmpty)
                    _buildSearchAndFilterBar(),
                  Expanded(child: _buildMenuSection()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: TawsilSpacing.md,
                top: TawsilSpacing.md,
                bottom: TawsilSpacing.md,
              ),
              child: SizedBox(
                width: orderPanelWidth,
                child: _OrderSummary(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderFAB(BuildContext context) {
    final count = context.watch<OrderProvider>().itemCount;
    return FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
            height: MediaQuery.of(ctx).size.height * 0.88,
            decoration: const BoxDecoration(
              color: TawsilColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(TawsilBorderRadius.xl)),
            ),
            child: const _OrderSummary(),
          ),
        );
      },
      icon: const Icon(Icons.shopping_cart_rounded),
      label: Text('$count'),
      backgroundColor: TawsilColors.primary,
      foregroundColor: TawsilColors.textOnPrimary,
    );
  }

  Widget _buildSidebarContent({VoidCallback? onCategoryTap}) {
    final categoryEntries = <MapEntry<String?, String>>[
      const MapEntry(null, 'Toutes catégories'),
    ];
    categoryEntries.addAll(_categoryNames.entries);
    if (categoryEntries.isEmpty && _menuItems.isNotEmpty) {
      for (final id in _menuItems.map((e) => e.categoryId).toSet()) {
        categoryEntries.add(MapEntry(id, _getCategoryDisplayName(id)));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: TawsilSpacing.md),
          child: Column(
            children: [
              Image.asset(
                'assets/images/logo_green.webp',
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.point_of_sale, size: 36, color: TawsilColors.primary),
              ),
              const SizedBox(height: TawsilSpacing.sm),
              const _SyncStatusBanner(compact: true),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: TawsilSpacing.xs),
            children: [
              _SidebarNavButton(
                icon: Icons.receipt_long,
                label: 'Commandes',
                onTap: () {
                  onCategoryTap?.call();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersHistoryScreen()));
                },
              ),
              _SidebarNavButton(
                icon: Icons.print,
                label: 'Imprimantes',
                onTap: () {
                  onCategoryTap?.call();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()));
                },
              ),
              Divider(color: TawsilColors.divider),
              ...categoryEntries.map((entry) {
                final isSelected = entry.key == _selectedCategoryId;
                return ListTile(
                  leading: _buildCategoryIcon(
                    name: entry.value,
                    isAll: entry.key == null,
                    isSelected: isSelected,
                  ),
                  title: Text(entry.value, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: isSelected ? TawsilColors.primary : TawsilColors.textSecondary, fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  selected: isSelected,
                  onTap: () {
                    setState(() => _selectedCategoryId = entry.key);
                    _filterMenuItems();
                    onCategoryTap?.call();
                  },
                );
              }),
              Divider(color: TawsilColors.divider),
              _SidebarNavButton(icon: Icons.logout, label: 'Déconnexion', onTap: () => _logout(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    final showClock = MediaQuery.of(context).size.width > 1000;
    final dateText = DateFormat('dd/MM/yyyy').format(_now);
    final timeText = DateFormat('hh:mm:ss a').format(_now);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TawsilSpacing.md,
        vertical: TawsilSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: TawsilColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: TawsilColors.background,
                borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _filterMenuItems();
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un article...',
                  prefixIcon:
                      Icon(Icons.search, color: TawsilColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: TawsilColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            _filterMenuItems();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TawsilSpacing.md,
                    vertical: TawsilSpacing.sm,
                  ),
                ),
              ),
            ),
          ),
          if (showClock) ...[
            const SizedBox(width: TawsilSpacing.md),
            _buildDateTimeChip(
              icon: Icons.calendar_today_outlined,
              label: dateText,
            ),
            const SizedBox(width: TawsilSpacing.sm),
            _buildDateTimeChip(
              icon: Icons.access_time,
              label: timeText,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateTimeChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TawsilColors.background,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
        border: Border.all(color: TawsilColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: TawsilColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TawsilTextStyles.bodySmall.copyWith(
              color: TawsilColors.textPrimary,
              fontWeight: FontWeight.w600,
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
                valueColor:
                    AlwaysStoppedAnimation<Color>(TawsilColors.primary),
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
                backgroundColor: TawsilColors.primary,
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
                backgroundColor: TawsilColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredMenuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: TawsilColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: TawsilSpacing.md),
            Text(
              'Aucun article trouvé',
              style: TawsilTextStyles.headingMedium.copyWith(
                color: TawsilColors.textSecondary,
              ),
            ),
            const SizedBox(height: TawsilSpacing.xs),
            Text(
              'Essayez de modifier votre recherche',
              style: TawsilTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    final groups = _groupMenuItemsByCategory(_filteredMenuItems);
    final w = MediaQuery.of(context).size.width;
    final isPhone = w < 600;
    final columnCount = w < 500 ? 1 : (w > 1400 ? 4 : (w > 900 ? 3 : 2));
    final gridAspectRatio = w < 500 ? 0.72 : (w > 1200 ? 0.65 : (w > 900 ? 0.7 : 0.8));

    return ListView.separated(
      padding: const EdgeInsets.all(TawsilSpacing.md),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: TawsilSpacing.lg),
      itemBuilder: (context, index) {
        final group = groups[index];
        return _buildCategorySection(
          group,
          columnCount,
          gridAspectRatio,
          isPhone: isPhone,
          availableWidth: w,
        );
      },
    );
  }

  List<_CategoryGroup> _groupMenuItemsByCategory(List<MenuItem> items) {
    final grouped = <String, List<MenuItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.categoryId, () => []).add(item);
    }

    final groups = grouped.entries.map((entry) {
      final id = entry.key;
      final groupItems = List<MenuItem>.from(entry.value);
      groupItems.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
      final name = _categoryNames[id] ?? _getCategoryDisplayName(id);
      final order = _categoryOrder[id];
      return _CategoryGroup(id: id, name: name, items: groupItems, order: order);
    }).toList();

    groups.sort((a, b) {
      final orderA = a.order ?? 999999;
      final orderB = b.order ?? 999999;
      if (orderA != orderB) return orderA.compareTo(orderB);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return groups;
  }

  Widget _buildCategorySection(
    _CategoryGroup group,
    int columnCount,
    double gridAspectRatio, {
    required bool isPhone,
    required double availableWidth,
  }
  ) {
    if (isPhone) {
      final itemWidth = (availableWidth * 0.72).clamp(220.0, 320.0).toDouble();
      final itemHeight =
          (itemWidth * 0.75 + 170).clamp(330.0, 440.0).toDouble();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryHeader(group),
          const SizedBox(height: TawsilSpacing.sm),
          SizedBox(
            height: itemHeight,
            child: ListView.separated(
              key: PageStorageKey('category-carousel-${group.id}'),
              scrollDirection: Axis.horizontal,
              physics: const PageScrollPhysics(),
              padding: const EdgeInsets.only(
                left: TawsilSpacing.sm,
                right: TawsilSpacing.md,
              ),
              itemCount: group.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: TawsilSpacing.md),
              itemBuilder: (context, index) {
                final item = group.items[index];
                return SizedBox(
                  width: itemWidth,
                  child: _MenuItemCard(menuItem: item),
                );
              },
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryHeader(group),
        const SizedBox(height: TawsilSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisSpacing: TawsilSpacing.md,
            crossAxisSpacing: TawsilSpacing.md,
            childAspectRatio: gridAspectRatio,
          ),
          itemCount: group.items.length,
          itemBuilder: (context, index) {
            final item = group.items[index];
            return _MenuItemCard(menuItem: item);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryHeader(_CategoryGroup group) {
    final itemCount = group.items.length;
    final itemLabel = itemCount == 1 ? 'article' : 'articles';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TawsilSpacing.md,
        vertical: TawsilSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TawsilColors.surface,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
        border: Border.all(color: TawsilColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: TawsilColors.primary,
              borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
            ),
          ),
          const SizedBox(width: TawsilSpacing.sm),
          Expanded(
            child: Text(
              group.name,
              style: TawsilTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: TawsilColors.primaryLight,
              borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
            ),
            child: Text(
              '$itemCount $itemLabel',
              style: TawsilTextStyles.bodySmall.copyWith(
                color: TawsilColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _CategoryGroup {
  final String id;
  final String name;
  final int? order;
  final List<MenuItem> items;

  const _CategoryGroup({
    required this.id,
    required this.name,
    required this.items,
    this.order,
  });
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem menuItem;

  const _MenuItemCard({required this.menuItem});

  @override
  Widget build(BuildContext context) {
    final availableAdditions =
        menuItem.additions.where((a) => a.isAvailable).toList();
    final activePromotions =
        menuItem.promotions.where((promotion) => promotion.isCurrentlyActive).toList();
    final promotionLabels = _collectPromotionLabels(activePromotions);
    final hasPromotion = menuItem.promotionalPrice != null;
    final infoChips = <Widget>[];

    for (final label in promotionLabels) {
      infoChips.add(_buildPromotionChip(label));
    }

    if (menuItem.tempsPreparation > 0) {
      infoChips.add(
        _buildInfoBubble(
          '${menuItem.tempsPreparation} min',
          icon: Icons.timer,
          background: const Color(0xFFE8F0FF),
          textColor: const Color(0xFF1E3A8A),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: TawsilElevation.sm,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
            side: BorderSide(color: TawsilColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _handleAdd(context),
            borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                      // Highlight active promotion as a badge in the top-right corner
                      if (hasPromotion && promotionLabels.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: TawsilColors.primaryDark,
                              borderRadius: BorderRadius.circular(
                                  TawsilBorderRadius.full),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 1,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_offer_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  promotionLabels.first,
                                  style: TawsilTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Padding(
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
                        if (infoChips.isNotEmpty) ...[
                          const SizedBox(height: TawsilSpacing.xs),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: infoChips,
                          ),
                        ],
                        if (menuItem.description != null &&
                            menuItem.description!.isNotEmpty) ...[
                          const SizedBox(height: TawsilSpacing.xs),
                          Text(
                            menuItem.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TawsilTextStyles.bodySmall.copyWith(
                              color: TawsilColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: TawsilSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasPromotion
                                      ? '${_formatMoney(menuItem.promotionalPrice!)} DA'
                                      : '${_formatMoney(menuItem.prix)} DA',
                                  style: TawsilTextStyles.priceMedium,
                                ),
                                if (hasPromotion)
                                  Text(
                                    '${_formatMoney(menuItem.prix)} DA',
                                    style: TawsilTextStyles.bodySmall.copyWith(
                                      color: TawsilColors.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: TawsilColors.primaryLight,
                                borderRadius: BorderRadius.circular(
                                    TawsilBorderRadius.full),
                                border:
                                    Border.all(color: TawsilColors.primary),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _handleAdd(context),
                                  borderRadius: BorderRadius.circular(
                                      TawsilBorderRadius.full),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      'Ajouter',
                                      style:
                                          TawsilTextStyles.bodySmall.copyWith(
                                        color: TawsilColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoBubble(
    String label, {
    IconData? icon,
    Color? background,
    Color? textColor,
  }) {
    final bubbleColor = background ?? TawsilColors.background;
    final labelColor = textColor ?? TawsilColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
        border: Border.all(color: labelColor.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: labelColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TawsilTextStyles.bodySmall.copyWith(color: labelColor),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAdd(BuildContext context) async {
    final orderProvider = context.read<OrderProvider>();
    List<OrderItemAddition> selectedAdditions = const [];
    int quantity = 1;

    final hasOptionGroups = menuItem.optionGroups.isNotEmpty;
    final hasAvailableAdditions =
        menuItem.additions.any((add) => add.isAvailable);

    if (hasOptionGroups || hasAvailableAdditions) {
      final selection = await _showAdditionsSheet(context, menuItem);
      if (selection == null) return;
      selectedAdditions = selection.additions;
      quantity = selection.quantity;
    }

    orderProvider.addItem(menuItem,
        additions: selectedAdditions, quantity: quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${menuItem.nom} ajouté'),
        duration: const Duration(milliseconds: 900),
        backgroundColor: TawsilColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: TawsilColors.primaryLight,
      child: const Center(
        child: Icon(
          Icons.fastfood_rounded,
          size: 48,
          color: TawsilColors.primary,
        ),
      ),
    );
  }
}

String? _formatPromotionLabel(MenuItemPromotion? promotion) {
  if (promotion == null) return null;
  final label = promotion.displayLabel?.trim();
  if (label?.isNotEmpty == true) return label;
  final description = promotion.description?.trim();
  if (description?.isNotEmpty == true) return description;

  final value = promotion.discountValue;
  if (value != null) {
    final formattedValue =
        value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
    switch (promotion.type.toLowerCase()) {
      case 'percentage':
        return '-$formattedValue%';
      case 'amount':
        final currency = promotion.currency.isEmpty ? 'DA' : promotion.currency;
        return '-$formattedValue $currency';
      default:
        break;
    }
  }

  switch (promotion.type.toLowerCase()) {
    case 'free_delivery':
      return 'Livraison gratuite';
    case 'buy_x_get_y':
      return 'Offre speciale';
    default:
      return promotion.type.isNotEmpty ? promotion.type : 'Promotion';
  }
}

List<String> _collectPromotionLabels(Iterable<MenuItemPromotion> promotions) {
  final labels = <String>[];
  final seen = <String>{};
  for (final promotion in promotions) {
    final label = _formatPromotionLabel(promotion);
    if (label == null) continue;
    final normalized = label.trim();
    if (normalized.isEmpty || !seen.add(normalized)) continue;
    labels.add(normalized);
  }
  return labels;
}

Widget _buildPromotionChip(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: TawsilColors.primaryLight,
      borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
      border: Border.all(color: TawsilColors.primary),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_offer_rounded,
            size: 12, color: TawsilColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TawsilTextStyles.bodySmall.copyWith(
            color: TawsilColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE7F7EE),
              child: Icon(icon, color: const Color(0xFF10A05C)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TawsilTextStyles.bodySmall
                        .copyWith(color: TawsilColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TawsilTextStyles.headingMedium
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _TrendingItem {
  final String? id;
  final String name;
  final double price;
  final String? photoUrl;
  final int? quantity;

  _TrendingItem({
    this.id,
    required this.name,
    required this.price,
    this.photoUrl,
    this.quantity,
  });

  factory _TrendingItem.fromMap(Map<String, dynamic> map) {
    return _TrendingItem(
      id: map['id']?.toString(),
      name: map['name'] ?? 'Article',
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      photoUrl: map['photo_url'] as String?,
      quantity:
          map['quantity'] is num ? (map['quantity'] as num).toInt() : null,
    );
  }
}

class _SidebarNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SidebarNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: TawsilColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TawsilColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: TawsilColors.primary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: TawsilColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderSummary extends StatefulWidget {
  const _OrderSummary();

  @override
  State<_OrderSummary> createState() => _OrderSummaryState();
}

class _OrderSummaryState extends State<_OrderSummary> {
  StreamSubscription<PrintStatus>? _printStatusSub;
  PrintStatus _printStatus = PrintStatus();

  @override
  void initState() {
    super.initState();
    // Écouter le statut d'impression
    final printService = PrintService();
    _printStatusSub = printService.statusStream.listen((status) {
      final isNoPrinterConfigured = status.lastError != null &&
          status.lastError!.toLowerCase().contains('aucune imprimante configurée');
      if (mounted) {
        setState(() {
          _printStatus = status;
        });
        
        // Afficher les notifications avec détails
        if (status.lastError != null && !status.isPrinting && !isNoPrinterConfigured) {
          // Extraire le message principal et les solutions
          final errorParts = status.lastError!.split('\n\n');
          final mainMessage = errorParts.isNotEmpty ? errorParts[0] : status.lastError!;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: TawsilSpacing.sm),
                      Expanded(
                        child: Text(
                          mainMessage,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (errorParts.length > 1) ...[
                    const SizedBox(height: TawsilSpacing.xs),
                    Text(
                      errorParts[1],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
              backgroundColor: TawsilColors.error,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'Détails',
                textColor: Colors.white,
                onPressed: () {
                  _showErrorDetails(context, status.lastError!);
                },
              ),
            ),
          );
        } else if (status.lastSuccess && !status.isPrinting && status.queueLength == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: TawsilSpacing.sm),
                  const Text('Tickets imprimés avec succès'),
                ],
              ),
              backgroundColor: TawsilColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _printStatusSub?.cancel();
    super.dispose();
  }

  void _showErrorDetails(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: TawsilColors.error),
            SizedBox(width: TawsilSpacing.sm),
            Text('Détails de l\'erreur'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            errorMessage,
            style: TawsilTextStyles.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.currentOrder;
    final totalBefore = orderProvider.totalBeforePromotions;
    final totalAfter = orderProvider.totalAfterPromotions;
    final hasPromoTotals = (totalBefore - totalAfter).abs() > 0.01;
    final noPrinterConfigured = _printStatus.lastError != null &&
        _printStatus.lastError!.toLowerCase().contains('aucune imprimante configurée');

    return Container(
      decoration: BoxDecoration(
        color: TawsilColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(TawsilBorderRadius.lg),
          bottomLeft: Radius.circular(TawsilBorderRadius.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: TawsilColors.shadow,
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
            decoration: BoxDecoration(
              color: TawsilColors.surface,
              border: Border(
                bottom: BorderSide(color: TawsilColors.divider),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart_rounded,
                      color: TawsilColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: TawsilSpacing.sm),
                    Text(
                      'Commande',
                      style: TawsilTextStyles.headingMedium.copyWith(
                        color: TawsilColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TawsilSpacing.sm,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      if (noPrinterConfigured)
                        Tooltip(
                          message: 'Imprimante non configurée',
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: TawsilColors.error.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: TawsilColors.error),
                            ),
                            child: const Icon(
                              Icons.print,
                              size: 14,
                              color: TawsilColors.error,
                            ),
                          ),
                        ),
                      if (noPrinterConfigured)
                        const SizedBox(width: TawsilSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TawsilSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: TawsilColors.primaryLight,
                          borderRadius:
                              BorderRadius.circular(TawsilBorderRadius.full),
                        ),
                        child: Text(
                          '${orderProvider.itemCount}',
                          style: TawsilTextStyles.badge.copyWith(
                            color: TawsilColors.primary,
                          ),
                        ),
                      ),
                    ],
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
                : Builder(
                    builder: (context) {
                      final sortedItems = List.from(order.items)
                        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                      return ListView.separated(
                        padding: const EdgeInsets.all(TawsilSpacing.sm),
                        itemCount: sortedItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final item = sortedItems[index];
                          return _OrderItemTile(item: item, index: index);
                        },
                      );
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
                // Indicateur de statut d'impression
                if (_printStatus.isPrinting || _printStatus.queueLength > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: TawsilSpacing.md),
                    padding: const EdgeInsets.all(TawsilSpacing.sm),
                    decoration: BoxDecoration(
                      color: TawsilColors.primaryLight,
                      borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                      border: Border.all(color: TawsilColors.primary),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(TawsilColors.primary),
                          ),
                        ),
                        const SizedBox(width: TawsilSpacing.sm),
                        Expanded(
                          child: Text(
                            _printStatus.isPrinting
                                ? 'Impression en cours${_printStatus.currentPrinter != null ? " (${_printStatus.currentPrinter})" : ""}...'
                                : '${_printStatus.queueLength} impression(s) en attente',
                            style: TawsilTextStyles.bodySmall.copyWith(
                              color: TawsilColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Total
                Container(
                  padding: const EdgeInsets.all(TawsilSpacing.md),
                  decoration: BoxDecoration(
                    color: TawsilColors.primaryLight,
                    borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'TOTAL',
                        style: TawsilTextStyles.headingMedium,
                      ),
                      const SizedBox(height: TawsilSpacing.xs),
                      Text(
                        '${_formatMoney(hasPromoTotals ? totalAfter : orderProvider.total)} DA',
                        style: TawsilTextStyles.priceLarge,
                      ),
                      if (hasPromoTotals) ...[
                        const SizedBox(height: TawsilSpacing.xs),
                        Text(
                          'Sous-total avant réduction: ${_formatMoney(totalBefore)} DA',
                          style: TawsilTextStyles.bodySmall.copyWith(
                            color: TawsilColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Économie: ${_formatMoney(totalBefore - totalAfter)} DA',
                          style: TawsilTextStyles.bodySmall.copyWith(
                            color: TawsilColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                        onPressed: orderProvider.itemCount > 0 && !orderProvider.isProcessing
                            ? () => _completeOrder(context)
                            : null,
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text('Valider'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TawsilColors.primaryDark,
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
    final orderProvider = context.read<OrderProvider>();
    if (orderProvider.isProcessing) {
      return;
    }

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
                color: TawsilColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TawsilBorderRadius.sm),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: TawsilColors.primary,
              ),
            ),
            const SizedBox(width: TawsilSpacing.sm),
            const Expanded(
              child: Text(
                'Confirmer la commande',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
              backgroundColor: TawsilColors.primary,
            ),
            child: const Text('Oui, valider'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (orderProvider.isProcessing) return;
        await orderProvider.completeOrder(
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
                const Expanded(
                  child: Text(
                    'Commande enregistrée avec succès !',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: TawsilColors.primary,
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
  final int index;

  const _OrderItemTile({required this.item, required this.index});

  Widget _buildItemPlaceholder() {
    return const Center(
      child: Icon(
        Icons.fastfood_rounded,
        size: 20,
        color: TawsilColors.primary,
      ),
    );
  }

  Widget _buildItemImage(String? url) {
    final hasUrl = url != null && url.trim().isNotEmpty;
    return ClipOval(
      child: Container(
        width: 60,
        height: 60,
        color: TawsilColors.primaryLight,
        child: hasUrl
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildItemPlaceholder(),
              )
            : _buildItemPlaceholder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final promoUnit = item.promotionalPrice ?? item.prixUnitaire;
    final baseLineTotal = (item.prixUnitaire * item.quantite) + item.additionsTotal;
    final promoLineTotal = (promoUnit * item.quantite) + item.additionsTotal;
    final hasPromo = item.promotionalPrice != null &&
        (promoLineTotal - baseLineTotal).abs() > 0.01;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final priceColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_formatMoney(promoLineTotal)} DA',
              style: TawsilTextStyles.priceMedium,
            ),
            if (hasPromo) ...[
              const SizedBox(height: 2),
              Text(
                '${_formatMoney(baseLineTotal)} DA',
                style: TawsilTextStyles.bodySmall.copyWith(
                  color: TawsilColors.textSecondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        );

        return Container(
          padding: const EdgeInsets.all(TawsilSpacing.sm),
          decoration: BoxDecoration(
            color: TawsilColors.surface,
            borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
            border: Border.all(color: TawsilColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular image with green quantity badge
                  Stack(
                    children: [
                      _buildItemImage(item.photoUrl),
                      Positioned(
                        top: -2,
                        left: -2,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: TawsilColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${item.quantite}',
                              style: TawsilTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.menuItemName,
                                style: TawsilTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              iconSize: 20,
                              color: TawsilColors.textSecondary,
                              onPressed: () =>
                                  context.read<OrderProvider>().removeItem(item.id),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Quantity selector centered below name
                        Center(
                          child: Container(
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
                                    context
                                        .read<OrderProvider>()
                                        .updateItemQuantity(item.id, item.quantite - 1);
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                    context
                                        .read<OrderProvider>()
                                        .updateItemQuantity(item.id, item.quantite + 1);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (item.instructionsSpeciales != null &&
                            item.instructionsSpeciales!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.instructionsSpeciales!,
                            style: TawsilTextStyles.bodySmall.copyWith(
                              color: TawsilColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 12),
                    // Price aligned to the right
                    priceColumn,
                  ],
                ],
              ),
              if (isNarrow) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: priceColumn,
                ),
              ],
              // Additions chips below the main row
              if (item.additions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.additions.map<Widget>((add) {
                    final contrib = add.prix * add.quantity * item.quantite;
                    final qtyPart = add.quantity > 1 ? ' ×${add.quantity}' : '';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: TawsilColors.background,
                        borderRadius:
                            BorderRadius.circular(TawsilBorderRadius.full),
                        border: Border.all(color: TawsilColors.border),
                      ),
                      child: Text(
                        '${add.nom}$qtyPart ${contrib < 0.01 ? "Inclus" : "+${_formatMoney(contrib)} DA"}',
                        style: TawsilTextStyles.bodySmall,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
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
          // Slightly larger touch target and icon for + / - buttons
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: TawsilColors.primary,
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
  final availableAdditions =
      menuItem.additions.where((a) => a.isAvailable).toList();
  final groups = <OptionGroup>[];

  if (menuItem.optionGroups.isNotEmpty) {
    for (final group in menuItem.optionGroups) {
      final filtered = group.additions.where((a) => a.isAvailable).toList();
      groups.add(group.copyWith(additions: filtered));
    }
  }

  final groupedIds = groups
      .expand((group) => group.additions)
      .map((addition) => addition.id)
      .toSet();
  final ungrouped = availableAdditions
      .where((addition) =>
          addition.optionGroupId == null ||
          addition.optionGroupId!.isEmpty ||
          !groupedIds.contains(addition.id))
      .toList();
  if (ungrouped.isNotEmpty) {
    groups.add(OptionGroup(
      id: 'ungrouped-${menuItem.id}',
      menuItemId: menuItem.id,
      nom: 'Extras',
      isRequired: false,
      additions: ungrouped,
    ));
  }

  groups.sort((a, b) {
    final ao = a.ordreAffichage ?? 9999;
    final bo = b.ordreAffichage ?? 9999;
    if (ao != bo) return ao.compareTo(bo);
    return a.nom.compareTo(b.nom);
  });

  final additions = groups.expand((group) => group.additions).toList();
  int itemQty = 1;
  final Map<String, int> selected = {for (final a in additions) a.id: 0};

  return showModalBottomSheet<_AdditionSelection>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(TawsilBorderRadius.xl)),
    ),
    builder: (context) {
      return SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            final extrasPerUnit = additions.fold<double>(
              0,
              (sum, add) => sum + (add.prix * (selected[add.id] ?? 0)),
            );
            final missingRequiredGroups = groups
                .where((group) => group.isRequired)
                .where((group) =>
                    !group.additions
                        .any((add) => (selected[add.id] ?? 0) > 0))
                .toList();
            final hasRequiredGroups = groups.any((group) => group.isRequired);
            final canSubmit = missingRequiredGroups.isEmpty;
            final promoUnitPrice = menuItem.promotionalPrice ?? menuItem.prix;
            final hasPromotion = menuItem.promotionalPrice != null &&
                (menuItem.prix - promoUnitPrice).abs() > 0.01;
            final promoTotal = (promoUnitPrice + extrasPerUnit) * itemQty;
            final baseTotal = (menuItem.prix + extrasPerUnit) * itemQty;
            final activePromotions =
                menuItem.promotions.where((promotion) => promotion.isCurrentlyActive).toList();
            final promoLabels = _collectPromotionLabels(activePromotions);
            final total = promoTotal;

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
                          borderRadius:
                              BorderRadius.circular(TawsilBorderRadius.md),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: menuItem.photoUrl != null
                                ? Image.network(
                                    menuItem.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _additionPlaceholder(),
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
                              if (menuItem.description != null &&
                                  menuItem.description!.isNotEmpty)
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
                                '${_formatMoney(promoUnitPrice)} DA',
                                style: TawsilTextStyles.priceMedium,
                              ),
                              if (hasPromotion)
                                Text(
                                  '${_formatMoney(menuItem.prix)} DA',
                                  style: TawsilTextStyles.bodySmall.copyWith(
                                    color: TawsilColors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              if (promoLabels.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: promoLabels
                                        .map(_buildPromotionChip)
                                        .toList(),
                                  ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: TawsilColors.background,
                        borderRadius:
                            BorderRadius.circular(TawsilBorderRadius.full),
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
                          Text('$itemQty',
                              style: TawsilTextStyles.headingMedium),
                          _QuantityButton(
                            icon: Icons.add_rounded,
                            onPressed: () => setState(() => itemQty += 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TawsilSpacing.lg),
                    Text('Options', style: TawsilTextStyles.headingSmall),
                    const SizedBox(height: TawsilSpacing.sm),
                    if (groups.isEmpty)
                      Text(
                        'Aucune option disponible.',
                        style: TawsilTextStyles.bodySmall.copyWith(
                          color: TawsilColors.textSecondary,
                        ),
                      ),
                    ...groups.map((group) {
                      final isMissing = group.isRequired &&
                          !group.additions.any(
                              (add) => (selected[add.id] ?? 0) > 0);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: TawsilSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    group.nom,
                                    style: TawsilTextStyles.bodyMedium
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (group.isRequired)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: TawsilColors.error.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Obligatoire',
                                      style: TawsilTextStyles.bodySmall.copyWith(
                                        color: TawsilColors.error,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (group.description != null &&
                                group.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  group.description!,
                                  style: TawsilTextStyles.bodySmall.copyWith(
                                    color: TawsilColors.textSecondary,
                                  ),
                                ),
                              ),
                            if (group.additions.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Aucune option dans ce groupe.',
                                  style: TawsilTextStyles.bodySmall.copyWith(
                                    color: TawsilColors.textSecondary,
                                  ),
                                ),
                              ),
                            if (isMissing)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Selection requise.',
                                  style: TawsilTextStyles.bodySmall.copyWith(
                                    color: TawsilColors.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            const SizedBox(height: TawsilSpacing.sm),
                            ...group.additions.map((add) {
                              final qty = selected[add.id] ?? 0;
                              final selectedFlag = qty > 0;
                              final isRequired = group.isRequired;
                              return InkWell(
                                onTap: () => setState(() {
                                  if (isRequired) {
                                    for (final o in group.additions) {
                                      selected[o.id] = 0;
                                    }
                                    selected[add.id] = 1;
                                  } else {
                                    selected[add.id] = selectedFlag ? 0 : 1;
                                  }
                                }),
                                borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                                child: Container(
                                  margin: const EdgeInsets.only(
                                      bottom: TawsilSpacing.sm),
                                  padding: const EdgeInsets.all(TawsilSpacing.md),
                                  decoration: BoxDecoration(
                                    color: selectedFlag
                                        ? TawsilColors.primary.withOpacity(0.06)
                                        : Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(TawsilBorderRadius.md),
                                    border: Border.all(
                                      color: selectedFlag
                                          ? TawsilColors.primary
                                          : TawsilColors.border,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: selectedFlag
                                                ? TawsilColors.primary
                                                : TawsilColors.border,
                                            width: 2,
                                          ),
                                          color: selectedFlag
                                              ? TawsilColors.primary.withOpacity(0.2)
                                              : Colors.transparent,
                                        ),
                                        child: selectedFlag
                                            ? const Icon(Icons.check,
                                                size: 14,
                                                color: TawsilColors.primary)
                                            : null,
                                      ),
                                    const SizedBox(width: TawsilSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            add.nom,
                                            style: TawsilTextStyles.bodyMedium
                                                .copyWith(
                                                    fontWeight: FontWeight.w600),
                                          ),
                                          if (add.description != null &&
                                              add.description!.isNotEmpty)
                                            Text(
                                              add.description!,
                                              style: TawsilTextStyles.bodySmall
                                                  .copyWith(
                                                color:
                                                    TawsilColors.textSecondary,
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
                                          add.prix > 0
                                              ? '+${add.prix.toStringAsFixed(0)} DA'
                                              : 'Inclus',
                                          style:
                                              TawsilTextStyles.bodyMedium.copyWith(
                                            color: TawsilColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (!isRequired && selectedFlag)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: () {}, // Absorb taps to prevent card toggle
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  _QuantityButton(
                                                    icon: Icons.remove_rounded,
                                                    onPressed: qty > 1
                                                        ? () => setState(() =>
                                                            selected[add.id] =
                                                                qty - 1)
                                                        : () => setState(() =>
                                                            selected[add.id] = 0),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 6),
                                                    child: Text('$qty',
                                                        style: TawsilTextStyles
                                                            .bodyMedium),
                                                  ),
                                                  _QuantityButton(
                                                    icon: Icons.add_rounded,
                                                    onPressed: () => setState(() =>
                                                        selected[add.id] = qty + 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                            }).toList(),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: TawsilSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(TawsilSpacing.md),
                      decoration: BoxDecoration(
                        color: TawsilColors.background,
                        borderRadius:
                            BorderRadius.circular(TawsilBorderRadius.md),
                        border: Border.all(color: TawsilColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Total', style: TawsilTextStyles.headingMedium),
                          const SizedBox(height: TawsilSpacing.xs),
                          Text(
                            '${_formatMoney(total)} DA',
                            style: TawsilTextStyles.priceMedium,
                          ),
                          if (hasPromotion) ...[
                            const SizedBox(height: TawsilSpacing.xs),
                            Text(
                              'Avant promo: ${_formatMoney(baseTotal)} DA',
                              style: TawsilTextStyles.bodySmall.copyWith(
                                color: TawsilColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: TawsilSpacing.md),
                    Row(
                      children: [
                        if (!hasRequiredGroups)
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(
                                  context,
                                  _AdditionSelection(
                                      quantity: itemQty, additions: const [])),
                              child: const Text('Sans extra'),
                            ),
                          ),
                        if (!hasRequiredGroups)
                          const SizedBox(width: TawsilSpacing.sm),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canSubmit
                                ? () {
                                  final additionsSelected = additions
                                      .where((a) => (selected[a.id] ?? 0) > 0)
                                      .map((a) {
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
                                }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TawsilColors.primaryDark,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              minimumSize: const Size(double.infinity, 56),
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
    color: TawsilColors.primaryLight,
    child: const Center(
      child: Icon(Icons.fastfood_rounded, color: TawsilColors.primary, size: 28),
    ),
  );
}

class _AdditionSelection {
  final int quantity;
  final List<OrderItemAddition> additions;
  const _AdditionSelection({required this.quantity, required this.additions});
}

class _SyncStatusBanner extends StatelessWidget {
  final bool compact;
  const _SyncStatusBanner({this.compact = false});

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
            : (isWarning ? Colors.orange : TawsilColors.primary);
        final IconData icon = status.isSyncing
            ? Icons.sync_rounded
            : (isWarning ? Icons.wifi_off_rounded : Icons.check_circle_rounded);

        final String displayMessage = compact
            ? (status.isSyncing
                ? 'Sync...'
                : (isWarning ? 'Hors ligne' : 'OK'))
            : status.message;

        final padding = compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
            : const EdgeInsets.symmetric(
                horizontal: TawsilSpacing.md, vertical: TawsilSpacing.sm);
        return Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            border: compact
                ? null
                : Border(
                    bottom: BorderSide(color: TawsilColors.border),
                  ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: compact ? 16 : 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  displayMessage,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TawsilTextStyles.bodySmall.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w700,
                    fontSize:
                        compact ? 11 : TawsilTextStyles.bodySmall.fontSize,
                  ),
                ),
              ),
              if (!compact)
                TextButton.icon(
                  onPressed:
                      status.isSyncing ? null : () => syncService.syncAll(),
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



