import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/media_res.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_cubit.dart';
import 'package:delivery_app/src/features/orders/cubit/order_active_cubit.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_state.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';
import 'package:delivery_app/src/features/orders/pages/order_assigned_page.dart';
import 'package:delivery_app/src/features/orders/zone_orders/presentation/pages/zone_orders_page.dart';
import 'package:delivery_app/src/features/orders/widgets/nearby_order_card.dart';
import 'package:delivery_app/src/features/orders/widgets/order_tracking_map_widget.dart';
import 'package:delivery_app/src/features/orders/widgets/driver_status_bottom_sheet.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_state.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  void _toggleDriverStatusSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DriverStatusBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Material(
        child: BlocProvider<OrdersCubit>.value(
          value: locator<OrdersCubit>(),
          child: BlocConsumer<OrdersCubit, OrdersState>(
            listener: _handleStateChanges,
            builder: _buildContent,
          ),
        ),
      ),
    );
  }

  void _handleStateChanges(BuildContext context, OrdersState state) {
    final localizations = AppLocalizations.of(context)!;
    if (state is OrderActionError) {
      _showErrorSnackBar(
          context, _translateErrorMessage(state.message, localizations));
    } else if (state is OrderActionSuccess) {
      // Refresh active orders list when an order is accepted
      context.read<OrderActiveCubit>().fetchActiveOrders();

      if (state.orderId != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OrderAssignedPage(
              orderId: state.orderId!,
            ),
          ),
        );
      } else {
        _showSuccessSnackBar(
            context, _translateSuccessMessage(state.message, localizations));
      }
    }
  }

  Widget _buildContent(BuildContext context, OrdersState state) {
    final size = MediaQuery.of(context).size;
    final localizations = AppLocalizations.of(context)!;
    List<OrderModel> orders = [];
    Widget mapContent;

    if (state is OrdersLoading) {
      orders = state.orders;
    } else if (state is OrdersLoaded) {
      orders = state.orders;
    } else if (state is OrderActionLoading) {
      orders = state.orders;
    } else if (state is OrderActionSuccess) {
      orders = state.orders;
    } else if (state is OrderActionError) {
      orders = state.orders;
    } else if (state is OrdersError) {
      orders = state.orders;
    }

    if (orders.isEmpty && state is OrdersLoading) {
      mapContent = _buildLoadingState();
    } else if (orders.isEmpty) {
      mapContent = _buildMapOnly();
    } else {
      mapContent = OrderTrackingMap(orders: orders);
    }

    // Calculate dynamic position for radar button
    // If cards exist, position radar above them
    final double radarTopPosition =
        orders.isEmpty ? size.height * 0.45 : size.height * 0.33;

    return Stack(
      children: [
        // Full screen map or loading
        Positioned.fill(child: mapContent),

        // Top Logo Overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: size.height * 0.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.8),
                  Colors.white.withOpacity(0.0),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Image.asset(
                  MediaRes.logo,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),

        // hna Bottom Order Cards (u can scroll and u shows 2 cards)
        if (orders.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildOrdersCards(orders),
          ),

        // Dynamic Status Toggle Button at Top Right
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 20,
          child: BlocBuilder<DriverCubit, DriverState>(
            builder: (context, state) {
              final isActive =
                  state is DriverLoaded ? state.driver.isActive : false;
              return GestureDetector(
                onTap: () => _toggleDriverStatusSheet(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF10B981) : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isActive ? const Color(0xFF10B981) : Colors.red)
                            .withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        isActive ? localizations.online : localizations.offline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isActive
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ZoneOrdersPage(),
                ),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),

        Positioned(
          top: radarTopPosition,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: () {
                if (state is! OrdersLoading) {
                  locator<OrdersCubit>().fetchOrdersNearby();
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 70, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827), // Very dark blue/black
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state is OrdersLoading && orders.isEmpty)
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(right: 8),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    Text(
                      localizations.radarButton,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Error handling if needed - must fill the stack to cover full screen
        if (state is OrdersError)
          Positioned.fill(child: _buildErrorOverlay(state.message)),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildMapOnly() {
    return BlocBuilder<DriverCubit, DriverState>(
      builder: (context, state) {
        final LatLng center =
            state is DriverLoaded && state.driver.latitude != null
                ? LatLng(state.driver.latitude!, state.driver.longitude!)
                : const LatLng(36.7538, 3.0588);
        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: center,
            zoom: 15.0,
          ),
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        );
      },
    );
  }

  Widget _buildErrorOverlay(String message) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: _buildErrorState(message),
    );
  }

  Widget _buildOrdersCards(List<OrderModel> orders) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20), // Spacing from nav bar
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: SingleChildScrollView(
        reverse: true, // Start from the bottom if multiple
        child: Column(
          mainAxisSize: MainAxisSize.min,
          verticalDirection: VerticalDirection
              .up, // Stack new ones at top or keep logic simple
          children: orders.map((order) => _buildOrderCard(order)).toList(),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, currentState) {
        return NearbyOrderCard(
          order: order,
          onDismiss: () {
            context.read<OrdersCubit>().dismissOrder(order.id);
          },
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

  String _translateSuccessMessage(
      String message, AppLocalizations localizations) {
    if (message.contains('accepted successfully')) {
      return localizations.orderAcceptedSuccess;
    } else if (message.contains('declined successfully')) {
      return localizations.orderRefusedSuccess;
    } else if (message.contains('refused successfully')) {
      return localizations.orderRefusedSuccess;
    }
    return message;
  }

  String _translateErrorMessage(
      String message, AppLocalizations localizations) {
    if (message.contains('Invalid response format')) {
      return localizations.errorInvalidResponseFormat;
    } else if (message.contains('Failed to fetch orders')) {
      return localizations.errorFailedToFetchOrders;
    } else if (message.contains('Failed to accept order')) {
      return localizations.errorFailedToAcceptOrder;
    } else if (message.contains('Error accepting order:')) {
      final errorMatch =
          RegExp(r'Error accepting order: (.+)').firstMatch(message);
      if (errorMatch != null) {
        return localizations.errorAcceptingOrder(errorMatch.group(1) ?? '');
      }
      return localizations.errorAcceptingOrder(message);
    } else if (message.contains('Failed to decline order')) {
      return localizations.errorFailedToRefuseOrder;
    } else if (message.contains('Error declining order:')) {
      final errorMatch =
          RegExp(r'Error declining order: (.+)').firstMatch(message);
      if (errorMatch != null) {
        return localizations.errorRefusingOrder(errorMatch.group(1) ?? '');
      }
      return localizations.errorRefusingOrder(message);
    } else if (message.contains('Failed to refuse order')) {
      return localizations.errorFailedToRefuseOrder;
    } else if (message.contains('Error refusing order:')) {
      final errorMatch =
          RegExp(r'Error refusing order: (.+)').firstMatch(message);
      if (errorMatch != null) {
        return localizations.errorRefusingOrder(errorMatch.group(1) ?? '');
      }
      return localizations.errorRefusingOrder(message);
    }
    return message;
  }
}
