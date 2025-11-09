import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/src/features/order/cubit/order_cubit.dart';
import 'package:frontend/src/features/order/cubit/order_state.dart';
import 'package:frontend/src/features/order/pages/order_tracking_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const Color _validateOrderPrimaryColor = Color(0xFF00695C);
const Duration _snackBarDuration = Duration(seconds: 3);
const Duration _navigationDelay = Duration(seconds: 2);
const Duration _fitBoundsDelay = Duration(milliseconds: 500);
const double _mapHeight = 250.0;

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
  GoogleMapController? _mapController;
  late final LatLng _pickupLatLng;
  late final LatLng _deliveryLatLng;
  late final Set<Marker> _markers;
  late final Set<Polyline> _polylines;
  late final List<ValidateOrderItemData> _orderItems;
  bool _isLoading = false;
  final GlobalKey<SwipeToConfirmButtonState> _swipeButtonKey = GlobalKey<SwipeToConfirmButtonState>();

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
    return widget.orderItems.map((Map<String, dynamic> item) => ValidateOrderItemData.fromMap(item)).toList(growable: false);
  }

  Set<Marker> _createMarkers() {
    return <Marker>{
      Marker(markerId: const MarkerId('pickup'), position: _pickupLatLng, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed), infoWindow: InfoWindow(title: widget.restaurantName ?? 'Pickup point', snippet: 'Restaurant')),
      Marker(markerId: const MarkerId('delivery'), position: _deliveryLatLng, icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), infoWindow: InfoWindow(title: 'Destination', snippet: widget.deliveryAddress))
    };
  }

  Set<Polyline> _createPolylines() {
    return <Polyline>{
      Polyline(polylineId: const PolylineId('route'), points: <LatLng>[_pickupLatLng, _deliveryLatLng], color: _validateOrderPrimaryColor, width: 4, patterns: <PatternItem>[PatternItem.dash(20), PatternItem.gap(10)])
    };
  }

  void _fitMarkersInBounds() {
    if (_mapController == null) return;
    final double minLat = _pickupLatLng.latitude < _deliveryLatLng.latitude ? _pickupLatLng.latitude : _deliveryLatLng.latitude;
    final double maxLat = _pickupLatLng.latitude > _deliveryLatLng.latitude ? _pickupLatLng.latitude : _deliveryLatLng.latitude;
    final double minLng = _pickupLatLng.longitude < _deliveryLatLng.longitude ? _pickupLatLng.longitude : _deliveryLatLng.longitude;
    final double maxLng = _pickupLatLng.longitude > _deliveryLatLng.longitude ? _pickupLatLng.longitude : _deliveryLatLng.longitude;
    final LatLngBounds bounds = LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    Future<void>.delayed(_fitBoundsDelay, () {
      if (!mounted) return;
      _fitMarkersInBounds();
    });
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
      Navigator.push(context, MaterialPageRoute<void>(builder: (BuildContext innerContext) => OrderTrackingPage(orderId: orderId)));
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text(localization.validateOrder, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    final List<OrderInformationData> infoItems = _createInformationItems(localization);
    return BlocListener<OrderCubit, OrderState>(
        listener: _handleOrderState,
        child: Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildAppBar(context),
            body: Stack(children: <Widget>[
              Column(children: <Widget>[
                ValidateOrderMapCard(pickupLatLng: _pickupLatLng, deliveryLatLng: _deliveryLatLng, markers: _markers, polylines: _polylines, onMapCreated: _onMapCreated, estimatedTime: widget.estimatedTime),
                Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 16), child: ValidateOrderDetailsSection(infoItems: infoItems, items: _orderItems, orderDetailsLabel: localization.orderDetailsLabel))),
                ValidateOrderActionBar(isLoading: _isLoading, onConfirm: _showConfirmationDialog, label: localization.validate, swipeButtonKey: _swipeButtonKey)
              ]),
              if (_isLoading) Container(color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_validateOrderPrimaryColor))))
            ])));
  }

  List<OrderInformationData> _createInformationItems(AppLocalizations localization) {
    return <OrderInformationData>[
      OrderInformationData(icon: Icons.location_on_outlined, title: localization.deliveryAddressLabel, subtitle: widget.deliveryAddress),
      OrderInformationData(icon: Icons.access_time, title: localization.deliveryTime, subtitle: widget.estimatedTime),
      OrderInformationData(icon: Icons.receipt_outlined, title: localization.orderNumber, subtitle: widget.orderNumber),
      OrderInformationData(icon: Icons.payments_outlined, title: localization.totalLabel, subtitle: localization.totalValue(widget.totalPrice.toStringAsFixed(2)), isTotal: true),
      OrderInformationData(icon: Icons.credit_card, title: localization.paymentMethodLabel, subtitle: widget.paymentMethod)
    ];
  }

  Future<void> _submitOrder() async {
    if (widget.restaurantId == null) {
      _showErrorSnackBar(context, AppLocalizations.of(context)!.verificationError);
      return;
    }
    final OrderCubit cubit = context.read<OrderCubit>();
    await cubit.createOrder(
        restaurantId: widget.restaurantId!,
        orderType: widget.orderType,
        deliveryAddress: widget.deliveryAddress,
        lat: widget.deliveryLocation?.latitude.toString() ?? _deliveryLatLng.latitude.toString(),
        lng: widget.deliveryLocation?.longitude.toString() ?? _deliveryLatLng.longitude.toString(),
        deliveryFee: widget.deliveryFee,
        paymentMethod: widget.paymentMethodCode,
        items: widget.orderItems);
  }

  void _showSuccessSnackBar(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    final Widget content = Row(children: <Widget>[const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(localization.orderValidatedSuccessfully, style: const TextStyle(fontWeight: FontWeight.w600)))]);
    _showSnackBar(context, content, Colors.green);
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final Widget content = Row(children: <Widget>[const Icon(Icons.error_outline, color: Colors.white), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)))]);
    _showSnackBar(context, content, Colors.red);
  }

  void _showSnackBar(BuildContext context, Widget content, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: content, backgroundColor: backgroundColor, duration: _snackBarDuration, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));
  }

  void _showConfirmationDialog() {
    final AppLocalizations localization = AppLocalizations.of(context)!;
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return ValidateOrderConfirmationDialog(
              title: localization.confirmOrder,
              message: localization.confirmOrderMessage,
              totalLabel: localization.totalLabel,
              totalValue: localization.totalValue(widget.totalPrice.toStringAsFixed(2)),
              paymentLabel: localization.payment,
              paymentValue: widget.paymentMethod,
              deliveryTimeLabel: localization.deliveryTime,
              deliveryTimeValue: widget.estimatedTime,
              cancelLabel: localization.cancel,
              confirmLabel: localization.confirm,
              onCancel: () {
                Navigator.of(dialogContext).pop();
                _swipeButtonKey.currentState?.reset();
              },
              onConfirm: () {
                Navigator.of(dialogContext).pop();
                _submitOrder();
              });
        });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class ValidateOrderMapCard extends StatelessWidget {
  const ValidateOrderMapCard({super.key, required this.pickupLatLng, required this.deliveryLatLng, required this.markers, required this.polylines, required this.onMapCreated, required this.estimatedTime});
  final LatLng pickupLatLng;
  final LatLng deliveryLatLng;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final ValueChanged<GoogleMapController> onMapCreated;
  final String estimatedTime;

  @override
  Widget build(BuildContext context) {
    final LatLng center = LatLng((pickupLatLng.latitude + deliveryLatLng.latitude) / 2, (pickupLatLng.longitude + deliveryLatLng.longitude) / 2);
    return Container(
      height: _mapHeight,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: <Widget>[
            GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: 12),
              markers: markers,
              polylines: polylines,
              onMapCreated: onMapCreated,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.access_time, size: 16, color: _validateOrderPrimaryColor),
                    const SizedBox(width: 4),
                    Text(
                      estimatedTime,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _validateOrderPrimaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ValidateOrderDetailsSection extends StatelessWidget {
  const ValidateOrderDetailsSection({super.key, required this.infoItems, required this.items, required this.orderDetailsLabel});
  final List<OrderInformationData> infoItems;
  final List<ValidateOrderItemData> items;
  final String orderDetailsLabel;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[const SizedBox(height: 8)];
    for (int i = 0; i < infoItems.length; i += 1) {
      children.add(OrderInformationTile(data: infoItems[i]));
      children.add(Divider(color: Colors.grey[200], height: 1));
    }
    children.add(OrderItemsCard(items: items, title: orderDetailsLabel));
    children.add(const SizedBox(height: 20));
    return Column(children: children);
  }
}

class OrderInformationTile extends StatelessWidget {
  const OrderInformationTile({super.key, required this.data});
  final OrderInformationData data;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = data.isTotal ? _validateOrderPrimaryColor : Colors.black87;
    final Color backgroundColor = data.isTotal ? _validateOrderPrimaryColor.withOpacity(0.1) : Colors.grey[100]!;
    final Color valueColor = data.isTotal ? _validateOrderPrimaryColor : Colors.grey[600]!;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(8)), child: Icon(data.icon, size: 20, color: iconColor)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text(data.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: iconColor)),
            const SizedBox(height: 4),
            Text(data.subtitle, style: TextStyle(fontSize: data.isTotal ? 16 : 13, fontWeight: data.isTotal ? FontWeight.w700 : FontWeight.normal, color: valueColor))
          ]))
        ]));
  }
}

