// lib/screens/orders_history_screen.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import 'receipt_screen.dart'; // ?. Import du ReceiptScreen

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
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            order.orderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            order.items.any((item) => 
              item.menuItemName.toLowerCase().contains(_searchQuery.toLowerCase())
            );
        
        // Date filter
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
      
      // Sort by date (most recent first)
      _filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Prendre l'historique depuis le backend (restaurant du caissier)
      final remoteOrders = await _api.fetchOrdersHistory();
      final orders = remoteOrders.isNotEmpty
          ? remoteOrders
          : await _db.getAllOrders(); // fallback offline
      
      // Filtrer selon la p?riode s?lectionn?e
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
        filteredOrders = orders.where((order) => 
          order.createdAt.isAfter(weekAgo)
        ).toList();
      } else if (_selectedFilter == 'month') {
        filteredOrders = orders.where((order) {
          return order.createdAt.year == now.year &&
                 order.createdAt.month == now.month;
        }).toList();
      }

      // Trier par date (plus récent en premier)
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
        title: const Text('Historique des Commandes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadOrders,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Bar
          if (!_isLoading && _orders.isNotEmpty) _buildStatisticsBar(),
          
          // Search Bar
          if (!_isLoading && _orders.isNotEmpty) _buildSearchBar(),
          
          // Filtres
          _buildFilterBar(),
          
          // Liste des commandes
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsBar() {
    final totalRevenue = _calculateTotalRevenue();
    final totalItems = _calculateTotalItems();
    final avgOrderValue = _filteredOrders.isEmpty 
        ? 0.0 
        : totalRevenue / _filteredOrders.length;

    return Container(
      padding: const EdgeInsets.all(TawsilSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TawsilColors.primary,
            TawsilColors.primaryDark,
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.receipt_long_rounded,
              label: 'Commandes',
              value: '${_filteredOrders.length}',
              color: Colors.white,
            ),
          ),
          const SizedBox(width: TawsilSpacing.md),
          Expanded(
            child: _buildStatCard(
              icon: Icons.attach_money_rounded,
              label: 'Chiffre d\'affaires',
              value: '${totalRevenue.toStringAsFixed(0)} DA',
              color: Colors.white,
            ),
          ),
          const SizedBox(width: TawsilSpacing.md),
          Expanded(
            child: _buildStatCard(
              icon: Icons.shopping_bag_rounded,
              label: 'Articles vendus',
              value: '$totalItems',
              color: Colors.white,
            ),
          ),
          const SizedBox(width: TawsilSpacing.md),
          Expanded(
            child: _buildStatCard(
              icon: Icons.trending_up_rounded,
              label: 'Panier moyen',
              value: '${avgOrderValue.toStringAsFixed(0)} DA',
              color: Colors.white,
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(TawsilSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TawsilSpacing.md,
        vertical: TawsilSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                decoration: InputDecoration(
                  hintText: 'Rechercher par numéro de commande ou article...',
                  prefixIcon: Icon(Icons.search, color: TawsilColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: TawsilColors.textSecondary),
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
            ),
          ),
          const SizedBox(width: TawsilSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TawsilSpacing.md,
              vertical: TawsilSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: TawsilColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
            ),
            child: Text(
              '${_filteredOrders.length} résultat${_filteredOrders.length > 1 ? 's' : ''}',
              style: TawsilTextStyles.bodySmall.copyWith(
                color: TawsilColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(TawsilSpacing.md),
      decoration: BoxDecoration(
        color: TawsilColors.surface,
        boxShadow: [
          BoxShadow(
            color: TawsilColors.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    
    return InkWell(
      onTap: () => _changeFilter(value),
      borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TawsilSpacing.md,
          vertical: TawsilSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? TawsilColors.primary : TawsilColors.background,
          borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
          border: Border.all(
            color: isSelected ? TawsilColors.primary : TawsilColors.border,
          ),
        ),
        child: Text(
          label,
          style: TawsilTextStyles.bodySmall.copyWith(
            color: isSelected ? TawsilColors.textOnPrimary : TawsilColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
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
              label: const Text('Réessayer'),
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
                  ? 'Aucune commande trouvée'
                  : 'Aucune commande',
              style: TawsilTextStyles.headingMedium.copyWith(
                color: TawsilColors.textSecondary,
              ),
            ),
            const SizedBox(height: TawsilSpacing.xs),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'all'
                  ? 'Essayez de modifier vos critères de recherche'
                  : 'Les commandes apparaîtront ici',
              style: TawsilTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(TawsilSpacing.md),
      itemCount: _filteredOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: TawsilSpacing.md),
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return _OrderCard(
          order: order,
          onTap: () => _viewReceipt(order),
        );
      },
    );
  }

  void _viewReceipt(Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(order: order),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: TawsilElevation.sm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
            border: Border.all(
              color: TawsilColors.border.withOpacity(0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TawsilSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Numéro de commande et date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: TawsilColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(TawsilBorderRadius.sm),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              size: 20,
                              color: TawsilColors.primary,
                            ),
                          ),
                          const SizedBox(width: TawsilSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.orderNumber,
                                  style: TawsilTextStyles.headingSmall.copyWith(
                                    color: TawsilColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: TawsilColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_formatDate(order.createdAt)} à ${_formatTime(order.createdAt)}',
                                      style: TawsilTextStyles.bodySmall.copyWith(
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
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TawsilSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: TawsilTextStyles.bodySmall.copyWith(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TawsilSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: TawsilSpacing.md),
                
                // Items preview
                if (order.items.isNotEmpty) ...[
                  ...order.items.take(2).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: TawsilSpacing.xs),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: TawsilColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: TawsilSpacing.sm),
                          Expanded(
                            child: Text(
                              '${item.quantite}x ${item.menuItemName}',
                              style: TawsilTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (order.items.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(top: TawsilSpacing.xs),
                      child: Text(
                        '+ ${order.items.length - 2} autre(s) article(s)',
                        style: TawsilTextStyles.bodySmall.copyWith(
                          color: TawsilColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: TawsilSpacing.md),
                ],
                
                // Footer: Total and action
                Container(
                  padding: const EdgeInsets.all(TawsilSpacing.sm),
                  decoration: BoxDecoration(
                    color: TawsilColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: TawsilTextStyles.bodySmall.copyWith(
                              color: TawsilColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${order.totalAmount.toStringAsFixed(2)} DA',
                            style: TawsilTextStyles.priceMedium.copyWith(
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.receipt_outlined, size: 18),
                        label: const Text('Voir le reçu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TawsilColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: TawsilSpacing.md,
                            vertical: TawsilSpacing.sm,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      return 'Aujourd\'hui';
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