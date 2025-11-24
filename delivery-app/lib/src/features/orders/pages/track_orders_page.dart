import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_cubit.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_state.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:delivery_app/src/features/orders/pages/order_assigned_page.dart';
import 'package:delivery_app/src/features/orders/widgets/nearby_order_card.dart';
import 'package:delivery_app/src/features/orders/widgets/order_tracking_map_widget.dart';
import 'package:delivery_app/src/features/orders/widgets/empty_orders_map_widget.dart';

class TrackOrdersPage extends StatefulWidget {
  const TrackOrdersPage({
    super.key,
  });

  @override
  State<TrackOrdersPage> createState() => _TrackOrdersPageState();
}

class _TrackOrdersPageState extends State<TrackOrdersPage> {
  @override
  void initState() {
    super.initState();
    locator<OrdersCubit>().fetchOrdersNearby();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: BlocProvider<OrdersCubit>.value(
      value: locator<OrdersCubit>(),
      child: BlocConsumer<OrdersCubit, OrdersState>(
        listener: _handleStateChanges,
        builder: _buildContent,
      ),
    ));
  }

  void _handleStateChanges(BuildContext context, OrdersState state) {
    final localizations = AppLocalizations.of(context)!;
    if (state is OrderActionError) {
      _showErrorSnackBar(context, _translateErrorMessage(state.message, localizations));
    } else if (state is OrderActionSuccess) {
      if (state.orderId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OrderAssignedPage(
              orderId: state.orderId!,
            ),
          ),
        );
      } else {
        _showSuccessSnackBar(context, _translateSuccessMessage(state.message, localizations));
      }
    }
  }

  Widget _buildContent(BuildContext context, OrdersState state) {
    if (state is OrdersLoading) {
      return _buildLoadingState();
    } else if (state is OrdersLoaded) {
      if (state.orders.isEmpty) {
        return _buildEmptyState();
      }
      return _buildMapWithCards(state);
    } else if (state is OrderActionLoading) {
      if (state.orders.isEmpty) {
        return _buildEmptyState();
      }
      return _buildMapWithCardsFromList(state.orders);
    } else if (state is OrderActionSuccess) {
      if (state.orders.isEmpty) {
        return _buildEmptyState();
      }
      return _buildMapWithCardsFromList(state.orders);
    } else if (state is OrderActionError) {
      if (state.orders.isEmpty) {
        return _buildEmptyState();
      }
      return _buildMapWithCardsFromList(state.orders);
    } else if (state is OrdersError) {
      return _buildErrorState(state.message);
    }
    return _buildLoadingState();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildMapWithCards(OrdersLoaded state) {
    return _buildMapWithCardsFromList(state.orders);
  }

  Widget _buildMapWithCardsFromList(List<OrderModel> orders) {
    return Stack(
      children: [
        OrderTrackingMap(
          orders: orders,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildOrdersCards(orders),
        ),
      ],
    );
  }

  Widget _buildOrdersCards(List<OrderModel> orders) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, currentState) {
        return NearbyOrderCard(
          order: order,
          onDismiss: () {},
        );
      },
    );
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

  Widget _buildEmptyState() {
    return EmptyOrdersMapWidget(
      onRefresh: () {
        context.read<OrdersCubit>().fetchOrdersNearby();
      },
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
              context.read<OrdersCubit>().fetchOrdersNearby();
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
