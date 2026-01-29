import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/order/widgets/history/order_history_card.dart';
import 'package:client_app/src/features/order/widgets/history/order_history_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../cubit/order_history_cubit.dart';
import '../cubit/order_history_state.dart';
import '../pages/order_tracking_page.dart';
import '../models/order_model.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderHistoryCubit()..fetchOrderHistory(),
      child: const OrderHistoryView(),
    );
  }
}

class OrderHistoryView extends StatefulWidget {
  const OrderHistoryView({super.key});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  OrderHistoryFilter _activeFilter = OrderHistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: ColorApp.white,
          appBar: AppBar(
            backgroundColor: ColorApp.white,
            title: Text(l10n.orderHistory),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
          body: Column(
            children: [
              OrderHistoryFilterBar(
                activeFilter: _activeFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    _activeFilter = filter;
                  });
                  context.read<OrderHistoryCubit>().filterBy(filter);
                },
              ),
              Expanded(
                child: _buildBody(context, state, l10n),
              ),
            ],
          ),
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
          await context.read<OrderHistoryCubit>().filterBy(_activeFilter);
        },
        child: _buildGroupedOrderList(state.orders, l10n),
      );
    } else if (state is OrderHistoryError) {
      return _buildErrorState(context, l10n, state.message);
    }
    return const SizedBox();
  }

  Widget _buildGroupedOrderList(
      List<OrderModel> orders, AppLocalizations l10n) {
    // Group orders by date
    final Map<String, List<OrderModel>> groupedOrders = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var order in orders) {
      if (order.createdAt == null) continue;
      final orderDate = DateTime(
          order.createdAt!.year, order.createdAt!.month, order.createdAt!.day);
      String dateLabel;

      if (orderDate == today) {
        dateLabel =
            "Aujourd'hui - ${DateFormat('dd MMMM yyyy').format(order.createdAt!)}";
      } else if (orderDate == yesterday) {
        dateLabel =
            "Hier - ${DateFormat('dd MMMM yyyy').format(order.createdAt!)}";
      } else {
        dateLabel = DateFormat('dd MMMM yyyy').format(order.createdAt!);
      }

      if (!groupedOrders.containsKey(dateLabel)) {
        groupedOrders[dateLabel] = [];
      }
      groupedOrders[dateLabel]!.add(order);
    }

    final sortedKeys =
        groupedOrders.keys.toList(); // Assuming they come sorted from API

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateLabel = sortedKeys[index];
        final dayOrders = groupedOrders[dateLabel]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                dateLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...dayOrders.map((order) => OrderHistoryCard(
                  order: order,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderTrackingPage(orderId: order.id),
                      ),
                    );
                  },
                )),
          ],
        );
      },
    );
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
              context.read<OrderHistoryCubit>().filterBy(_activeFilter);
            },
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
