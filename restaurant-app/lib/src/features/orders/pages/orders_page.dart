import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/orders/cubit/orders_cubit.dart';
import 'package:restaurant_app/src/features/orders/cubit/orders_state.dart';
import 'package:restaurant_app/src/features/orders/widgets/order_card.dart';
import 'package:restaurant_app/src/features/orders/widgets/order_card_shimmer.dart';

class OrdersPage extends StatefulWidget {
  final String? status;

  const OrdersPage({
    super.key,
    this.status,
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
    context.read<OrdersCubit>().fetchOrders(status: widget.status ?? 'pending');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      context.read<OrdersCubit>().loadMoreOrders(status: widget.status ?? 'pending');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrdersCubit, OrdersState>(
      listener: (context, state) {
        final localizations = AppLocalizations.of(context)!;
        if (state is OrderActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_translateErrorMessage(state.message, localizations)),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is OrderActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_translateSuccessMessage(state.message, localizations)),
              backgroundColor: AppColors.primaryColor,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is OrdersLoading) {
          return _buildShimmerList();
        } else if (state is OrdersLoaded) {
          if (state.orders.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<OrdersCubit>().refreshOrders(status: widget.status ?? 'pending');
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.orders.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.orders.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final order = state.orders[index];
                final currentState = context.read<OrdersCubit>().state;
                final isLoading = currentState is OrderActionLoading && currentState.orderId == order.id;
                return OrderCard(
                  order: order,
                  isLoading: isLoading,
                  onAccept: () {
                    context.read<OrdersCubit>().acceptOrder(order.id);
                  },
                  onRefuse: () {
                    context.read<OrdersCubit>().refuseOrder(order.id);
                  },
                );
              },
            ),
          );
        } else if (state is OrdersError) {
          return _buildErrorState(state.message);
        }
        return const SizedBox.shrink();
      },
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
              context.read<OrdersCubit>().refreshOrders(status: widget.status ?? 'pending');
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
