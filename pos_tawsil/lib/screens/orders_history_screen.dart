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
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // all, today, week, month

  @override
  void initState() {
    super.initState();
    _loadOrders();
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

      // Trier par date (plus r?cent en premier)
      filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _orders = filteredOrders;
        _isLoading = false;
      });
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
    _loadOrders();
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

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: TawsilColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: TawsilSpacing.md),
            Text(
              'Aucune commande',
              style: TawsilTextStyles.headingMedium.copyWith(
                color: TawsilColors.textSecondary,
              ),
            ),
            const SizedBox(height: TawsilSpacing.xs),
            Text(
              'Les commandes apparaîtront ici',
              style: TawsilTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(TawsilSpacing.md),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: TawsilSpacing.md),
      itemBuilder: (context, index) {
        final order = _orders[index];
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
                    child: Text(
                      order.orderNumber,
                      style: TawsilTextStyles.headingSmall.copyWith(
                        color: TawsilColors.primary,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(order.createdAt),
                    style: TawsilTextStyles.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: TawsilSpacing.sm),
              
              // Heure
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: TawsilColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(order.createdAt),
                    style: TawsilTextStyles.bodySmall,
                  ),
                ],
              ),
              
              const Divider(height: TawsilSpacing.lg),
              
              // Nombre d'articles
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 18,
                    color: TawsilColors.textSecondary,
                  ),
                  const SizedBox(width: TawsilSpacing.sm),
                  Text(
                    '${order.items.length} article(s)',
                    style: TawsilTextStyles.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: TawsilSpacing.sm),
              
              // Montant total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TawsilTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${order.totalAmount.toStringAsFixed(2)} DA',
                    style: TawsilTextStyles.priceMedium,
                  ),
                ],
              ),
              const SizedBox(height: TawsilSpacing.md),
              
              // Bouton voir reçu
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.receipt_outlined, size: 18),
                    label: const Text('Voir le reçu'),
                    style: TextButton.styleFrom(
                      foregroundColor: TawsilColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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