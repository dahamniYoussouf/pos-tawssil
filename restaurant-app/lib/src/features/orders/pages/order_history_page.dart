import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/orders/cubit/order_history_cubit.dart';
import 'package:restaurant_app/src/features/orders/cubit/order_history_state.dart';
import 'package:restaurant_app/src/features/orders/models/order_history_filters.dart';
import 'package:restaurant_app/src/features/orders/widgets/order_history_card.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrderHistoryCubit>().fetchOrderHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            localizations.orderHistory,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            onTap: (index) {
              final orderType =
                  index == 1 ? 'delivery' : (index == 2 ? 'pos' : null);
              context.read<OrderHistoryCubit>().setOrderType(orderType);
            },
            indicatorColor: AppColors.primaryColor,
            indicatorWeight: 3,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.grey,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
            tabs: [
              Tab(text: localizations.all),
              Tab(text: localizations.deliveryApp),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diamond_outlined,
                        size: 18, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(localizations.pos),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: const OrderHistoryContentWidget(),
      ),
    );
  }
}

class OrderHistoryContentWidget extends StatelessWidget {
  const OrderHistoryContentWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
      builder: (context, state) {
        if (state is OrderHistoryLoading) {
          return const OrderHistoryLoadingIndicatorWidget();
        } else if (state is OrderHistoryLoaded) {
          final loadedState = state;
          if (loadedState.orders.isEmpty) {
            return OrderHistoryEmptyStateWidget(filters: loadedState.filters);
          }
          return OrderHistoryOrdersListWidget();
        } else if (state is OrderHistoryError) {
          final errorState = state;
          return OrderHistoryErrorStateWidget(message: errorState.message);
        } else if (state is OrderHistoryInitial) {
          // Initial state - trigger fetch if not already loading
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.read<OrderHistoryCubit>().fetchOrderHistory();
            }
          });
          return const OrderHistoryLoadingIndicatorWidget();
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class OrderHistoryOrdersListWidget extends StatefulWidget {
  const OrderHistoryOrdersListWidget({
    super.key,
  });

  @override
  State<OrderHistoryOrdersListWidget> createState() =>
      _OrderHistoryOrdersListWidgetState();
}

class _OrderHistoryOrdersListWidgetState
    extends State<OrderHistoryOrdersListWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final state = context.read<OrderHistoryCubit>().state;
    if (state is! OrderHistoryLoaded) return;
    if (!state.hasMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _isLoadingMore = true;
      context.read<OrderHistoryCubit>().loadMoreOrders().then((_) {
        if (mounted) {
          _isLoadingMore = false;
        }
      }).catchError((_) {
        if (mounted) {
          _isLoadingMore = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<OrderHistoryCubit>().refresh();
      },
      child: BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
        builder: (context, state) {
          if (state is OrderHistoryLoaded) {
            return ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.orders.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.orders.length) {
                  return const OrderHistoryLoadingIndicatorWidget();
                }
                return OrderHistoryCard(order: state.orders[index]);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class OrderHistoryLoadingIndicatorWidget extends StatelessWidget {
  const OrderHistoryLoadingIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class OrderHistoryEmptyStateWidget extends StatelessWidget {
  final OrderHistoryFilters filters;

  const OrderHistoryEmptyStateWidget({
    super.key,
    required this.filters,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final hasActiveFilters = filters.hasFilters;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasActiveFilters
                ? Icons.filter_alt_off_outlined
                : Icons.inbox_outlined,
            size: 80,
            color: AppColors.greyLight,
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters
                ? localizations.noOrdersFoundWithFilters
                : localizations.noOrdersFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<OrderHistoryCubit>().clearFilters();
              },
              icon: const Icon(Icons.clear_all, color: AppColors.white),
              label: Text(
                localizations.reset,
                style: const TextStyle(color: AppColors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class OrderHistoryErrorStateWidget extends StatelessWidget {
  final String message;

  const OrderHistoryErrorStateWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.error,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<OrderHistoryCubit>().refresh();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: Text(
              localizations.retry,
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