class OrderItemsCard extends StatelessWidget {
  const OrderItemsCard({super.key, required this.items, required this.title});
  final List<ValidateOrderItemData> items;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.restaurant_menu, size: 20, color: Colors.black87)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)), child: Column(children: _buildItemRows()))
          ]))
        ]));
  }

  List<Widget> _buildItemRows() {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < items.length; i += 1) {
      final ValidateOrderItemData item = items[i];
      rows.add(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
        Expanded(child: Text('${item.quantity}x ${item.name}', style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w500))),
        if (item.price != null) Text('${item.price} DA', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600))
      ]));
      if (i != items.length - 1) {
        rows.add(const SizedBox(height: 8));
      }
    }
    return rows;
  }
}

class ValidateOrderActionBar extends StatelessWidget {
  const ValidateOrderActionBar({super.key, required this.isLoading, required this.onConfirm, required this.label, required this.swipeButtonKey});
  final bool isLoading;
  final VoidCallback onConfirm;
  final String label;
  final GlobalKey<SwipeToConfirmButtonState> swipeButtonKey;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: <BoxShadow>[BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, -2))]),
        child: SafeArea(
            child: isLoading ? const SizedBox(height: 56, child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_validateOrderPrimaryColor)))) : SwipeToConfirmButton(key: swipeButtonKey, label: label, onConfirm: onConfirm)));
  }
}

