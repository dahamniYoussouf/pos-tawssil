import 'dart:async';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/order/widgets/validate/swip_to_confirm_button_widget.dart';
import 'package:client_app/src/features/order/widgets/validate/validate_order_confirmation_dialog.dart';
import 'package:client_app/src/features/order/widgets/validate/validate_order_info_widget.dart';
import 'package:client_app/src/features/order/widgets/validate/validate_order_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/features/order/cubit/order_cubit.dart';
import 'package:client_app/src/features/order/cubit/order_state.dart';
import 'package:client_app/src/features/order/pages/order_tracking_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const Color _routeLineBlue = Color(0xFF2196F3);
const Duration _snackBarDuration = Duration(seconds: 3);
const Duration _navigationDelay = Duration(seconds: 2);
const double _cardTopRadius = 24.0;

class ValidateOrderPage extends StatefulWidget {
  final String deliveryAddress;
  final String estimatedTime;
  final String orderNumber;
  final double totalPrice;
  final String paymentMethod;
  final String paymentMethodCode;
  final List<Map<String, dynamic>> orderItems;
  final LatLng? pickupLocation;
  final LatLng? deliveryLocation;
  final String? restaurantName;
  final String? restaurantId;
  final String orderType;
  final double deliveryFee;

  const ValidateOrderPage(
      {super.key,
      required this.deliveryAddress,
      required this.estimatedTime,
      required this.orderNumber,
      required this.totalPrice,
      required this.paymentMethod,
      required this.paymentMethodCode,
      required this.orderItems,
      required this.orderType,
      required this.deliveryFee,
      this.pickupLocation,
      this.deliveryLocation,
      this.restaurantName,
      this.restaurantId});

  @override
  State<ValidateOrderPage> createState() => _ValidateOrderPageState();
}

class _ValidateOrderPageState extends State<ValidateOrderPage> {
  MapController? _mapController;
  late final LatLng _pickupLatLng;
  late final LatLng _deliveryLatLng;
  late final List<Marker> _markers;
  late final List<Polyline> _polylines;
  late final List<ValidateOrderItemData> _orderItems;
  bool _isLoading = false;
  final GlobalKey<SwipeToConfirmButtonState> _swipeButtonKey =
      GlobalKey<SwipeToConfirmButtonState>();

  @override
  void initState() {
    super.initState();
    _initializeLocations();
    _markers = _createMarkers();
    _polylines = _createPolylines();
    _orderItems = _createOrderItems();
  }

  void _initializeLocations() {
    _pickupLatLng = widget.pickupLocation ?? const LatLng(36.7538, 3.0588);
    _deliveryLatLng = widget.deliveryLocation ?? const LatLng(36.7738, 3.0888);
  }

  List<ValidateOrderItemData> _createOrderItems() {
    return widget.orderItems
        .map((Map<String, dynamic> item) => ValidateOrderItemData.fromMap(item))
        .toList(growable: false);
  }

  List<Marker> _createMarkers() {
    return <Marker>[
      Marker(
        point: _pickupLatLng,
        width: 44,
        height: 44,
        child: Tooltip(
          message: widget.restaurantName ?? 'Pickup point',
          child: const Icon(Icons.location_on, color: Colors.red, size: 32),
        ),
      ),
      Marker(
        point: _deliveryLatLng,
        width: 44,
        height: 44,
        child: Tooltip(
          message: widget.deliveryAddress,
          child: const Icon(Icons.location_on, color: Colors.red, size: 32),
        ),
      ),
    ];
  }

  List<Polyline> _createPolylines() {
    return <Polyline>[
      Polyline(
        points: <LatLng>[_pickupLatLng, _deliveryLatLng],
        color: _routeLineBlue,
        strokeWidth: 4,
      ),
    ];
  }

  void _onMapCreated(MapController controller) {
    _mapController = controller;
  }

