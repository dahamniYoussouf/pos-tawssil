import 'package:client_app/src/core/utils/dependency_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/home/pages/home_page.dart';
import 'package:client_app/src/features/order/widgets/delivery_person_card_widget.dart';
import 'package:client_app/src/features/order/widgets/order_details_card_widget.dart';
import 'package:client_app/src/features/order/widgets/order_timeline_widget.dart';
import 'package:client_app/src/features/order/widgets/order_tracking_map_widget.dart';
import 'package:client_app/src/features/order/widgets/restaurant_info_card_widget.dart';
import 'package:client_app/src/features/order/widgets/status_card_widget.dart';
import 'package:client_app/src/features/order/widgets/validate_order_button_widget.dart';
import 'package:client_app/src/features/order/widgets/declined_order_widget.dart';
import 'package:client_app/src/features/review/index.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import '../models/order_model.dart';

class OrderTrackingPage extends StatefulWidget {
  final String orderId;
  const OrderTrackingPage({super.key, required this.orderId});
  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  OrderModel? _currentOrder;
  bool _isInitialLoad = true;
  bool _hasShownSuccessDialog = false;

  @override
  void initState() {
    super.initState();
    final orderCubit = locator<OrderCubit>();
    // Stop any existing polling and reset state before starting new one
    orderCubit.stopPolling();
    // Only reset if cubit is not closed (shouldn't happen with singleton, but safety check)
    if (!orderCubit.isClosed) {
      orderCubit.reset();
    }
    _executeInitialLoad();
  }

  @override
  void dispose() {
    locator<OrderCubit>().stopPolling();
    super.dispose();
  }

  void _executeInitialLoad() {
    final orderCubit = locator<OrderCubit>();
    if (!orderCubit.isClosed) {
      orderCubit.fetchOrder(widget.orderId);
      orderCubit.startPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    final orderCubit = locator<OrderCubit>();
    return Scaffold(
      body: BlocProvider<OrderCubit>.value(
        value: orderCubit,
        child: BlocConsumer<OrderCubit, OrderState>(
          listener: (BuildContext context, OrderState state) =>
              _handleStateListener(context, state, localization),
          builder: (BuildContext context, OrderState state) =>
              _buildStateBody(context, state, localization),
        ),
      ),
    );
  }

  void _handleStateListener(
      BuildContext context, OrderState state, AppLocalizations localization) {
    if (state is OrderLoaded ||
        state is OrderRefused ||
        state is OrderDelayed) {
      final OrderModel order = _extractOrderFromState(state);
      if (_isInitialLoad) {
        _isInitialLoad = false;
      }
      _handleOrderUpdate(order);

      // Show success dialog when order is delivered for the first time
      if (order.isPending && !_hasShownSuccessDialog) {
        _hasShownSuccessDialog = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showDeliverySuccessDialog(context, order.id);
        });
      }
    }
    if (state is OrderError && _isInitialLoad) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: ColorApp.redColor,
        ),
      );
    }
    if (state is OrderRefused) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localization.orderRefused}: ${state.reason}'),
          backgroundColor: ColorApp.orangeColor,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    if (state is OrderDelayed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localization.orderDelayed}: ${state.reason}'),
          backgroundColor: ColorApp.orangeColor,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildStateBody(
      BuildContext context, OrderState state, AppLocalizations localization) {
    if ((state is OrderLoading || state is OrderInitial) && _isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is OrderError && _isInitialLoad) {
      return _buildInitialError(context, state, localization);
    }
    // Check if order is declined
    if (state is OrderRefused) {
      return DeclinedOrderWidget(refusalReason: state.reason);
    }
    final OrderModel? order =
        _extractOrderFromStateOrNull(state) ?? _currentOrder;
    if (order != null) {
      // Also check if order status is declined
      if (order.isRefused) {
        return DeclinedOrderWidget(refusalReason: order.refusalReason);
      }
      return _buildOrderTrackingContent(context, order, localization);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildInitialError(
      BuildContext context, OrderError state, AppLocalizations localization) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            state.message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _isInitialLoad = true;
              locator<OrderCubit>().refreshOrder();
            },
            child: Text(localization.retry),
          ),
        ],
      ),
    );
  }

  OrderModel _extractOrderFromState(OrderState state) {
    if (state is OrderLoaded) {
      return state.order;
    }
    if (state is OrderRefused) {
      return state.order;
    }
    return (state as OrderDelayed).order;
  }

  OrderModel? _extractOrderFromStateOrNull(OrderState state) {
    if (state is OrderLoaded) {
      return state.order;
    }
    if (state is OrderRefused) {
      return state.order;
    }
    if (state is OrderDelayed) {
      return state.order;
    }
    return null;
  }

  Widget _buildOrderTrackingContent(
      BuildContext context, OrderModel order, AppLocalizations localization) {
    final bool isDelivery = order.orderType == "delivery";
    return Stack(
      children: [
        if (isDelivery) ...[
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: OrderTrackingMap(
              order: order,
            ),
          ),
        ],
        _buildBackButton(context),
        _buildContentSheet(context, order, localization,
            isDelivery: isDelivery),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16, left: 8),
          child: CircleAvatar(
            backgroundColor: ColorApp.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: ColorApp.black),
              onPressed: () {
                locator<OrderCubit>().stopPolling();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSheet(
      BuildContext context, OrderModel order, AppLocalizations localization,
      {required bool isDelivery}) {
    if (!isDelivery) {
      // pickup order
      return Positioned.fill(
        child: Container(
          color: Colors.white,
          child: SafeArea(
            top: true,
            bottom: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  children: [
                    _buildBackButton(context),
                    _buildSheetContent(order, localization,
                        includeHandle: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // delivery order
      return DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildSheetContent(order, localization,
                    includeHandle: true),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildSheetContent(OrderModel order, AppLocalizations localization,
      {required bool includeHandle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (includeHandle)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        StatusCardWidget(order: order),
        if (order.isDelivering && order.deliveryPerson != null)
          const SizedBox(height: 16),
        if (order.isDelivering && order.deliveryPerson != null)
          DeliveryPersonCard(
              person: order.deliveryPerson!, localization: localization),
        const SizedBox(height: 16),
        RestaurantInfoCard(order: order),
        const SizedBox(height: 16),
        OrderDetailsCard(order: order),
        const SizedBox(height: 16),
        OrderTimeline(order: order, localization: localization),
        const SizedBox(height: 16),
        if (order.isDelivered) const ValidateOrderButtonWidget(),
      ],
    );
  }

  void _handleOrderUpdate(OrderModel order) {
    final bool hasOrderChanged = _currentOrder == null ||
        _currentOrder?.status != order.status ||
        _currentOrder?.deliveryPerson?.id != order.deliveryPerson?.id ||
        _currentOrder?.deliveryPerson?.latitude !=
            order.deliveryPerson?.latitude ||
        _currentOrder?.deliveryPerson?.longitude !=
            order.deliveryPerson?.longitude ||
        _currentOrder?.estimatedDeliveryTime != order.estimatedDeliveryTime;
    if (hasOrderChanged) {
      _currentOrder = order;
    }
  }

  void _showDeliverySuccessDialog(BuildContext context, String orderId) {
    DeliverySuccessDialog.show(
      context,
      () {
        // Navigate to restaurant review page when OK is pressed
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantReviewPage(orderId: orderId),
          ),
        );
      },
    );
  }
}