class SwipeToConfirmButton extends StatefulWidget {
  const SwipeToConfirmButton({super.key, required this.label, required this.onConfirm});
  final String label;
  final VoidCallback onConfirm;

  @override
  SwipeToConfirmButtonState createState() => SwipeToConfirmButtonState();
}

class SwipeToConfirmButtonState extends State<SwipeToConfirmButton> {
  double _dragPosition = 0.0;

  void reset() {
    if (!mounted) return;
    setState(() => _dragPosition = 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      final double maxWidth = constraints.maxWidth;
      final double buttonHeight = 56.0;
      final double iconSize = 44.0;
      final double padding = 4.0;
      final double maxDragDistance = maxWidth - iconSize - (padding * 2);
      final double threshold = maxDragDistance * 0.85;
      final double clampedPosition = _dragPosition.clamp(0.0, maxDragDistance);
      return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            setState(() => _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDragDistance));
          },
          onHorizontalDragEnd: (_) {
            if (_dragPosition >= threshold) {
              setState(() => _dragPosition = maxDragDistance);
              widget.onConfirm();
            } else {
              setState(() => _dragPosition = 0.0);
            }
          },
          child: Container(
              height: buttonHeight,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3), width: 1.5)),
              child: Stack(clipBehavior: Clip.none, children: <Widget>[
                Positioned.fill(child: Center(child: Text(widget.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _validateOrderPrimaryColor, letterSpacing: 0.5)))),
                AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    left: padding + clampedPosition,
                    top: padding,
                    child: GestureDetector(
                        onTap: () {
                          if (_dragPosition < threshold) {
                            setState(() => _dragPosition = maxDragDistance);
                            Future<void>.delayed(const Duration(milliseconds: 300), () {
                              if (!mounted) return;
                              widget.onConfirm();
                            });
                          }
                        },
                        child: Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(color: _validateOrderPrimaryColor, shape: BoxShape.circle, boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]),
                            child: const Icon(Icons.arrow_forward_ios_outlined, color: Colors.white, size: 24))))
              ])));
    });
  }
}

class ValidateOrderConfirmationDialog extends StatelessWidget {
  const ValidateOrderConfirmationDialog(
      {super.key,
      required this.title,
      required this.message,
      required this.totalLabel,
      required this.totalValue,
      required this.paymentLabel,
      required this.paymentValue,
      required this.deliveryTimeLabel,
      required this.deliveryTimeValue,
      required this.cancelLabel,
      required this.confirmLabel,
      required this.onCancel,
      required this.onConfirm});
  final String title;
  final String message;
  final String totalLabel;
  final String totalValue;
  final String paymentLabel;
  final String paymentValue;
  final String deliveryTimeLabel;
  final String deliveryTimeValue;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: <Widget>[
          Container(
              padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _validateOrderPrimaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.check_circle_outline, color: _validateOrderPrimaryColor, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18)))
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(message, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
              child: Column(children: <Widget>[
                OrderSummaryRow(label: totalLabel, value: totalValue),
                const Divider(height: 16),
                OrderSummaryRow(label: paymentLabel, value: paymentValue),
                const Divider(height: 16),
                OrderSummaryRow(label: deliveryTimeLabel, value: deliveryTimeValue)
              ]))
        ]),
        actions: <Widget>[
          TextButton(onPressed: onCancel, child: Text(cancelLabel, style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(backgroundColor: _validateOrderPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)))
        ]);
  }
}

class OrderSummaryRow extends StatelessWidget {
  const OrderSummaryRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
      Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    ]);
  }
}

class OrderInformationData {
  const OrderInformationData({required this.icon, required this.title, required this.subtitle, this.isTotal = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isTotal;
}

class ValidateOrderItemData {
  const ValidateOrderItemData({required this.name, required this.quantity, this.price});
  final String name;
  final int quantity;
  final String? price;

  factory ValidateOrderItemData.fromMap(Map<String, dynamic> map) {
    final dynamic rawQuantity = map['quantity'];
    final dynamic rawPrice = map['price'];
    final int parsedQuantity = rawQuantity is int ? rawQuantity : int.tryParse('$rawQuantity') ?? 0;
    return ValidateOrderItemData(name: '${map['name']}', quantity: parsedQuantity, price: rawPrice?.toString());
  }
}
