import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/features/orders/widgets/history/order_history_card.dart';
import 'package:delivery_app/src/features/orders/widgets/history/order_history_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/order_history_cubit.dart';
import '../cubit/order_history_state.dart';
import '../pages/order_details_page.dart';
import '../models/order_model.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderHistoryCubit()
        ..fetchOrderHistory(filter: OrderHistoryFilter.ongoing),
      child: const OrderView(),
    );
  }
}

class OrderView extends StatelessWidget {
  const OrderView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            title: Text(
              l10n.homeTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                    fontSize: 22,
                  ),
            ),
            centerTitle: true,
          ),
          body: _buildBody(context, state, l10n),
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context, OrderHistoryState state, AppLocalizations l10n) {
    if (state is OrderHistoryInitial || state is OrderHistoryLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is OrderHistoryLoaded) {
      if (state.orders.isEmpty) {
        return _buildEmptyState(context, l10n);
      }
      return RefreshIndicator(
        onRefresh: () async {
          await context.read<OrderHistoryCubit>().refreshOrderHistory();
        },
        child: _buildGroupedOrderList(context, state.groupedOrders, l10n),
      );
    } else if (state is OrderHistoryError) {
      return _buildErrorState(context, l10n, state.message);
    }
    return const SizedBox();
  }

  Widget _buildGroupedOrderList(BuildContext context,
      Map<String, List<OrderModel>> groupedOrders, AppLocalizations l10n) {
    final flattenedList = _flattenGroupedOrders(groupedOrders, l10n);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: flattenedList.length,
      itemBuilder: (context, index) {
        final item = flattenedList[index];
        if (item.isHeader) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              item.displayDate!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          );
        } else {
          return OrderHistoryCard(
            order: item.order!,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      OrderDetailsPage(orderId: item.order!.id),
                ),
              );
            },
            orderPage: true,
          );
        }
      },
    );
  }

  List<_OrderListItem> _flattenGroupedOrders(
      Map<String, List<OrderModel>> groupedOrders, AppLocalizations l10n) {
    final List<_OrderListItem> flattenedList = [];
    final sortedKeys = groupedOrders.keys.toList();
    for (final dateLabel in sortedKeys) {
      String displayDate = dateLabel;
      if (dateLabel.startsWith('TODAY|')) {
        displayDate = '${l10n.todayLabel} - ${dateLabel.substring(6)}';
      } else if (dateLabel.startsWith('YESTERDAY|')) {
        displayDate = '${l10n.yesterdayLabel} - ${dateLabel.substring(10)}';
      }
      flattenedList.add(_OrderListItem.header(displayDate));
      final dayOrders = groupedOrders[dateLabel]!;
      for (final order in dayOrders) {
        flattenedList.add(_OrderListItem.order(order));
      }
    }
    return flattenedList;
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(l10n.noOrdersYet, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            l10n.startOrderingNow,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, AppLocalizations l10n, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(l10n.error, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context
                  .read<OrderHistoryCubit>()
                  .filterBy(OrderHistoryFilter.ongoing);
            },
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

class _OrderListItem {
  final bool isHeader;
  final String? displayDate;
  final OrderModel? order;

  const _OrderListItem._({
    required this.isHeader,
    this.displayDate,
    this.order,
  });

  factory _OrderListItem.header(String displayDate) {
    return _OrderListItem._(
      isHeader: true,
      displayDate: displayDate,
    );
  }

  factory _OrderListItem.order(OrderModel order) {
    return _OrderListItem._(
      isHeader: false,
      order: order,
    );
  }
}
