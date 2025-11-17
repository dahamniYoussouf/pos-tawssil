import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/orders/cubit/orders_cubit.dart';
import 'package:restaurant_app/src/features/orders/cubit/orders_state.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';
import 'package:restaurant_app/src/features/orders/widgets/order_card.dart';
import 'package:restaurant_app/src/features/orders/widgets/order_card_shimmer.dart';
import 'package:restaurant_app/src/features/orders/widgets/status_selector.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({
    super.key,
  });

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final initialStatus = OrderStatus.pending;
    context.read<OrdersCubit>().fetchOrders(status: initialStatus);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onStatusChanged(String status) {
    context.read<OrdersCubit>().changeStatus(status);
  }

  void _onScroll() {
    final currentState = context.read<OrdersCubit>().state;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      context.read<OrdersCubit>().loadMoreOrders(status: currentState.selectedStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        return Column(
          children: [
            StatusSelector(
              selectedStatus: state.selectedStatus,
              onStatusChanged: _onStatusChanged,
            ),
            Expanded(
              child: BlocConsumer<OrdersCubit, OrdersState>(
                listener: _handleStateChanges,
                builder: _buildContent,
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleStateChanges(BuildContext context, OrdersState state) {
    final localizations = AppLocalizations.of(context)!;
    if (state is OrderActionError) {
      _showErrorSnackBar(context, _translateErrorMessage(state.message, localizations));
    } else if (state is OrderActionSuccess) {
      _showSuccessSnackBar(context, _translateSuccessMessage(state.message, localizations));
    }
  }

  Widget _buildContent(BuildContext context, OrdersState state) {
    if (state is OrdersLoading) {
      return _buildShimmerList();
    } else if (state is OrdersLoaded) {
      if (state.orders.isEmpty) {
        return _buildEmptyState();
      }
      return _buildOrdersList(state);
    } else if (state is OrdersError) {
      return _buildErrorState(state.message);
    }
    return const SizedBox.shrink();
  }

  Widget _buildOrdersList(OrdersLoaded state) {
    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.orders.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.orders.length) {
            return _buildLoadingIndicator();
          }
          return _buildOrderCard(state.orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final currentState = context.read<OrdersCubit>().state;
    final isLoading = currentState is OrderActionLoading && currentState.orderId == order.id;
    return OrderCard(
      order: order,
      isLoading: isLoading,
      onAccept: () => context.read<OrdersCubit>().acceptOrder(order.id),
      onRefuse: () => context.read<OrdersCubit>().declineOrder(order.id),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Future<void> _refreshOrders() async {
    final currentState = context.read<OrdersCubit>().state;
    context.read<OrdersCubit>().refreshOrders(status: currentState.selectedStatus);
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 3,
      itemBuilder: (context, index) {
        return const OrderCardShimmer();
      },
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: AppColors.greyLight,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.noOrders,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.noPendingOrders,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.greyDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
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
            _translateErrorMessage(message, localizations),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final currentState = context.read<OrdersCubit>().state;
              context.read<OrdersCubit>().refreshOrders(status: currentState.selectedStatus);
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

  String _translateSuccessMessage(String message, AppLocalizations localizations) {
    if (message.contains('accepted successfully')) {
      return localizations.orderAcceptedSuccess;
    } else if (message.contains('declined successfully')) {
      return localizations.orderRefusedSuccess;
    } else if (message.contains('refused successfully')) {
      return localizations.orderRefusedSuccess;
    }
    return message;
  }

  String _translateErrorMessage(String message, AppLocalizations localizations) {
    if (message.contains('Invalid response format')) {
      return localizations.errorInvalidResponseFormat;
    } else if (message.contains('Failed to fetch orders')) {
      return localizations.errorFailedToFetchOrders;
    } else if (message.contains('Failed to accept order')) {
      return localizations.errorFailedToAcceptOrder;
    } else if (message.contains('Error accepting order:')) {
      final errorMatch = RegExp(r'Error accepting order: (.+)').firstMatch(message);
      if (errorMatch != null) {
        return localizations.errorAcceptingOrder(errorMatch.group(1) ?? '');
      }
      return localizations.errorAcceptingOrder(message);
    } else if (message.contains('Failed to decline order')) {
      return localizations.errorFailedToRefuseOrder;
    } else if (message.contains('Error declining order:')) {
      final errorMatch = RegExp(r'Error declining order: (.+)').firstMatch(message);
      if (errorMatch != null) {
        return localizations.errorRefusingOrder(errorMatch.group(1) ?? '');
      }
      return localizations.errorRefusingOrder(message);
    } else if (message.contains('Failed to refuse order')) {
      return localizations.errorFailedToRefuseOrder;
    } else if (message.contains('Error refusing order:')) {
      final errorMatch = RegExp(r'Error refusing order: (.+)').firstMatch(message);
      if (errorMatch != null) {
        return localizations.errorRefusingOrder(errorMatch.group(1) ?? '');
      }
      return localizations.errorRefusingOrder(message);
    }
    return message;
  }
}