  void _handleOrderState(BuildContext context, OrderState state) {
    if (state is OrderCreated) {
      _onOrderCreated(context, state.order.id);
    } else if (state is OrderError) {
      _onOrderError(context, state.message);
    } else if (state is OrderCreating) {
      _onOrderCreating();
    }
  }

  void _onOrderCreated(BuildContext context, String orderId) {
    setState(() => _isLoading = false);
    _showSuccessSnackBar(context);
    Future<void>.delayed(_navigationDelay, () {
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (BuildContext innerContext) =>
                  OrderTrackingPage(orderId: orderId)));
    });
  }

  void _onOrderError(BuildContext context, String message) {
    setState(() => _isLoading = false);
    final AppLocalizations localization = AppLocalizations.of(context)!;
    final String feedback = '${localization.verificationError} $message';
    _showErrorSnackBar(context, feedback);
  }

  void _onOrderCreating() {
    setState(() => _isLoading = true);
    _swipeButtonKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    return BlocListener<OrderCubit, OrderState>(
        listener: _handleOrderState,
        child: Scaffold(
          body: Stack(children: [
            Container(
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(_cardTopRadius),
                        topRight: Radius.circular(_cardTopRadius))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(height: 12),
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text('Order Overview',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 16),
                  ValidateOrderMapCard(
                      pickupLatLng: _pickupLatLng,
                      deliveryLatLng: _deliveryLatLng,
                      markers: _markers,
                      polylines: _polylines,
                      onMapCreated: _onMapCreated,
                      estimatedTime: widget.estimatedTime),
                  Flexible(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ValidateOrderDetailsSection(
                              deliveryAddress: widget.deliveryAddress,
                              estimatedTime: widget.estimatedTime,
                              totalPrice: widget.totalPrice,
                              paymentMethod: widget.paymentMethod,
                              items: _orderItems,
                              orderDetailsLabel: localization.orderDetailsLabel,
                              localization: localization))),
                ])),
            if (_isLoading)
              Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(ColorApp.primary))))
          ]),
          floatingActionButton: ValidateOrderActionBar(
              isLoading: _isLoading,
              onConfirm: () {
                _submitOrder();
              },
              label: localization.validate,
              swipeButtonKey: _swipeButtonKey),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        ));
  }

  Future<void> _submitOrder() async {
    if (widget.restaurantId == null) {
      _showErrorSnackBar(
          context, AppLocalizations.of(context)!.verificationError);
      return;
    }
    final OrderCubit cubit = context.read<OrderCubit>();
    await cubit.createOrder(
        restaurantId: widget.restaurantId!,
        orderType: widget.orderType,
        deliveryAddress: widget.deliveryAddress,
        lat: widget.deliveryLocation?.latitude.toString() ??
            _deliveryLatLng.latitude.toString(),
        lng: widget.deliveryLocation?.longitude.toString() ??
            _deliveryLatLng.longitude.toString(),
        deliveryFee: widget.deliveryFee,
        paymentMethod: widget.paymentMethodCode,
        items: widget.orderItems);
  }

  void _showSuccessSnackBar(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    final Widget content = Row(children: <Widget>[
      const Icon(Icons.check_circle, color: Colors.white),
      const SizedBox(width: 12),
      Expanded(
          child: Text(localization.orderValidatedSuccessfully,
              style: const TextStyle(fontWeight: FontWeight.w600)))
    ]);
    _showSnackBar(context, content, Colors.green);
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final Widget content = Row(children: <Widget>[
      const Icon(Icons.error_outline, color: Colors.white),
      const SizedBox(width: 12),
      Expanded(
          child: Text(message,
              style: const TextStyle(fontWeight: FontWeight.w600)))
    ]);
    _showSnackBar(context, content, Colors.red);
  }

  void _showSnackBar(
      BuildContext context, Widget content, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: content,
        backgroundColor: backgroundColor,
        duration: _snackBarDuration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
