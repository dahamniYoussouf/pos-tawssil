import 'package:client_app/src/core/utils/dependency_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/home/pages/home_page.dart';
import 'package:client_app/src/features/order/widgets/delivery_person_card_widget.dart';
import 'package:client_app/src/features/order/widgets/order_details_card_widget.dart';
import 'package:client_app/src/features/order/widgets/order_tracking_map_widget.dart';
import 'package:client_app/src/features/order/widgets/status_card_widget.dart';
import 'package:client_app/src/features/order/widgets/order_tracking_steps_widget.dart';
import 'package:client_app/src/features/order/widgets/validate_order_button_widget.dart';
import 'package:client_app/src/features/order/widgets/declined_order_widget.dart';
import 'package:client_app/src/features/review/index.dart';
import 'package:easy_refresh/easy_refresh.dart';
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
    _executeInitialLoad();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _executeInitialLoad() {
    final orderCubit = locator<OrderCubit>();
    if (!orderCubit.isClosed) {
      orderCubit.fetchOrder(widget.orderId);
    }
  }

  Future<void> _executeRefresh() async {
    final orderCubit = locator<OrderCubit>();
    if (orderCubit.isClosed) {
      return;
    }
    _isInitialLoad = false;
    await orderCubit.refreshOrder();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    final orderCubit = locator<OrderCubit>();
    return Scaffold(
      backgroundColor: ColorApp.white,
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
      if (order.isDelivered && !_hasShownSuccessDialog) {
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
            height: MediaQuery.of(context).size.height * 0.6,
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
            child: EasyRefresh.builder(
              onRefresh: _executeRefresh,
              header: const ClassicHeader(
                backgroundColor: ColorApp.white,
                textStyle: TextStyle(
                  color: ColorApp.textBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              childBuilder: (BuildContext context, ScrollPhysics physics) {
                final ScrollPhysics refreshPhysics =
                    const AlwaysScrollableScrollPhysics().applyTo(physics);
                return SingleChildScrollView(
                  physics: refreshPhysics,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Column(
                      children: [
                        _buildBackButton(context),
                        _buildSheetContent(order, localization,
                            includeHandle: false, isDelivery: isDelivery),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    } else {
      // delivery order
      return DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.40,
        maxChildSize: 0.70,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: EasyRefresh.builder(
              onRefresh: _executeRefresh,
              header: const ClassicHeader(
                backgroundColor: ColorApp.white,
                textStyle: TextStyle(
                  color: ColorApp.textBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              childBuilder: (BuildContext context, ScrollPhysics physics) {
                final ScrollPhysics refreshPhysics =
                    const AlwaysScrollableScrollPhysics().applyTo(physics);
                return SingleChildScrollView(
                  controller: scrollController,
                  physics: refreshPhysics,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildSheetContent(order, localization,
                        includeHandle: true, isDelivery: isDelivery),
                  ),
                );
              },
            ),
          );
        },
      );
    }
  }

  Widget _buildSheetContent(OrderModel order, AppLocalizations localization,
      {required bool includeHandle, required bool isDelivery}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (includeHandle)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 75,
              height: 8,
              decoration: BoxDecoration(
                color: ColorApp.greyBorder,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        StatusCardWidget(order: order),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OrderTrackingStepsWidget(
              orderStatus: order.status, isDelivery: isDelivery),
        ),
        const SizedBox(height: 8),
        Divider(indent: 4, endIndent: 4, color: ColorApp.greyBorder),
        const SizedBox(height: 16),
        OrderDetailsCard(order: order),
        if (order.isDelivered) const ValidateOrderButtonWidget(),
        const SizedBox(height: 16),
        // check if order is delivery mode
        if (isDelivery)
          DeliveryPersonCard(
              person: order.deliveryPerson, localization: localization),
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
