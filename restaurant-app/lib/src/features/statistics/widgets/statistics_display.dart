import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/statistics/models/statistics_model.dart';

class StatisticsDisplay extends StatelessWidget {
  final StatisticsModel statistics;

  const StatisticsDisplay({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(localizations, context),
          const SizedBox(height: 24),
          _buildOrdersByStatus(localizations),
          const SizedBox(height: 24),
          _buildRevenueByStatus(localizations, context),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
      AppLocalizations localizations, BuildContext context) {
    final locale = Localizations.localeOf(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                localizations.totalOrders,
                statistics.totalOrders.toString(),
                Icons.shopping_cart,
                AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                localizations.totalRevenue,
                '${NumberFormat('#,##0', locale.toString()).format(statistics.totalRevenue)} DA',
                Icons.attach_money,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                localizations.averageValue,
                '${NumberFormat('#,##0.00', locale.toString()).format(statistics.averageOrderValue)} DA',
                Icons.trending_up,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                localizations.deliveredOrders,
                statistics.deliveredOrders.toString(),
                Icons.check_circle,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersByStatus(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.ordersByStatus,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusRow(localizations.accepted, statistics.acceptedOrders,
              AppColors.primaryColor),
          _buildStatusRow(
              localizations.preparing, statistics.preparingOrders, Colors.blue),
          _buildStatusRow(localizations.delivering, statistics.deliveringOrders,
              Colors.orange),
          _buildStatusRow(localizations.delivered, statistics.deliveredOrders,
              Colors.green),
          _buildStatusRow(
              localizations.pickedUp, statistics.pickedUpOrders, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueByStatus(
      AppLocalizations localizations, BuildContext context) {
    if (statistics.revenueByStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    final locale = Localizations.localeOf(context);
    final statusLabels = {
      'accepted': localizations.accepted,
      'preparing': localizations.preparing,
      'delivering': localizations.delivering,
      'delivered': localizations.delivered,
      'picked-up': localizations.pickedUp,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.revenueByStatus,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...statistics.revenueByStatus.entries.map((entry) {
            final label = statusLabels[entry.key] ?? entry.key;
            final color = _getStatusColor(entry.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  Text(
                    '${NumberFormat('#,##0', locale.toString()).format(entry.value)} DA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.primaryColor;
      case 'preparing':
        return Colors.blue;
      case 'delivering':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'picked-up':
        return Colors.purple;
      default:
        return AppColors.grey;
    }
  }
}
