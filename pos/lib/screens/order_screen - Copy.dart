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
  if (n.contains('drink') || n.contains('boisson'))
    return Icons.local_bar_rounded;
  if (n.contains('tacos')) return Icons.breakfast_dining_rounded;
  if (n.contains('sandwich') || n.contains('sandwish'))
    return Icons.bakery_dining_rounded;
  if (n.contains('promo')) return Icons.local_offer_rounded;
  return Icons.restaurant_menu_rounded;
}

/// Styled category icon: rounded container, themed colors, no images
Widget _buildCategoryIcon(
    {required String? name, required bool isAll, required bool isSelected}) {
  final iconData = _categoryIconFromName(name, isAll: isAll);
  return Container(
    width: 36,
    height: 36,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: isSelected
          ? TawsilColors.primary.withOpacity(0.14)
          : TawsilColors.background,
      border: isSelected
          ? Border.all(
              color: TawsilColors.primary.withOpacity(0.35), width: 1.2)
          : null,
      boxShadow: isSelected
          ? [
              BoxShadow(
                  color: TawsilColors.primary.withOpacity(0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ]
          : null,
    ),
    child: Icon(iconData,
        size: 22,
        color: isSelected ? TawsilColors.primary : TawsilColors.textSecondary),
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
  bool _hasInitializedCategorySelection = false;
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
        final items = await _getCurrentRestaurantMenuItems();
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
    final categoryEntries = _buildCategoryEntries();
    return Container(
      width: 96,
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
                                _hasInitializedCategorySelection = true;
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
            label: 'Déconnexion',
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

  List<MapEntry<String?, String>> _buildCategoryEntries({
    Map<String, String>? categoryNames,
    Map<String, int>? categoryOrder,
    Iterable<String>? categoryIds,
  }) {
    final names = categoryNames ?? _categoryNames;
    final orders = categoryOrder ?? _categoryOrder;
    final ids = <String>[
      ...?categoryIds?.toSet(),
    ];

    if (ids.isEmpty) {
      if (_menuItems.isNotEmpty) {
        ids.addAll(_menuItems.map((item) => item.categoryId).toSet());
      } else {
        ids.addAll(names.keys);
      }
    }

    ids.sort((a, b) {
      final orderA = orders[a] ?? 999999;
      final orderB = orders[b] ?? 999999;
      if (orderA != orderB) return orderA.compareTo(orderB);
      final nameA = names[a] ?? _getCategoryDisplayName(a);
      final nameB = names[b] ?? _getCategoryDisplayName(b);
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    });

    final entries = ids
        .map((id) => MapEntry<String?, String>(
              id,
              names[id] ?? _getCategoryDisplayName(id),
            ))
        .toList();

    entries.add(const MapEntry(null, 'Toutes catégories'));
    return entries;
  }

  String? _resolveSelectedCategoryId({
    required String? currentSelection,
    required bool hasInitializedSelection,
    Map<String, String>? categoryNames,
    Map<String, int>? categoryOrder,
    Iterable<String>? categoryIds,
  }) {
    final entries = _buildCategoryEntries(
      categoryNames: categoryNames,
      categoryOrder: categoryOrder,
      categoryIds: categoryIds,
    );
    final realEntries = entries.where((entry) => entry.key != null).toList();

    if (realEntries.isEmpty) return null;

    final validIds = realEntries.map((entry) => entry.key!).toSet();
    if (currentSelection != null && validIds.contains(currentSelection)) {
      return currentSelection;
    }

    if (hasInitializedSelection && currentSelection == null) {
      return null;
    }

    return null;
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

  Future<List<MenuItem>> _getCurrentRestaurantMenuItems() async {
    final restaurantId = await _apiService.getRestaurantId();
    if (restaurantId == null || restaurantId.isEmpty) {
      return _db.getMenuItems();
    }
    return _db.getMenuItemsForRestaurant(restaurantId);
  }

  Future<void> _loadCategories() async {
    try {
      final apiService = ApiService();
      final restaurantId = await apiService.getRestaurantId();
      // 1. Try to load from database first
      final categories =
          await _db.getFoodCategories(restaurantId: restaurantId);
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
      final menuItems = await _db.getMenuItems();
      final menuCategoryIds = menuItems.map((item) => item.categoryId).toSet();
      final missingCategoryIds =
          menuCategoryIds.where((id) => !categoryMap.containsKey(id)).toList();

      // Recover missing category rows locally when sync is incomplete.
      if (missingCategoryIds.isNotEmpty) {
        for (var catId in missingCategoryIds) {
          String? resolvedName;
          try {
            resolvedName = await _db.getCategoryName(catId);
          } catch (e) {
            print('⚠️ Could not get name for category $catId: $e');
          }

          final fallbackName = resolvedName ?? _getCategoryDisplayName(catId);
          categoryMap[catId] = fallbackName;
          categoryOrder.putIfAbsent(catId, () => 100000 + orderIndex);
          orderIndex++;

          if (resolvedName == null &&
              restaurantId != null &&
              restaurantId.isNotEmpty) {
            final now = DateTime.now().toIso8601String();
            await _db.insertFoodCategory({
              'id': catId,
              'restaurant_id': restaurantId,
              'nom': fallbackName,
              'description': null,
              'icone_url': null,
              'ordre_affichage': categoryOrder[catId],
              'created_at': now,
              'updated_at': now,
            });
          }
        }
      }

      // 3. Update state
      if (mounted) {
        setState(() {
          _categoryNames = categoryMap;
          _categoryOrder = categoryOrder;
          _selectedCategoryId = _resolveSelectedCategoryId(
            currentSelection: _selectedCategoryId,
            hasInitializedSelection: _hasInitializedCategorySelection,
            categoryNames: categoryMap,
            categoryOrder: categoryOrder,
            categoryIds: menuCategoryIds,
          );
          _hasInitializedCategorySelection =
              _selectedCategoryId != null || _hasInitializedCategorySelection;
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
      final cached = await _getCurrentRestaurantMenuItems();
      if (mounted && cached.isNotEmpty) {
        setState(() {
          _menuItems = cached;
          _filteredMenuItems = cached;
          _selectedCategoryId = _resolveSelectedCategoryId(
            currentSelection: _selectedCategoryId,
            hasInitializedSelection: _hasInitializedCategorySelection,
            categoryIds: cached.map((item) => item.categoryId),
          );
          _hasInitializedCategorySelection =
              _selectedCategoryId != null || _hasInitializedCategorySelection;
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

      final items = await _getCurrentRestaurantMenuItems();
      if (!mounted) return;
      await _loadCategories();
      setState(() {
        _menuItems = items;
        _filteredMenuItems = items;
        _selectedCategoryId = _resolveSelectedCategoryId(
          currentSelection: _selectedCategoryId,
          hasInitializedSelection: _hasInitializedCategorySelection,
          categoryIds: items.map((item) => item.categoryId),
        );
        _hasInitializedCategorySelection =
            _selectedCategoryId != null || _hasInitializedCategorySelection;
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
    final orderPanelWidth = width > 1500
        ? 292.0
        : (width > 1200 ? 272.0 : (width > 900 ? 248.0 : 300.0));

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
              child: _buildSidebarContent(
                  onCategoryTap: () => Navigator.of(context).pop()),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              ),
              child: SizedBox(
                width: orderPanelWidth,
                child: const _OrderSummary(),
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
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(TawsilBorderRadius.xl)),
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
    final categoryEntries = _buildCategoryEntries();
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
                errorBuilder: (_, __, ___) => Icon(Icons.point_of_sale,
                    size: 36, color: TawsilColors.primary),
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
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OrdersHistoryScreen()));
                },
              ),
              _SidebarNavButton(
                icon: Icons.print,
                label: 'Imprimantes',
                onTap: () {
                  onCategoryTap?.call();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrinterSettingsScreen()));
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
                  title: Text(entry.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isSelected
                              ? TawsilColors.primary
                              : TawsilColors.textSecondary,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal)),
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = entry.key;
                      _hasInitializedCategorySelection = true;
                    });
                    _filterMenuItems();
                    onCategoryTap?.call();
                  },
                );
              }),
              Divider(color: TawsilColors.divider),
              _SidebarNavButton(
                  icon: Icons.logout,
                  label: 'Déconnexion',
                  onTap: () => _logout(context)),
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
                    vertical: TawsilSpacing.md,
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
                valueColor: AlwaysStoppedAnimation<Color>(TawsilColors.primary),
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

    final w = MediaQuery.of(context).size.width;
    final groups = _groupMenuItemsByCategory(_filteredMenuItems);
    final isPhone = w < 700;
    final desktopPanelWidth =
        w > 1500 ? 292.0 : (w > 1200 ? 272.0 : (w > 900 ? 248.0 : 300.0));
    final desktopContentWidth =
        w - 96 - desktopPanelWidth - (TawsilSpacing.md * 2);
    final columnCount = isPhone ? (w < 430 ? 1 : 2) : 4;
    final mainAxisExtent = isPhone
        ? (w < 430 ? 248.0 : 228.0)
        : (desktopContentWidth >= 1180
            ? 164.0
            : (desktopContentWidth >= 980 ? 156.0 : 148.0));

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _buildCategorySection(
          group,
          columnCount,
          mainAxisExtent,
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
      groupItems
          .sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
      final name = _categoryNames[id] ?? _getCategoryDisplayName(id);
      final order = _categoryOrder[id];
      return _CategoryGroup(
          id: id, name: name, items: groupItems, order: order);
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
    double mainAxisExtent, {
    required bool isPhone,
    required double availableWidth,
  }) {
    if (isPhone) {
      final itemWidth = availableWidth < 430
          ? (availableWidth - (TawsilSpacing.md * 2))
          : ((availableWidth - (TawsilSpacing.md * 3)) / 2)
              .clamp(210.0, 270.0)
              .toDouble();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryHeader(group),
          const SizedBox(height: TawsilSpacing.sm),
          SizedBox(
            height: mainAxisExtent,
            child: ListView.separated(
              key: PageStorageKey('category-carousel-${group.id}'),
              scrollDirection: Axis.horizontal,
              physics: const PageScrollPhysics(),
              padding: const EdgeInsets.only(
                left: TawsilSpacing.sm,
                right: TawsilSpacing.md,
              ),
              itemCount: group.items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: TawsilSpacing.md),
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

    final paddedItemCount = group.items.isEmpty
        ? 0
        : group.items.length +
            ((columnCount - (group.items.length % columnCount)) % columnCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryHeader(group),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            mainAxisExtent: mainAxisExtent,
          ),
          itemCount: paddedItemCount,
          itemBuilder: (context, index) {
            if (index >= group.items.length) {
              return const SizedBox.shrink();
            }
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
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: TawsilColors.surface,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              group.name,
              style: TawsilTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: TawsilColors.primaryLight,
              borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
            ),
            child: Text(
              '$itemCount $itemLabel',
              style: TawsilTextStyles.bodySmall.copyWith(
                color: TawsilColors.primaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 10,
                height: 1,
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
    final activePromotions = menuItem.promotions
        .where((promotion) => promotion.isCurrentlyActive)
        .toList();
    final promotionLabels = _collectPromotionLabels(activePromotions);
    final hasPromotion = menuItem.promotionalPrice != null;
    final promotionLabel =
        promotionLabels.isNotEmpty ? promotionLabels.first : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 225;
        final imageHeight = isCompact ? 78.0 : 84.0;
        final horizontalPadding = isCompact ? 6.0 : 7.0;
        final verticalPadding = 5.0;

        return Card(
          elevation: 1,
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
                SizedBox(
                  height: imageHeight,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(TawsilBorderRadius.lg),
                      topRight: Radius.circular(TawsilBorderRadius.lg),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        menuItem.photoUrl != null
                            ? Image.network(
                                menuItem.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                        if (hasPromotion && promotionLabel != null)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8506B),
                                borderRadius: BorderRadius.circular(
                                  TawsilBorderRadius.full,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.14),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                promotionLabel,
                                style: TawsilTextStyles.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 8.2,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    verticalPadding,
                    horizontalPadding,
                    verticalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        menuItem.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TawsilTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: isCompact ? 10 : 10.4,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hasPromotion
                                      ? '${_formatMoney(menuItem.promotionalPrice!)} DA'
                                      : '${_formatMoney(menuItem.prix)} DA',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TawsilTextStyles.priceMedium.copyWith(
                                    fontSize: isCompact ? 11.2 : 11.6,
                                    height: 1,
                                  ),
                                ),
                                if (hasPromotion)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1.5),
                                    child: Text(
                                      '${_formatMoney(menuItem.prix)} DA',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          TawsilTextStyles.bodySmall.copyWith(
                                        color: TawsilColors.textSecondary,
                                        decoration: TextDecoration.lineThrough,
                                        fontSize: isCompact ? 7.8 : 8.2,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 3),
                          Container(
                            width: isCompact ? 26 : 28,
                            height: isCompact ? 26 : 28,
                            decoration: BoxDecoration(
                              color: TawsilColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: TawsilColors.primary.withOpacity(0.7),
                                width: 1.2,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _handleAdd(context),
                                borderRadius: BorderRadius.circular(
                                  10,
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  size: isCompact ? 16 : 18,
                                  color: TawsilColors.primary,
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
          status.lastError!
              .toLowerCase()
              .contains('aucune imprimante configurée');
      if (mounted) {
        setState(() {
          _printStatus = status;
        });

        // Afficher les notifications avec détails
        if (status.lastError != null &&
            !status.isPrinting &&
            !isNoPrinterConfigured) {
          // Extraire le message principal et les solutions
          final errorParts = status.lastError!.split('\n\n');
          final mainMessage =
              errorParts.isNotEmpty ? errorParts[0] : status.lastError!;

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
        } else if (status.lastSuccess &&
            !status.isPrinting &&
            status.queueLength == 0) {
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
        _printStatus.lastError!
            .toLowerCase()
            .contains('aucune imprimante configurée');

    return Container(
      decoration: BoxDecoration(
        color: TawsilColors.surface,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
        border: Border.all(color: TawsilColors.border),
        boxShadow: [
          BoxShadow(
            color: TawsilColors.shadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              TawsilSpacing.md,
              TawsilSpacing.sm,
              TawsilSpacing.sm,
              TawsilSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: TawsilColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(TawsilBorderRadius.lg),
              ),
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
                      size: 18,
                    ),
                    const SizedBox(width: TawsilSpacing.sm),
                    Text(
                      'Commande',
                      style: TawsilTextStyles.headingMedium.copyWith(
                        color: TawsilColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (noPrinterConfigured)
                      Tooltip(
                        message: 'Imprimante non configurée',
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: TawsilColors.error.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: TawsilColors.error),
                          ),
                          child: const Icon(
                            Icons.print_disabled_rounded,
                            size: 13,
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
              ],
            ),
          ),
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
                            fontWeight: FontWeight.w600,
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
                        padding: const EdgeInsets.fromLTRB(
                          6,
                          6,
                          6,
                          0,
                        ),
                        itemCount: sortedItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 3),
                        itemBuilder: (context, index) {
                          final item = sortedItems[index];
                          return _OrderItemTile(item: item, index: index);
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              TawsilSpacing.sm,
              TawsilSpacing.sm,
              TawsilSpacing.sm,
              TawsilSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: TawsilColors.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(TawsilBorderRadius.lg),
              ),
              border: Border(
                top: BorderSide(color: TawsilColors.divider),
              ),
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
                if (_printStatus.isPrinting || _printStatus.queueLength > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: TawsilSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: TawsilColors.primaryLight,
                      borderRadius:
                          BorderRadius.circular(TawsilBorderRadius.md),
                      border: Border.all(color: TawsilColors.primary),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              TawsilColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: TawsilSpacing.sm),
                        Expanded(
                          child: Text(
                            _printStatus.isPrinting
                                ? 'Impression en cours...'
                                : '${_printStatus.queueLength} impression(s) en attente',
                            style: TawsilTextStyles.bodySmall.copyWith(
                              color: TawsilColors.primaryDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: TawsilColors.primaryLight,
                    borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'À payer',
                            style: TawsilTextStyles.headingMedium.copyWith(
                              color: TawsilColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${_formatMoney(hasPromoTotals ? totalAfter : orderProvider.total)} DA',
                                  maxLines: 1,
                                  style:
                                      TawsilTextStyles.displayMedium.copyWith(
                                    color: TawsilColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (hasPromoTotals) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Avant promo: ${_formatMoney(totalBefore)} DA',
                          style: TawsilTextStyles.bodySmall.copyWith(
                            color: TawsilColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 11.5,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Économie: ${_formatMoney(totalBefore - totalAfter)} DA',
                          style: TawsilTextStyles.bodySmall.copyWith(
                            color: TawsilColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                            height: 1.05,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: TawsilSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: orderProvider.itemCount > 0 &&
                                !orderProvider.isProcessing
                            ? () => orderProvider.cancelOrder()
                            : null,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text(
                          'Annuler',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TawsilColors.textSecondary,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: TawsilColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(0, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(TawsilBorderRadius.md),
                          ),
                          textStyle: TawsilTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: TawsilSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: orderProvider.itemCount > 0 &&
                                !orderProvider.isProcessing
                            ? () => _completeOrder(context)
                            : null,
                        icon: Icon(
                          orderProvider.isProcessing
                              ? Icons.hourglass_top_rounded
                              : Icons.check_rounded,
                          size: 18,
                        ),
                        label: Text(
                          orderProvider.isProcessing
                              ? 'Traitement...'
                              : 'Valider',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TawsilColors.primaryLight,
                          foregroundColor: TawsilColors.primaryDark,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(0, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(TawsilBorderRadius.md),
                          ),
                          textStyle: TawsilTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
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
        size: 16,
        color: TawsilColors.primary,
      ),
    );
  }

  Widget _buildItemImage(String? url) {
    final hasUrl = url != null && url.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
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

  String _buildDetailsSummary() {
    final parts = <String>[];

    if (item.additions.isNotEmpty) {
      final additionsSummary = item.additions.map<String>((add) {
        final qtyPart = add.quantity > 1 ? 'x${add.quantity} ' : '';
        return '$qtyPart${add.nom}';
      }).join(', ');
      if (additionsSummary.isNotEmpty) {
        parts.add(additionsSummary);
      }
    }

    final instructions = item.instructionsSpeciales?.trim();
    if (instructions != null && instructions.isNotEmpty) {
      parts.add(instructions);
    }

    return parts.join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    final promoUnit = item.promotionalPrice ?? item.prixUnitaire;
    final baseLineTotal =
        (item.prixUnitaire * item.quantite) + item.additionsTotal;
    final promoLineTotal = (promoUnit * item.quantite) + item.additionsTotal;
    final hasPromo = item.promotionalPrice != null &&
        (promoLineTotal - baseLineTotal).abs() > 0.01;
    final detailSummary = _buildDetailsSummary();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: TawsilColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TawsilColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildItemImage(item.photoUrl),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            item.menuItemName,
                            style: TawsilTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              height: 1.05,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (hasPromo)
                          Text(
                            '${_formatMoney(baseLineTotal)}',
                            style: TawsilTextStyles.bodySmall.copyWith(
                              color: TawsilColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 9.5,
                            ),
                          ),
                        if (hasPromo) const SizedBox(width: 4),
                        Text(
                          '${_formatMoney(promoLineTotal)} DA',
                          style: TawsilTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: TawsilColors.textPrimary,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(width: 2),
                        InkResponse(
                          onTap: () =>
                              context.read<OrderProvider>().removeItem(item.id),
                          radius: 14,
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: TawsilColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  detailSummary.isNotEmpty ? detailSummary : 'Article standard',
                  style: TawsilTextStyles.bodySmall.copyWith(
                    color: TawsilColors.textSecondary,
                    fontStyle: item.instructionsSpeciales != null &&
                            item.instructionsSpeciales!.trim().isNotEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                    fontSize: 10,
                    height: 1.05,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: TawsilColors.background,
                  borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                  border: Border.all(color: TawsilColors.border),
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
                      buttonSize: 18,
                      iconSize: 11,
                      borderRadius: 6,
                      backgroundColor: Colors.white,
                      borderColor: TawsilColors.border,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        '${item.quantite}',
                        style: TawsilTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          height: 1,
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
                      buttonSize: 18,
                      iconSize: 11,
                      borderRadius: 6,
                      backgroundColor: Colors.white,
                      borderColor: TawsilColors.border,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.additions.isNotEmpty && detailSummary.isEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: item.additions.map<Widget>((add) {
                final contrib = add.prix * add.quantity * item.quantite;
                final qtyPart = add.quantity > 1 ? ' ×${add.quantity}' : '';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TawsilColors.background,
                    borderRadius:
                        BorderRadius.circular(TawsilBorderRadius.full),
                    border: Border.all(color: TawsilColors.border),
                  ),
                  child: Text(
                    '${add.nom}$qtyPart ${contrib < 0.01 ? "Inclus" : "+${_formatMoney(contrib)} DA"}',
                    style: TawsilTextStyles.bodySmall.copyWith(
                      fontSize: 10.5,
                      height: 1,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double buttonSize;
  final double iconSize;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    this.buttonSize = 34,
    this.iconSize = 18,
    this.borderRadius,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final resolvedRadius = borderRadius ?? TawsilBorderRadius.sm;
    final resolvedIconColor = enabled
        ? (iconColor ?? TawsilColors.primary)
        : TawsilColors.textSecondary.withOpacity(0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(resolvedRadius),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.transparent,
            borderRadius: BorderRadius.circular(resolvedRadius),
            border: borderColor == null
                ? null
                : Border.all(
                    color:
                        enabled ? borderColor! : borderColor!.withOpacity(0.35),
                  ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: iconSize,
            color: resolvedIconColor,
          ),
        ),
      ),
    );
  }
}

Future<_AdditionSelection?> _showAdditionsSheetLegacy(
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
    backgroundColor: Colors.transparent,
    builder: (context) {
      return SafeArea(
        top: false,
        child: StatefulBuilder(
          builder: (context, setState) {
            final mediaQuery = MediaQuery.of(context);
            final screenWidth = mediaQuery.size.width;
            final screenHeight = mediaQuery.size.height;
            final isDesktop = screenWidth >= 960;
            final maxHeight = screenHeight * (isDesktop ? 0.86 : 0.9);
            final horizontalPadding = isDesktop ? 28.0 : 20.0;
            final activePromotions = menuItem.promotions
                .where((promotion) => promotion.isCurrentlyActive)
                .toList();
            final promoLabels = _collectPromotionLabels(activePromotions);
            final extrasPerUnit = additions.fold<double>(
              0,
              (sum, add) => sum + (add.prix * (selected[add.id] ?? 0)),
            );
            final missingRequiredGroups = groups
                .where((group) => group.isRequired)
                .where((group) =>
                    !group.additions.any((add) => (selected[add.id] ?? 0) > 0))
                .toList();
            final canSubmit = missingRequiredGroups.isEmpty;
            final promoUnitPrice = menuItem.promotionalPrice ?? menuItem.prix;
            final hasPromotion = menuItem.promotionalPrice != null &&
                (menuItem.prix - promoUnitPrice).abs() > 0.01;
            final total = (promoUnitPrice + extrasPerUnit) * itemQty;
            final baseTotal = (menuItem.prix + extrasPerUnit) * itemQty;

            void toggleAddition(OptionGroup group, dynamic add) {
              setState(() {
                final currentQty = selected[add.id] ?? 0;
                if (group.isRequired) {
                  for (final option in group.additions) {
                    selected[option.id] = 0;
                  }
                  selected[add.id] = 1;
                  return;
                }
                selected[add.id] = currentQty > 0 ? 0 : 1;
              });
            }

            void updateAdditionQuantity(dynamic add, int nextQty) {
              setState(() {
                selected[add.id] = nextQty < 0 ? 0 : nextQty;
              });
            }

            Widget buildGroupBadge(
              String label, {
              required Color backgroundColor,
              required Color textColor,
            }) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
                ),
                child: Text(
                  label,
                  style: TawsilTextStyles.bodySmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    letterSpacing: 0.2,
                  ),
                ),
              );
            }

            Widget buildSelectionIndicator({
              required bool isSelected,
              required bool isRequired,
            }) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: isRequired ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: isRequired
                      ? null
                      : BorderRadius.circular(TawsilBorderRadius.sm + 3),
                  color: isSelected ? TawsilColors.primary : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? TawsilColors.primary
                        : TawsilColors.textHint.withOpacity(0.6),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      )
                    : null,
              );
            }

            Widget buildOptionTile(OptionGroup group, dynamic add) {
              final qty = selected[add.id] ?? 0;
              final isSelected = qty > 0;
              final isRequired = group.isRequired;
              final hasDescription =
                  add.description != null && add.description!.isNotEmpty;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => toggleAddition(group, add),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFFF1F7F3) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? TawsilColors.primary
                              : TawsilColors.border,
                          width: isSelected ? 1.4 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildSelectionIndicator(
                            isSelected: isSelected,
                            isRequired: isRequired,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  add.nom,
                                  style: TawsilTextStyles.headingSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (hasDescription)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      add.description!,
                                      style:
                                          TawsilTextStyles.bodySmall.copyWith(
                                        color: TawsilColors.textSecondary,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                add.prix > 0
                                    ? '+${_formatMoney(add.prix)} DA'
                                    : 'Inclus',
                                style: TawsilTextStyles.bodyMedium.copyWith(
                                  color: add.prix > 0
                                      ? TawsilColors.success
                                      : TawsilColors.textSecondary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (!isRequired && isSelected) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TawsilColors.background,
                                    borderRadius: BorderRadius.circular(
                                      TawsilBorderRadius.full,
                                    ),
                                    border:
                                        Border.all(color: TawsilColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _QuantityButton(
                                        icon: Icons.remove_rounded,
                                        onPressed: qty > 1
                                            ? () => updateAdditionQuantity(
                                                  add,
                                                  qty - 1,
                                                )
                                            : () => updateAdditionQuantity(
                                                  add,
                                                  0,
                                                ),
                                        buttonSize: 28,
                                        iconSize: 16,
                                        backgroundColor: Colors.white,
                                        borderColor: TawsilColors.border,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text(
                                          '$qty',
                                          style: TawsilTextStyles.bodyMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      _QuantityButton(
                                        icon: Icons.add_rounded,
                                        onPressed: () => updateAdditionQuantity(
                                          add,
                                          qty + 1,
                                        ),
                                        buttonSize: 28,
                                        iconSize: 16,
                                        backgroundColor: Colors.white,
                                        borderColor: TawsilColors.border,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            Widget buildGroupSection(OptionGroup group, double width) {
              final isMissing = group.isRequired &&
                  !group.additions.any((add) => (selected[add.id] ?? 0) > 0);

              return SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            group.nom.toUpperCase(),
                            style: TawsilTextStyles.headingMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        buildGroupBadge(
                          group.isRequired ? 'REQUIS' : 'Multiple',
                          backgroundColor: group.isRequired
                              ? TawsilColors.primaryLight
                              : Colors.white,
                          textColor: group.isRequired
                              ? TawsilColors.primaryDark
                              : TawsilColors.textSecondary,
                        ),
                      ],
                    ),
                    if (group.description != null &&
                        group.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 10),
                        child: Text(
                          group.description!,
                          style: TawsilTextStyles.bodySmall.copyWith(
                            color: TawsilColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 10),
                    if (isMissing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Selection requise',
                          style: TawsilTextStyles.bodySmall.copyWith(
                            color: TawsilColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (group.additions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(TawsilSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: TawsilColors.border),
                        ),
                        child: Text(
                          'Aucune option disponible dans ce groupe.',
                          style: TawsilTextStyles.bodySmall.copyWith(
                            color: TawsilColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      ...group.additions.map((add) => buildOptionTile(
                            group,
                            add,
                          )),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: mediaQuery.viewInsets.bottom,
                left: isDesktop ? 24 : 0,
                right: isDesktop ? 24 : 0,
                top: isDesktop ? 24 : 0,
              ),
              child: Align(
                alignment:
                    isDesktop ? Alignment.center : Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1380 : double.infinity,
                    maxHeight: maxHeight,
                  ),
                  child: ClipRRect(
                    borderRadius: isDesktop
                        ? BorderRadius.circular(28)
                        : const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                    child: Material(
                      color: Colors.white,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            isDesktop ? 26 : 20,
                            horizontalPadding,
                            isDesktop ? 24 : 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: SizedBox(
                                      width: isDesktop ? 88 : 72,
                                      height: isDesktop ? 88 : 72,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          menuItem.nom,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TawsilTextStyles.headingLarge
                                              .copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontSize: isDesktop ? 22 : 18,
                                          ),
                                        ),
                                        if (menuItem.description != null &&
                                            menuItem.description!.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(
                                              menuItem.description!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TawsilTextStyles.bodyMedium
                                                  .copyWith(
                                                color:
                                                    TawsilColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              '${_formatMoney(promoUnitPrice)} DA',
                                              style: TawsilTextStyles.priceLarge
                                                  .copyWith(
                                                color: TawsilColors.success,
                                                fontSize: isDesktop ? 20 : 18,
                                              ),
                                            ),
                                            if (hasPromotion)
                                              Text(
                                                '${_formatMoney(menuItem.prix)} DA',
                                                style: TawsilTextStyles
                                                    .bodySmall
                                                    .copyWith(
                                                  color: TawsilColors
                                                      .textSecondary,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                            if (menuItem.tempsPreparation > 0)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      TawsilColors.background,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    TawsilBorderRadius.full,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.schedule_rounded,
                                                      size: 14,
                                                      color: TawsilColors
                                                          .textSecondary,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '${menuItem.tempsPreparation} min',
                                                      style: TawsilTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                        color: TawsilColors
                                                            .textSecondary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (promoLabels.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 10),
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: promoLabels
                                                  .map(_buildPromotionChip)
                                                  .toList(),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.close_rounded),
                                    splashRadius: 22,
                                  ),
                                ],
                              ),
                              const SizedBox(height: TawsilSpacing.sm),
                              Row(
                                children: [
                                  Text(
                                    'QUANTITE',
                                    style: TawsilTextStyles.bodySmall.copyWith(
                                      color: TawsilColors.textSecondary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: TawsilColors.background,
                                      borderRadius: BorderRadius.circular(
                                          TawsilBorderRadius.full),
                                      border: Border.all(
                                          color: TawsilColors.success),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _QuantityButton(
                                          icon: Icons.remove_rounded,
                                          onPressed: itemQty > 1
                                              ? () =>
                                                  setState(() => itemQty -= 1)
                                              : null,
                                          buttonSize: isDesktop ? 56 : 42,
                                          iconSize: isDesktop ? 24 : 18,
                                          backgroundColor: Colors.white,
                                          borderColor: TawsilColors.success,
                                          iconColor: TawsilColors.success,
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isDesktop ? 18 : 14,
                                          ),
                                          child: Text(
                                            '$itemQty',
                                            style: TawsilTextStyles.headingLarge
                                                .copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        _QuantityButton(
                                          icon: Icons.add_rounded,
                                          onPressed: () =>
                                              setState(() => itemQty += 1),
                                          buttonSize: isDesktop ? 56 : 42,
                                          iconSize: isDesktop ? 24 : 18,
                                          backgroundColor: Colors.white,
                                          borderColor: TawsilColors.success,
                                          iconColor: TawsilColors.success,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: TawsilSpacing.lg),
                              Text('OPTIONS',
                                  style: TawsilTextStyles.headingSmall),
                              const SizedBox(height: TawsilSpacing.sm),
                              if (groups.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.all(TawsilSpacing.md),
                                  decoration: BoxDecoration(
                                    color: TawsilColors.background,
                                    borderRadius: BorderRadius.circular(
                                        TawsilBorderRadius.md),
                                    border:
                                        Border.all(color: TawsilColors.border),
                                  ),
                                  child: Text(
                                    'Aucune option disponible.',
                                    style: TawsilTextStyles.bodySmall.copyWith(
                                      color: TawsilColors.textSecondary,
                                    ),
                                  ),
                                ),
                              if (groups.isNotEmpty)
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final maxWidth = constraints.maxWidth;
                                    final columns = maxWidth >= 1180
                                        ? 4
                                        : (maxWidth >= 860
                                            ? 3
                                            : (maxWidth >= 560 ? 2 : 1));
                                    final spacing = TawsilSpacing.lg;
                                    final groupWidth = columns == 1
                                        ? maxWidth
                                        : (maxWidth -
                                                (spacing * (columns - 1))) /
                                            columns;

                                    return Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(
                                        TawsilSpacing.lg,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F7F5),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: TawsilColors.divider,
                                        ),
                                      ),
                                      child: Wrap(
                                        spacing: spacing,
                                        runSpacing: spacing,
                                        children: groups
                                            .map(
                                              (group) => buildGroupSection(
                                                group,
                                                groupWidth,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: TawsilSpacing.lg),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: TawsilSpacing.lg,
                                  vertical: TawsilSpacing.lg,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: isDesktop
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'TOTAL',
                                                  style: TawsilTextStyles
                                                      .bodySmall
                                                      .copyWith(
                                                    color: TawsilColors
                                                        .textSecondary,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 0.9,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '${_formatMoney(total)} DA',
                                                  style: TawsilTextStyles
                                                      .displayLarge
                                                      .copyWith(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                if (hasPromotion)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 4,
                                                    ),
                                                    child: Text(
                                                      'Avant promo: ${_formatMoney(baseTotal)} DA',
                                                      style: TawsilTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                        color: TawsilColors
                                                            .textSecondary,
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                      ),
                                                    ),
                                                  ),
                                                if (!canSubmit)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                      top: 8,
                                                    ),
                                                    child: Text(
                                                      'Completez les choix requis pour continuer.',
                                                      style: TawsilTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                        color:
                                                            TawsilColors.error,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                              width: TawsilSpacing.xl),
                                          SizedBox(
                                            width: 360,
                                            height: 74,
                                            child: ElevatedButton.icon(
                                              onPressed: canSubmit
                                                  ? () {
                                                      final additionsSelected =
                                                          additions
                                                              .where((a) =>
                                                                  (selected[a
                                                                          .id] ??
                                                                      0) >
                                                                  0)
                                                              .map((a) {
                                                        return OrderItemAddition(
                                                          additionId: a.id,
                                                          nom: a.nom,
                                                          prix: a.prix,
                                                          quantity:
                                                              selected[a.id] ??
                                                                  1,
                                                        );
                                                      }).toList();

                                                      Navigator.of(context).pop(
                                                        _AdditionSelection(
                                                          quantity: itemQty,
                                                          additions:
                                                              additionsSelected,
                                                        ),
                                                      );
                                                    }
                                                  : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    TawsilColors.success,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                textStyle: TawsilTextStyles
                                                    .buttonLarge
                                                    .copyWith(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.shopping_cart_outlined,
                                                size: 24,
                                              ),
                                              label: const Text(
                                                'Ajouter au panier',
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            'TOTAL',
                                            style: TawsilTextStyles.bodySmall
                                                .copyWith(
                                              color: TawsilColors.textSecondary,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.9,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${_formatMoney(total)} DA',
                                            style: TawsilTextStyles
                                                .displayMedium
                                                .copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          if (hasPromotion)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                'Avant promo: ${_formatMoney(baseTotal)} DA',
                                                style: TawsilTextStyles
                                                    .bodySmall
                                                    .copyWith(
                                                  color: TawsilColors
                                                      .textSecondary,
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                            ),
                                          if (!canSubmit)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Text(
                                                'Completez les choix requis pour continuer.',
                                                style: TawsilTextStyles
                                                    .bodySmall
                                                    .copyWith(
                                                  color: TawsilColors.error,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            height: 60,
                                            child: ElevatedButton.icon(
                                              onPressed: canSubmit
                                                  ? () {
                                                      final additionsSelected =
                                                          additions
                                                              .where((a) =>
                                                                  (selected[a
                                                                          .id] ??
                                                                      0) >
                                                                  0)
                                                              .map((a) {
                                                        return OrderItemAddition(
                                                          additionId: a.id,
                                                          nom: a.nom,
                                                          prix: a.prix,
                                                          quantity:
                                                              selected[a.id] ??
                                                                  1,
                                                        );
                                                      }).toList();

                                                      Navigator.of(context).pop(
                                                        _AdditionSelection(
                                                          quantity: itemQty,
                                                          additions:
                                                              additionsSelected,
                                                        ),
                                                      );
                                                    }
                                                  : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    TawsilColors.success,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                ),
                                                textStyle: TawsilTextStyles
                                                    .buttonLarge
                                                    .copyWith(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.shopping_cart_outlined,
                                                size: 22,
                                              ),
                                              label: const Text(
                                                'Ajouter au panier',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: TawsilSpacing.md),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
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

  return showModalBottomSheet<_AdditionSelection>(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(
      minWidth: MediaQuery.of(context).size.width,
      maxWidth: MediaQuery.of(context).size.width,
    ),
    backgroundColor: Colors.transparent,
    builder: (context) => _AdditionsSheetDialog(
      menuItem: menuItem,
      groups: groups,
      additions: additions,
    ),
  );
}

Widget _additionPlaceholder() {
  return Container(
    color: TawsilColors.primaryLight,
    child: const Center(
      child:
          Icon(Icons.fastfood_rounded, color: TawsilColors.primary, size: 28),
    ),
  );
}

class _AdditionSelection {
  final int quantity;
  final List<OrderItemAddition> additions;
  const _AdditionSelection({required this.quantity, required this.additions});
}

class _AdditionsSheetDialog extends StatefulWidget {
  final MenuItem menuItem;
  final List<OptionGroup> groups;
  final List<dynamic> additions;

  const _AdditionsSheetDialog({
    required this.menuItem,
    required this.groups,
    required this.additions,
  });

  @override
  State<_AdditionsSheetDialog> createState() => _AdditionsSheetDialogState();
}

class _AdditionsSheetDialogState extends State<_AdditionsSheetDialog> {
  late final Map<String, int> _selected;
  int _itemQty = 1;

  @override
  void initState() {
    super.initState();
    _selected = {for (final addition in widget.additions) addition.id: 0};
  }

  List<MenuItemPromotion> get _activePromotions => widget.menuItem.promotions
      .where((promotion) => promotion.isCurrentlyActive)
      .toList();

  List<String> get _promoLabels => _collectPromotionLabels(_activePromotions);

  double get _extrasPerUnit => widget.additions.fold<double>(
        0,
        (sum, add) => sum + (add.prix * (_selected[add.id] ?? 0)),
      );

  List<OptionGroup> get _missingRequiredGroups => widget.groups
      .where((group) => group.isRequired)
      .where((group) =>
          !group.additions.any((add) => (_selected[add.id] ?? 0) > 0))
      .toList();

  bool get _canSubmit => _missingRequiredGroups.isEmpty;

  double get _promoUnitPrice =>
      widget.menuItem.promotionalPrice ?? widget.menuItem.prix;

  bool get _hasPromotion =>
      widget.menuItem.promotionalPrice != null &&
      (widget.menuItem.prix - _promoUnitPrice).abs() > 0.01;

  double get _total => (_promoUnitPrice + _extrasPerUnit) * _itemQty;

  double get _baseTotal => (widget.menuItem.prix + _extrasPerUnit) * _itemQty;

  bool get _hasImage =>
      widget.menuItem.photoUrl != null &&
      widget.menuItem.photoUrl!.trim().isNotEmpty;

  int _resolveDesktopColumns() {
    if (widget.groups.isEmpty) return 1;
    if (widget.groups.length <= 4) return widget.groups.length;
    return 4;
  }

  double _estimateGroupWeight(OptionGroup group) {
    final hasDescription =
        group.description != null && group.description!.trim().isNotEmpty;
    final selectedExtras = group.additions
        .where((add) => !group.isRequired && (_selected[add.id] ?? 0) > 0)
        .length;

    return group.additions.length +
        (group.isRequired ? 0.6 : 0.0) +
        (hasDescription ? 0.35 : 0.0) +
        (selectedExtras * 0.5);
  }

  List<List<OptionGroup>> _buildBalancedDesktopColumns(int requestedColumns) {
    if (widget.groups.isEmpty) {
      return const [
        <OptionGroup>[],
      ];
    }

    final maxColumns = widget.groups.length < 4 ? widget.groups.length : 4;
    final columnCount = requestedColumns < 1
        ? 1
        : (requestedColumns > maxColumns ? maxColumns : requestedColumns);

    final columns = List.generate(columnCount, (_) => <OptionGroup>[]);
    final weights = List<double>.filled(columnCount, 0);
    for (final group in widget.groups) {
      var targetIndex = 0;
      for (var i = 1; i < columnCount; i++) {
        if (weights[i] < weights[targetIndex]) {
          targetIndex = i;
        }
      }
      columns[targetIndex].add(group);
      weights[targetIndex] += _estimateGroupWeight(group);
    }

    return columns;
  }

  Widget _buildDesktopGroups({required bool dense}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final columns = _buildBalancedDesktopColumns(_resolveDesktopColumns());

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 4),
          child: SizedBox(
            width: constraints.maxWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var columnIndex = 0;
                    columnIndex < columns.length;
                    columnIndex++) ...[
                  if (columnIndex > 0) const SizedBox(width: spacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var itemIndex = 0;
                            itemIndex < columns[columnIndex].length;
                            itemIndex++) ...[
                          _buildGroupSection(
                            columns[columnIndex][itemIndex],
                            dense: dense,
                          ),
                          if (itemIndex < columns[columnIndex].length - 1)
                            const SizedBox(height: spacing),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleAddition(OptionGroup group, dynamic add) {
    setState(() {
      final currentQty = _selected[add.id] ?? 0;
      if (group.isRequired) {
        for (final option in group.additions) {
          _selected[option.id] = 0;
        }
        _selected[add.id] = 1;
        return;
      }
      _selected[add.id] = currentQty > 0 ? 0 : 1;
    });
  }

  void _updateAdditionQuantity(dynamic add, int nextQty) {
    setState(() {
      _selected[add.id] = nextQty < 0 ? 0 : nextQty;
    });
  }

  void _submit() {
    if (!_canSubmit) return;
    final additionsSelected = widget.additions
        .where((a) => (_selected[a.id] ?? 0) > 0)
        .map((a) => OrderItemAddition(
              additionId: a.id,
              nom: a.nom,
              prix: a.prix,
              quantity: _selected[a.id] ?? 1,
            ))
        .toList();

    Navigator.of(context).pop(
      _AdditionSelection(
        quantity: _itemQty,
        additions: additionsSelected,
      ),
    );
  }

  Widget _buildHeaderChip(
    String label, {
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final resolvedBackground = backgroundColor ?? const Color(0xFFF3F4F7);
    final resolvedTextColor = textColor ?? TawsilColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: resolvedBackground,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: resolvedTextColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TawsilTextStyles.bodySmall.copyWith(
              color: resolvedTextColor,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupBadge(OptionGroup group) {
    if (!group.isRequired) {
      return Text(
        'Multiple',
        style: TawsilTextStyles.bodySmall.copyWith(
          color: TawsilColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: TawsilColors.primaryLight,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
        border: Border.all(
          color: TawsilColors.primary.withOpacity(0.16),
        ),
      ),
      child: Text(
        'REQUIS',
        style: TawsilTextStyles.bodySmall.copyWith(
          color: TawsilColors.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
          letterSpacing: 0.2,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator({
    required bool isSelected,
    required bool isRequired,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isSelected ? TawsilColors.primary : Colors.white,
        shape: isRequired ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isRequired
            ? null
            : BorderRadius.circular(TawsilBorderRadius.sm + 3),
        border: Border.all(
          color: isSelected
              ? TawsilColors.primary
              : TawsilColors.textHint.withOpacity(0.7),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: isSelected
          ? const Icon(
              Icons.check_rounded,
              size: 12,
              color: Colors.white,
            )
          : null,
    );
  }

  Widget _buildQuantitySection({required bool compact}) {
    final buttonSize = compact ? 40.0 : 50.0;
    final numberStyle = compact
        ? TawsilTextStyles.displayMedium.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          )
        : TawsilTextStyles.displayLarge.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'QUANTITE',
          style: TawsilTextStyles.bodySmall.copyWith(
            color: TawsilColors.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _QuantityButton(
              icon: Icons.remove_rounded,
              onPressed:
                  _itemQty > 1 ? () => setState(() => _itemQty -= 1) : null,
              buttonSize: buttonSize,
              iconSize: compact ? 16 : 20,
              borderRadius: compact ? 14 : 18,
              backgroundColor: Colors.white,
              borderColor: TawsilColors.primary,
              iconColor: TawsilColors.primary,
            ),
            SizedBox(width: compact ? 10 : 16),
            Text('$_itemQty', style: numberStyle),
            SizedBox(width: compact ? 10 : 16),
            _QuantityButton(
              icon: Icons.add_rounded,
              onPressed: () => setState(() => _itemQty += 1),
              buttonSize: buttonSize,
              iconSize: compact ? 16 : 20,
              borderRadius: compact ? 14 : 18,
              backgroundColor: Colors.white,
              borderColor: TawsilColors.primary,
              iconColor: TawsilColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    OptionGroup group,
    dynamic add, {
    required bool dense,
  }) {
    final qty = _selected[add.id] ?? 0;
    final isSelected = qty > 0;
    final hasDescription =
        add.description != null && add.description!.trim().isNotEmpty;
    final tilePadding = dense ? 10.0 : 14.0;
    final tileRadius = dense ? 16.0 : 20.0;
    final gap = dense ? 8.0 : 12.0;

    return Padding(
      padding: EdgeInsets.only(top: dense ? 8 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleAddition(group, add),
          borderRadius: BorderRadius.circular(tileRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 14 : 16,
              vertical: tilePadding,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? TawsilColors.primaryLight.withOpacity(0.4)
                  : Colors.white,
              borderRadius: BorderRadius.circular(tileRadius),
              border: Border.all(
                color: isSelected ? TawsilColors.primary : TawsilColors.border,
                width: isSelected ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: dense ? 8 : 10,
                  offset: Offset(0, dense ? 3 : 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSelectionIndicator(
                  isSelected: isSelected,
                  isRequired: group.isRequired,
                ),
                SizedBox(width: gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        add.nom,
                        maxLines: dense ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TawsilTextStyles.headingSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: dense ? 12.5 : 14,
                          height: 1.1,
                        ),
                      ),
                      if (!dense && hasDescription)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            add.description!,
                            style: TawsilTextStyles.bodyMedium.copyWith(
                              color: TawsilColors.textSecondary,
                              fontSize: 10.5,
                              height: 1.18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: gap),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      add.prix > 0 ? '+${_formatMoney(add.prix)} DA' : 'Inclus',
                      style: TawsilTextStyles.bodySmall.copyWith(
                        color: add.prix > 0
                            ? TawsilColors.primary
                            : TawsilColors.primaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: dense ? 11.5 : 12.5,
                      ),
                    ),
                    if (!group.isRequired && isSelected) ...[
                      SizedBox(height: dense ? 4 : 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: dense ? 3 : 4,
                          vertical: dense ? 2 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(TawsilBorderRadius.full),
                          border: Border.all(
                            color: TawsilColors.primary.withOpacity(0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _QuantityButton(
                              icon: Icons.remove_rounded,
                              onPressed: qty > 1
                                  ? () => _updateAdditionQuantity(add, qty - 1)
                                  : () => _updateAdditionQuantity(add, 0),
                              buttonSize: dense ? 20 : 24,
                              iconSize: dense ? 12 : 14,
                              borderRadius: 8,
                              backgroundColor: Colors.white,
                              borderColor: TawsilColors.primary,
                              iconColor: TawsilColors.primary,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: dense ? 5 : 7,
                              ),
                              child: Text(
                                '$qty',
                                style: TawsilTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: dense ? 10 : 11,
                                ),
                              ),
                            ),
                            _QuantityButton(
                              icon: Icons.add_rounded,
                              onPressed: () =>
                                  _updateAdditionQuantity(add, qty + 1),
                              buttonSize: dense ? 20 : 24,
                              iconSize: dense ? 12 : 14,
                              borderRadius: 8,
                              backgroundColor: Colors.white,
                              borderColor: TawsilColors.primary,
                              iconColor: TawsilColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSection(
    OptionGroup group, {
    required bool dense,
    double? width,
  }) {
    final isMissing = group.isRequired &&
        !group.additions.any((add) => (_selected[add.id] ?? 0) > 0);

    final section = Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        dense ? 14 : 16,
        dense ? 14 : 16,
        dense ? 14 : 16,
        dense ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(dense ? 22 : 24),
        border: Border.all(
          color: isMissing
              ? TawsilColors.error.withOpacity(0.22)
              : TawsilColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dense ? 0.035 : 0.045),
            blurRadius: dense ? 12 : 16,
            offset: Offset(0, dense ? 4 : 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  group.nom.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TawsilTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: dense ? 14 : 16,
                    letterSpacing: 0.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildGroupBadge(group),
            ],
          ),
          if (!dense &&
              group.description != null &&
              group.description!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                group.description!,
                style: TawsilTextStyles.bodySmall.copyWith(
                  color: TawsilColors.textSecondary,
                  fontSize: 10.5,
                  height: 1.15,
                ),
              ),
            ),
          if (isMissing)
            Padding(
              padding: EdgeInsets.only(top: dense ? 4 : 8),
              child: Text(
                'Selection requise',
                style: TawsilTextStyles.bodySmall.copyWith(
                  color: TawsilColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: dense ? 10 : 11,
                ),
              ),
            ),
          if (group.additions.isEmpty)
            Container(
              margin: EdgeInsets.only(top: dense ? 10 : 12),
              width: double.infinity,
              padding: EdgeInsets.all(dense ? 12 : 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(dense ? 18 : 20),
                border: Border.all(color: TawsilColors.border),
              ),
              child: Text(
                'Aucune option disponible dans ce groupe.',
                style: TawsilTextStyles.bodySmall.copyWith(
                  color: TawsilColors.textSecondary,
                  fontSize: dense ? 10.5 : 11,
                ),
              ),
            )
          else
            ...group.additions.map(
              (add) => _buildOptionTile(
                group,
                add,
                dense: dense,
              ),
            ),
        ],
      ),
    );

    if (width == null) {
      return section;
    }

    return SizedBox(width: width, child: section);
  }

  Widget _buildDesktopHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: _hasImage
                    ? Image.network(
                        widget.menuItem.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _additionPlaceholder(),
                      )
                    : _additionPlaceholder(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.menuItem.nom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TawsilTextStyles.headingMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        height: 1.1,
                      ),
                    ),
                    if (widget.menuItem.description != null &&
                        widget.menuItem.description!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.menuItem.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TawsilTextStyles.bodySmall.copyWith(
                            color: TawsilColors.textSecondary,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${_formatMoney(_promoUnitPrice)} DA',
                          style: TawsilTextStyles.priceMedium.copyWith(
                            color: TawsilColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        if (_hasPromotion)
                          Text(
                            '${_formatMoney(widget.menuItem.prix)} DA',
                            style: TawsilTextStyles.bodySmall.copyWith(
                              color: TawsilColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        if (widget.menuItem.tempsPreparation > 0)
                          _buildHeaderChip(
                            '${widget.menuItem.tempsPreparation} min',
                            icon: Icons.timer_outlined,
                          ),
                        ..._promoLabels.map(
                          (label) => _buildHeaderChip(
                            label,
                            icon: Icons.local_offer_rounded,
                            backgroundColor: TawsilColors.primaryLight,
                            textColor: TawsilColors.primaryDark,
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
        const SizedBox(width: 16),
        Container(
          width: 1,
          height: 78,
          color: TawsilColors.divider,
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 186,
          child: _buildQuantitySection(compact: true),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F7),
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: _hasImage
                  ? Image.network(
                      widget.menuItem.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _additionPlaceholder(),
                    )
                  : _additionPlaceholder(),
            ),
            const SizedBox(width: TawsilSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.menuItem.nom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TawsilTextStyles.headingMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  if (widget.menuItem.description != null &&
                      widget.menuItem.description!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.menuItem.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TawsilTextStyles.bodyMedium.copyWith(
                          color: TawsilColors.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Text(
                        '${_formatMoney(_promoUnitPrice)} DA',
                        style: TawsilTextStyles.priceMedium.copyWith(
                          color: TawsilColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (_hasPromotion)
                        Text(
                          '${_formatMoney(widget.menuItem.prix)} DA',
                          style: TawsilTextStyles.bodySmall.copyWith(
                            color: TawsilColors.textSecondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      if (widget.menuItem.tempsPreparation > 0)
                        _buildHeaderChip(
                          '${widget.menuItem.tempsPreparation} min',
                          icon: Icons.timer_outlined,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: TawsilColors.border),
          ),
          child: _buildQuantitySection(compact: true),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDesktop, double sidePadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(sidePadding, 10, sidePadding, 10),
      child: isDesktop
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL',
                        style: TawsilTextStyles.bodySmall.copyWith(
                          color: TawsilColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatMoney(_total)} DA',
                        style: TawsilTextStyles.displayMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: TawsilColors.primaryDark,
                          fontSize: 22,
                        ),
                      ),
                      if (_hasPromotion)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Avant promo: ${_formatMoney(_baseTotal)} DA',
                            style: TawsilTextStyles.bodySmall.copyWith(
                              color: TawsilColors.textSecondary,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 11,
                              height: 1.05,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 340,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TawsilColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: TawsilTextStyles.buttonLarge.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 20,
                    ),
                    label: const Text('Ajouter au panier'),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'TOTAL',
                  style: TawsilTextStyles.bodySmall.copyWith(
                    color: TawsilColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatMoney(_total)} DA',
                  style: TawsilTextStyles.displayMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: TawsilColors.primaryDark,
                    fontSize: 19,
                  ),
                ),
                if (_hasPromotion)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Avant promo: ${_formatMoney(_baseTotal)} DA',
                      style: TawsilTextStyles.bodySmall.copyWith(
                        color: TawsilColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                        fontSize: 11,
                        height: 1.05,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TawsilColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: TawsilTextStyles.buttonLarge.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 20,
                    ),
                    label: const Text('Ajouter au panier'),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isDesktop = screenWidth >= 980;
    final denseDesktopLayout = isDesktop;
    final desktopOuterMargin = 0.0;
    final sheetWidth =
        isDesktop ? screenWidth - (desktopOuterMargin * 2) : screenWidth;
    final sheetHeight = screenHeight * (isDesktop ? 0.95 : 0.92);
    final sidePadding = isDesktop ? 22.0 : 20.0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: desktopOuterMargin,
          right: desktopOuterMargin,
          top: isDesktop ? 12 : 0,
          bottom: mediaQuery.viewInsets.bottom,
        ),
        child: Align(
          alignment: isDesktop ? Alignment.center : Alignment.bottomCenter,
          child: SizedBox(
            width: sheetWidth,
            height: sheetHeight,
            child: ClipRRect(
              borderRadius: isDesktop
                  ? BorderRadius.circular(30)
                  : const BorderRadius.vertical(top: Radius.circular(30)),
              child: Material(
                color: Colors.white,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            sidePadding,
                            isDesktop ? 20 : 18,
                            sidePadding,
                            isDesktop ? 16 : 14,
                          ),
                          child: isDesktop
                              ? _buildDesktopHeader()
                              : _buildMobileHeader(),
                        ),
                        Container(height: 1, color: TawsilColors.divider),
                        Expanded(
                          child: Container(
                            color: const Color(0xFFF5F7F5),
                            child: isDesktop
                                ? Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      sidePadding,
                                      18,
                                      sidePadding,
                                      16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'OPTIONS',
                                          style: TawsilTextStyles.headingMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        if (widget.groups.isEmpty)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(
                                              TawsilSpacing.lg,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAF8),
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                            ),
                                            child: Text(
                                              'Aucune option disponible pour cet article.',
                                              style: TawsilTextStyles.bodySmall
                                                  .copyWith(
                                                color:
                                                    TawsilColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          )
                                        else
                                          Expanded(
                                            child: _buildDesktopGroups(
                                              dense: denseDesktopLayout,
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                : SingleChildScrollView(
                                    padding: EdgeInsets.fromLTRB(
                                      sidePadding,
                                      28,
                                      sidePadding,
                                      28,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'OPTIONS',
                                          style: TawsilTextStyles.headingLarge
                                              .copyWith(
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        if (widget.groups.isEmpty)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(
                                              TawsilSpacing.lg,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAF8),
                                              borderRadius:
                                                  BorderRadius.circular(26),
                                            ),
                                            child: Text(
                                              'Aucune option disponible pour cet article.',
                                              style: TawsilTextStyles.bodyMedium
                                                  .copyWith(
                                                color:
                                                    TawsilColors.textSecondary,
                                              ),
                                            ),
                                          )
                                        else
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              const spacing = 18.0;
                                              final columns = constraints
                                                          .maxWidth >=
                                                      1220
                                                  ? 4
                                                  : (constraints.maxWidth >= 860
                                                      ? 3
                                                      : (constraints.maxWidth >=
                                                              560
                                                          ? 2
                                                          : 1));
                                              final groupWidth = columns == 1
                                                  ? constraints.maxWidth
                                                  : (constraints.maxWidth -
                                                          (spacing *
                                                              (columns - 1))) /
                                                      columns;

                                              return Wrap(
                                                spacing: spacing,
                                                runSpacing: spacing,
                                                children: widget.groups
                                                    .map(
                                                      (group) =>
                                                          _buildGroupSection(
                                                        group,
                                                        dense: false,
                                                        width: groupWidth,
                                                      ),
                                                    )
                                                    .toList(),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        Container(height: 1, color: TawsilColors.divider),
                        _buildFooter(isDesktop, sidePadding),
                      ],
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius:
                              BorderRadius.circular(TawsilBorderRadius.full),
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle,
                              border: Border.all(color: TawsilColors.border),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: TawsilColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
            ? (status.isSyncing ? 'Sync...' : (isWarning ? 'Hors ligne' : 'OK'))
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
