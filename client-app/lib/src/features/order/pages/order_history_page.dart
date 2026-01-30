import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/order/widgets/history/order_history_card.dart';
import 'package:client_app/src/features/order/widgets/history/order_history_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
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

class OrderHistoryView extends StatelessWidget {
  const OrderHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
      builder: (context, state) {
        final activeFilter = state.activeFilter;
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
              //asks Cubit to load orders based on selected filter
              OrderHistoryFilterBar(
                activeFilter: activeFilter,
                onFilterChanged: (filter) {
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
        //reload order
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
    final sortedKeys = groupedOrders.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateLabel = sortedKeys[index];
        final dayOrders = groupedOrders[dateLabel]!;

        String displayDate = dateLabel;
        if (dateLabel.startsWith('TODAY|')) {
          displayDate = '${l10n.todayLabel} - ${dateLabel.substring(6)}';
        } else if (dateLabel.startsWith('YESTERDAY|')) {
          displayDate = '${l10n.yesterdayLabel} - ${dateLabel.substring(10)}';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                displayDate,
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
              final activeFilter =
                  context.read<OrderHistoryCubit>().state is OrderHistoryLoaded
                      ? (context.read<OrderHistoryCubit>().state
                              as OrderHistoryLoaded)
                          .activeFilter
                      : OrderHistoryFilter.all;
              context.read<OrderHistoryCubit>().filterBy(activeFilter);
            },
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
