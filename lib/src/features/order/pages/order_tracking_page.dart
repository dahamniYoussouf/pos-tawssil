import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/src/core/res/color_app.dart';
import 'package:frontend/src/features/home/pages/home_page.dart';
import 'package:frontend/src/features/order/widgets/delivery_person_card_widget.dart';
import 'package:frontend/src/features/order/widgets/order_details_card_widget.dart';
import 'package:frontend/src/features/order/widgets/order_timeline_widget.dart';
import 'package:frontend/src/features/order/widgets/order_tracking_map_widget.dart';
import 'package:frontend/src/features/order/widgets/status_card_widget.dart';
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
  late final OrderCubit _orderCubit;

  @override
  void initState() {
    super.initState();
    _orderCubit = context.read<OrderCubit>();
    _executeInitialLoad();
  }

  @override
  void dispose() {
    _orderCubit.stopPolling();
    super.dispose();
  }

  void _executeInitialLoad() {
    _orderCubit.fetchOrder(widget.orderId);
    _orderCubit.startPolling();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    return Scaffold(
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (BuildContext context, OrderState state) => _handleStateListener(context, state, localization),
        builder: (BuildContext context, OrderState state) => _buildStateBody(context, state, localization),
      ),
    );
  }

  void _handleStateListener(BuildContext context, OrderState state, AppLocalizations localization) {
    if (state is OrderLoaded || state is OrderRefused || state is OrderDelayed) {
      final OrderModel order = _extractOrderFromState(state);
      if (_isInitialLoad) {
        _isInitialLoad = false;
      }
      _handleOrderUpdate(order);
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

  Widget _buildStateBody(BuildContext context, OrderState state, AppLocalizations localization) {
    if ((state is OrderLoading || state is OrderInitial) && _isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is OrderError && _isInitialLoad) {
      return _buildInitialError(context, state, localization);
    }
    final OrderModel? order = _extractOrderFromStateOrNull(state) ?? _currentOrder;
    if (order != null) {
      return _buildOrderTrackingContent(context, order, localization);
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildInitialError(BuildContext context, OrderError state, AppLocalizations localization) {
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
              _orderCubit.refreshOrder();
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

  Widget _buildOrderTrackingContent(BuildContext context, OrderModel order, AppLocalizations localization) {
    return Stack(
      children: <Widget>[
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: OrderTrackingMap(
            order: order,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 2,
          left: 16,
          child: SafeArea(
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  _orderCubit.stopPolling();
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
                },
              ),
            ),
          ),
        ),
        _buildContentSheet(order, localization),
      ],
    );
  }

  Widget _buildContentSheet(OrderModel order, AppLocalizations localization) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                const SizedBox(height: 16),
                OrderDetailsCard(order: order),
                const SizedBox(height: 16),
                if (order.isDelivering && order.deliveryPerson != null) DeliveryPersonCard(person: order.deliveryPerson!, localization: localization),
                if (order.isDelivering && order.deliveryPerson != null) const SizedBox(height: 16),
                OrderTimeline(order: order, localization: localization),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleOrderUpdate(OrderModel order) {
    final bool hasOrderChanged = _currentOrder == null ||
        _currentOrder?.status != order.status ||
        _currentOrder?.deliveryPerson?.id != order.deliveryPerson?.id ||
        _currentOrder?.deliveryPerson?.latitude != order.deliveryPerson?.latitude ||
        _currentOrder?.deliveryPerson?.longitude != order.deliveryPerson?.longitude ||
        _currentOrder?.estimatedDeliveryTime != order.estimatedDeliveryTime;
    if (hasOrderChanged) {
      _currentOrder = order;
    }
  }
}
