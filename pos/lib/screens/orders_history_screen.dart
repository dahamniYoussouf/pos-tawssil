// lib/screens/orders_history_screen.dart
import 'package:flutter/material.dart';
import 'package:pos_tawsil/config/app_theme.dart';
import 'package:pos_tawsil/models/order.dart';
import 'package:pos_tawsil/screens/receipt_screen.dart';
import 'package:pos_tawsil/services/api_service.dart';
import 'package:pos_tawsil/services/database_service.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  final DatabaseService _db = DatabaseService();
  final ApiService _api = ApiService();
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // all, today, week, month
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders = _orders.where((order) {
        final matchesSearch = _searchQuery.isEmpty ||
            order.orderNumber
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            order.items.any(
              (item) => item.menuItemName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()),
            );

        final now = DateTime.now();
        if (_selectedFilter == 'today') {
          final orderDate = order.createdAt;
          if (orderDate.year != now.year ||
              orderDate.month != now.month ||
              orderDate.day != now.day) {
            return false;
          }
        } else if (_selectedFilter == 'week') {
          final weekAgo = now.subtract(const Duration(days: 7));
          if (!order.createdAt.isAfter(weekAgo)) {
            return false;
          }
        } else if (_selectedFilter == 'month') {
          if (order.createdAt.year != now.year ||
              order.createdAt.month != now.month) {
            return false;
          }
        }

        return matchesSearch;
      }).toList();

      _filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<Order> remoteOrders = [];
      try {
        remoteOrders = await _api.fetchOrdersHistory();
      } catch (e) {
        // Fallback to local orders if API fails
        print('⚠️ Orders history API failed, using local DB: $e');
      }

      final localOrders = await _db.getAllOrders();
      final orders = _mergeOrders(remoteOrders, localOrders);

      List<Order> filteredOrders = orders;
      final now = DateTime.now();

      if (_selectedFilter == 'today') {
        filteredOrders = orders.where((order) {
          final orderDate = order.createdAt;
          return orderDate.year == now.year &&
              orderDate.month == now.month &&
              orderDate.day == now.day;
        }).toList();
      } else if (_selectedFilter == 'week') {
        final weekAgo = now.subtract(const Duration(days: 7));
        filteredOrders =
            orders.where((order) => order.createdAt.isAfter(weekAgo)).toList();
      } else if (_selectedFilter == 'month') {
        filteredOrders = orders.where((order) {
          return order.createdAt.year == now.year &&
              order.createdAt.month == now.month;
        }).toList();
      }

      filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _orders = filteredOrders;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Order> _mergeOrders(List<Order> remote, List<Order> local) {
    final hasRemote = remote.isNotEmpty;
    final filteredLocal = hasRemote
        ? local.where((o) {
            final isPosNumber = o.orderNumber.toUpperCase().startsWith('POS-');
            if (!isPosNumber) return true;
            if (!o.synced) return true;
            // If a remote match exists, hide the local POS order to avoid duplicate.
            return !_isLikelyDuplicateOfRemote(o, remote);
          }).toList()
        : local;
    final byId = <String, Order>{};

    for (final order in remote) {
      byId[order.id] = order;
    }

    for (final order in filteredLocal) {
      final existing = byId[order.id];
      if (existing == null || !order.synced) {
        byId[order.id] = order;
      }
    }

    final merged = byId.values.toList();
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  bool _isLikelyDuplicateOfRemote(Order localOrder, List<Order> remoteOrders) {
    // Heuristic matching to hide POS local duplicates when a PKP server order exists.
    const int maxMinutesDiff = 3;
    const double totalEps = 0.01;

    for (final remote in remoteOrders) {
      if (localOrder.restaurantId.isNotEmpty &&
          remote.restaurantId.isNotEmpty &&
          localOrder.restaurantId != remote.restaurantId) {
        continue;
      }
      if (localOrder.cashierId.isNotEmpty &&
          remote.cashierId.isNotEmpty &&
          localOrder.cashierId != remote.cashierId) {
        continue;
      }
      if (localOrder.paymentMethod.isNotEmpty &&
          remote.paymentMethod.isNotEmpty &&
          localOrder.paymentMethod != remote.paymentMethod) {
        continue;
      }
      if (localOrder.items.length != remote.items.length) continue;
      if ((localOrder.totalAmount - remote.totalAmount).abs() > totalEps) continue;

      final diff = localOrder.createdAt.difference(remote.createdAt).abs();
      if (diff.inMinutes <= maxMinutesDiff) {
        return true;
      }
    }
    return false;
  }

  void _changeFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilters();
  }

  double _calculateTotalRevenue() {
    return _filteredOrders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );
  }

  int _calculateTotalItems() {
    return _filteredOrders.fold<int>(
      0,
      (sum, order) => sum + order.items.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TawsilColors.background,
      appBar: AppBar(
        backgroundColor: TawsilColors.primary,
        toolbarHeight: 54,
        titleTextStyle: TawsilTextStyles.headingMedium
            .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        title: const Text('Historique des Commandes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadOrders,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isLoading) _buildSearchBar(),
            Expanded(child: _buildOrdersList()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsBar() {
    final totalRevenue = _calculateTotalRevenue();
    final totalItems = _calculateTotalItems();
    final avgOrderValue =
        _filteredOrders.isEmpty ? 0.0 : totalRevenue / _filteredOrders.length;
    final w = MediaQuery.of(context).size.width;
    final useGrid = w < 500;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        TawsilSpacing.md,
        TawsilSpacing.sm,
        TawsilSpacing.md,
        TawsilSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TawsilSpacing.md,
          vertical: TawsilSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: TawsilColors.primary.withOpacity(0.95),
          borderRadius: BorderRadius.circular(TawsilBorderRadius.xl),
          boxShadow: [
            BoxShadow(
              color: TawsilColors.shadow.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: useGrid
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBubble(
                          icon: Icons.receipt_long_rounded,
                          label: 'Commandes',
                          value: '${_filteredOrders.length}',
                        ),
                      ),
                      const SizedBox(width: TawsilSpacing.sm),
                      Expanded(
                        child: _buildStatBubble(
                          icon: Icons.attach_money_rounded,
                          label: 'CA',
                          value: '${totalRevenue.toStringAsFixed(0)} DA',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TawsilSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatBubble(
                          icon: Icons.shopping_bag_rounded,
                          label: 'Articles',
                          value: '$totalItems',
                        ),
                      ),
                      const SizedBox(width: TawsilSpacing.sm),
                      Expanded(
                        child: _buildStatBubble(
                          icon: Icons.trending_up_rounded,
                          label: 'Panier',
                          value: '${avgOrderValue.toStringAsFixed(0)} DA',
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildStatBubble(
                      icon: Icons.receipt_long_rounded,
                      label: 'Commandes',
                      value: '${_filteredOrders.length}',
                    ),
                  ),
                  const SizedBox(width: TawsilSpacing.sm),
                  Expanded(
                    child: _buildStatBubble(
                      icon: Icons.attach_money_rounded,
                      label: 'CA',
                      value: '${totalRevenue.toStringAsFixed(0)} DA',
                    ),
                  ),
                  const SizedBox(width: TawsilSpacing.sm),
                  Expanded(
                    child: _buildStatBubble(
                      icon: Icons.shopping_bag_rounded,
                      label: 'Articles',
                      value: '$totalItems',
                    ),
                  ),
                  const SizedBox(width: TawsilSpacing.sm),
                  Expanded(
                    child: _buildStatBubble(
                      icon: Icons.trending_up_rounded,
                      label: 'Panier',
                      value: '${avgOrderValue.toStringAsFixed(0)} DA',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(
        horizontal: TawsilSpacing.md,
        vertical: TawsilSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: TawsilSpacing.sm),
          Text(
            value,
            style: TawsilTextStyles.headingMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TawsilTextStyles.bodySmall.copyWith(
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBubble({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TawsilSpacing.sm,
        vertical: TawsilSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TawsilTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TawsilTextStyles.bodySmall.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        TawsilSpacing.md,
        0,
        TawsilSpacing.md,
        TawsilSpacing.md,
      ),
      padding: const EdgeInsets.all(TawsilSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 420;
              final searchField = Container(
                decoration: BoxDecoration(
                  color: TawsilColors.background,
                  borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
                  border: Border.all(color: TawsilColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un numero de commande ou un article',
                    prefixIcon:
                        Icon(Icons.search, color: TawsilColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: TawsilColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
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
              );
              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                ],
              );
            },
          ),
          const SizedBox(height: TawsilSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tout', 'all'),
                const SizedBox(width: TawsilSpacing.sm),
                _buildFilterChip('Aujourd\'hui', 'today'),
                const SizedBox(width: TawsilSpacing.sm),
                _buildFilterChip('7 jours', 'week'),
                const SizedBox(width: TawsilSpacing.sm),
                _buildFilterChip('Ce mois', 'month'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return InkWell(
      onTap: () => _changeFilter(value),
      borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: TawsilSpacing.md + 2,
          vertical: TawsilSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? TawsilColors.primary : TawsilColors.background,
          borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
          border: Border.all(
            color: isSelected
                ? TawsilColors.primary.withOpacity(0.7)
                : TawsilColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: TawsilColors.primary.withOpacity(0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TawsilTextStyles.bodySmall.copyWith(
                color: isSelected
                    ? TawsilColors.textOnPrimary
                    : TawsilColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(TawsilColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: TawsilColors.error,
            ),
            const SizedBox(height: TawsilSpacing.md),
            Text(
              _errorMessage!,
              style: TawsilTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TawsilSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }

    if (_filteredOrders.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty || _selectedFilter != 'all'
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_outlined,
              size: 64,
              color: TawsilColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: TawsilSpacing.md),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'all'
                  ? 'Aucune commande trouvee'
                  : 'Aucune commande',
              style: TawsilTextStyles.headingMedium.copyWith(
                color: TawsilColors.textSecondary,
              ),
            ),
            const SizedBox(height: TawsilSpacing.xs),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'all'
                  ? 'Modifiez vos criteres de recherche'
                  : 'Les commandes apparaitront ici',
              style: TawsilTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    final w = MediaQuery.of(context).size.width;
    if (w < 600) {
      return _buildOrdersCardList();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TawsilSpacing.md,
        0,
        TawsilSpacing.md,
        TawsilSpacing.md,
      ),
      child: _buildOrdersTable(),
    );
  }

  Widget _buildOrdersCardList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        TawsilSpacing.md,
        0,
        TawsilSpacing.md,
        TawsilSpacing.lg,
      ),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: TawsilSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
      ),
      child: InkWell(
        onTap: () => _viewReceipt(order),
        borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(TawsilSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: TawsilTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: TawsilColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _sourceBadge(order),
                  _statusBadge(
                    _getStatusColor(order.status),
                    order.status,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.orderType,
                style: TawsilTextStyles.bodySmall.copyWith(
                  color: TawsilColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: TawsilColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatDate(order.createdAt)} • ${_formatTime(order.createdAt)}',
                    style: TawsilTextStyles.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.receipt_long, size: 14, color: TawsilColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${order.items.length} article${order.items.length > 1 ? 's' : ''}',
                    style: TawsilTextStyles.bodySmall.copyWith(
                      color: TawsilColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.payment, size: 14, color: TawsilColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.paymentMethod,
                      style: TawsilTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} DA',
                    style: TawsilTextStyles.priceMedium,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _viewReceipt(order),
                        child: const Text('Reçu'),
                      ),
                      Icon(
                        order.synced ? Icons.cloud_done_rounded : Icons.cloud_off,
                        size: 20,
                        color: order.synced ? TawsilColors.success : TawsilColors.warning,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                headingRowHeight: 54,
                dataRowHeight: 64,
                headingRowColor: MaterialStateProperty.all(
                  TawsilColors.background.withOpacity(0.6),
                ),
                headingTextStyle: TawsilTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: TawsilColors.textPrimary,
                ),
                dataTextStyle: TawsilTextStyles.bodySmall,
                columns: const [
                  DataColumn(label: Text('Commande')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Articles')),
                  DataColumn(label: Text('Paiement')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _filteredOrders
                    .map((order) => _buildOrderRow(order))
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildOrderRow(Order order) {
    return DataRow(cells: [
      DataCell(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            order.orderNumber,
            style: TawsilTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: TawsilColors.textPrimary,
            ),
          ),
          const SizedBox(height: TawsilSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                order.orderType,
                style: TawsilTextStyles.bodySmall.copyWith(
                  color: TawsilColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              _sourceBadge(order, compact: true),
            ],
          ),
        ],
      )),
      DataCell(Text(
        '${_formatDate(order.createdAt)} • ${_formatTime(order.createdAt)}',
        style: TawsilTextStyles.bodySmall,
      )),
      DataCell(Text(
        '${order.items.length} article${order.items.length > 1 ? 's' : ''}',
        style: TawsilTextStyles.bodySmall.copyWith(
          color: TawsilColors.textSecondary,
        ),
      )),
      DataCell(Text(
        order.paymentMethod,
        style: TawsilTextStyles.bodySmall,
      )),
      DataCell(Text(
        '${order.totalAmount.toStringAsFixed(0)} DA',
        style: TawsilTextStyles.bodyMedium.copyWith(
          color: TawsilColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      )),
      DataCell(_statusBadge(_getStatusColor(order.status), order.status)),
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _viewReceipt(order),
            child: const Text('Voir le reçu'),
          ),
          const SizedBox(width: 8),
          Icon(
            order.synced ? Icons.cloud_done_rounded : Icons.cloud_off,
            size: 20,
            color: order.synced ? TawsilColors.success : TawsilColors.warning,
          ),
        ],
      )),
    ]);
  }

  void _viewReceipt(Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(order: order),
      ),
    );
  }

  Widget _sourceBadge(Order order, {bool compact = false}) {
    final color = order.isPosOrder ? TawsilColors.primary : TawsilColors.info;
    final fontSize = compact ? 10.5 : 11.5;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        order.sourceLabel.toUpperCase(),
        style: TawsilTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _statusBadge(Color color, String status, {bool compact = false}) {
    final fontSize = compact ? 10.5 : 11.5;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TawsilTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        return TawsilColors.success;
      case 'pending':
        return TawsilColors.warning;
      case 'cancelled':
        return TawsilColors.error;
      default:
        return TawsilColors.info;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final orderDate = DateTime(date.year, date.month, date.day);

    if (orderDate == today) {
      return "Aujourd'hui";
    } else if (orderDate == yesterday) {
      return 'Hier';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
