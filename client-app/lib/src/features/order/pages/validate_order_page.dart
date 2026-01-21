import 'dart:async';
import 'dart:math';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/order/widgets/validate/swip_to_confirm_button_widget.dart';
import 'package:client_app/src/features/order/widgets/validate/validate_order_confirmation_dialog.dart';
import 'package:client_app/src/features/order/widgets/validate/validate_order_info_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/features/order/cubit/order_cubit.dart';
import 'package:client_app/src/features/order/cubit/order_state.dart';
import 'package:client_app/src/features/order/pages/order_tracking_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;

const Color _routeLineBlue = Color(0xFF2196F3);
const Duration _snackBarDuration = Duration(seconds: 3);
const Duration _navigationDelay = Duration(seconds: 2);
const double _pageHorizontalPadding = 16.0;
const double _contentBottomPadding = 140.0;
const double _sectionSpacing = 16.0;
const double _cardRadius = 17.0;
const double _mapHeight = 200.0;
const double _mapCameraPadding = 50.0;

class ValidateOrderPage extends StatefulWidget {
  final String deliveryAddress;
  final String estimatedTime;
  final String orderNumber;
  final double totalPrice;
  final String paymentMethod;
  final String paymentMethodCode;
  final List<Map<String, dynamic>> orderItems;
  final latlong.LatLng? pickupLocation;
  final latlong.LatLng? deliveryLocation;
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
  GoogleMapController? _mapController;
  late final latlong.LatLng _pickupLatLng;
  late final latlong.LatLng _deliveryLatLng;
  late final Set<Polyline> _polylines;
  late final List<ValidateOrderItemData> _orderItems;
  bool _isLoading = false;
  final GlobalKey<SwipeToConfirmButtonState> _swipeButtonKey =
      GlobalKey<SwipeToConfirmButtonState>();

  @override
  void initState() {
    super.initState();
    _initializeLocations();
    _polylines = _createPolylines();
    _orderItems = _createOrderItems();
  }

  void _initializeLocations() {
    _pickupLatLng =
        widget.pickupLocation ?? const latlong.LatLng(36.7538, 3.0588);
    _deliveryLatLng =
        widget.deliveryLocation ?? const latlong.LatLng(36.7738, 3.0888);
  }

  List<ValidateOrderItemData> _createOrderItems() {
    return widget.orderItems
        .map((Map<String, dynamic> item) => ValidateOrderItemData.fromMap(item))
        .toList(growable: false);
  }

  Set<Marker> _createMarkers(
      {required String pickupLabel, required String deliveryLabel}) {
    return <Marker>{
      Marker(
          markerId: const MarkerId('pickup'),
          position: _convertToGoogleLatLng(_pickupLatLng),
          infoWindow: InfoWindow(title: widget.restaurantName ?? pickupLabel)),
      Marker(
          markerId: const MarkerId('delivery'),
          position: _convertToGoogleLatLng(_deliveryLatLng),
          infoWindow: InfoWindow(title: deliveryLabel)),
    };
  }

  Set<Polyline> _createPolylines() {
    return <Polyline>{
      Polyline(
        polylineId: const PolylineId('route'),
        points: <LatLng>[
          _convertToGoogleLatLng(_pickupLatLng),
          _convertToGoogleLatLng(_deliveryLatLng)
        ],
        color: _routeLineBlue,
        width: 4,
      ),
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _moveCameraToBounds(controller);
  }

  void _moveCameraToBounds(GoogleMapController controller) {
    final LatLngBounds bounds = _createMapBounds();
    controller
        .animateCamera(CameraUpdate.newLatLngBounds(bounds, _mapCameraPadding));
  }

  LatLng _createMapCenter() {
    final double latitude =
        (_pickupLatLng.latitude + _deliveryLatLng.latitude) / 2;
    final double longitude =
        (_pickupLatLng.longitude + _deliveryLatLng.longitude) / 2;
    return LatLng(latitude, longitude);
  }

  LatLngBounds _createMapBounds() {
    final double south = min(_pickupLatLng.latitude, _deliveryLatLng.latitude);
    final double west = min(_pickupLatLng.longitude, _deliveryLatLng.longitude);
    final double north = max(_pickupLatLng.latitude, _deliveryLatLng.latitude);
    final double east = max(_pickupLatLng.longitude, _deliveryLatLng.longitude);
    return LatLngBounds(
        southwest: LatLng(south, west), northeast: LatLng(north, east));
  }

  LatLng _convertToGoogleLatLng(latlong.LatLng value) {
    return LatLng(value.latitude, value.longitude);
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
    final Set<Marker> markers = _createMarkers(
        pickupLabel: localization.pickupPoint,
        deliveryLabel: widget.deliveryAddress);
    final LatLng mapCenter = _createMapCenter();
    return BlocListener<OrderCubit, OrderState>(
        listener: _handleOrderState,
        child: Scaffold(
          backgroundColor: ColorApp.white,
          body: Stack(children: [
            SafeArea(
                child: Column(children: [
              const SizedBox(height: 12),
              const _DragHandle(),
              const SizedBox(height: 12),
              Expanded(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(_pageHorizontalPadding,
                          0, _pageHorizontalPadding, _contentBottomPadding),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PageTitle(title: localization.orderOverview),
                            const SizedBox(height: _sectionSpacing),
                            _SectionCard(
                                child: SizedBox(
                                    height: _mapHeight,
                                    child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(_cardRadius),
                                        child: GoogleMap(
                                          onMapCreated: _onMapCreated,
                                          initialCameraPosition: CameraPosition(
                                              target: mapCenter, zoom: 12),
                                          markers: markers,
                                          polylines: _polylines,
                                          myLocationEnabled: false,
                                          myLocationButtonEnabled: false,
                                          mapToolbarEnabled: false,
                                          zoomControlsEnabled: false,
                                          compassEnabled: false,
                                        )))),
                            const SizedBox(height: _sectionSpacing),
                            ValidateOrderDetailsSection(
                                deliveryAddress: widget.deliveryAddress,
                                estimatedTime: widget.estimatedTime,
                                totalPrice: widget.totalPrice,
                                paymentMethod: widget.paymentMethod,
                                items: _orderItems,
                                orderDetailsLabel:
                                    localization.orderDetailsLabel,
                                localization: localization,
                                orderNumber: widget.orderNumber),
                          ])))
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
    final Widget content = Row(children: [
      const Icon(Icons.check_circle, color: Colors.white),
      const SizedBox(width: 12),
      Expanded(
          child: Text(localization.orderValidatedSuccessfully,
              style: const TextStyle(fontWeight: FontWeight.w600)))
    ]);
    _showSnackBar(context, content, Colors.green);
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final Widget content = Row(children: [
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

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: ColorApp.greyBorder,
            borderRadius: BorderRadius.circular(2)));
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorApp.textBlack),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(_cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: child);
  }
}
