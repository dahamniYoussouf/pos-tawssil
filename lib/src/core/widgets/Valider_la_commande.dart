import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:frontend/l10n/app_localizations.dart';
// Remove: import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class ValiderLaCommandePage extends StatefulWidget {
  final String deliveryAddress;
  final String estimatedTime;
  final String orderNumber;
  final double totalPrice;
  final String paymentMethod;
  final List<Map<String, dynamic>> orderItems;
  final LatLng? pickupLocation;
  final LatLng? deliveryLocation;
  final String? restaurantName;

  const ValiderLaCommandePage({
    Key? key,
    required this.deliveryAddress,
    required this.estimatedTime,
    required this.orderNumber,
    required this.totalPrice,
    required this.paymentMethod,
    required this.orderItems,
    this.pickupLocation,
    this.deliveryLocation,
    this.restaurantName,
  }) : super(key: key);

  @override
  State<ValiderLaCommandePage> createState() => _ValiderLaCommandePageState();
}

class _ValiderLaCommandePageState extends State<ValiderLaCommandePage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = false;
  late LatLng _pickupLatLng;
  late LatLng _deliveryLatLng;

  @override
  void initState() {
    super.initState();
    _initializeLocations();
    _initializeMarkers();
    _drawRoute();
  }

  void _initializeLocations() {
    _pickupLatLng = widget.pickupLocation ?? const LatLng(36.7538, 3.0588);
    _deliveryLatLng = widget.deliveryLocation ?? const LatLng(36.7738, 3.0888);
  }

  void _initializeMarkers() {
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: widget.restaurantName ?? 'Point de récupération',
          snippet: 'Restaurant',
        ),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('delivery'),
        position: _deliveryLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: widget.deliveryAddress,
        ),
      ),
    );
  }

  void _drawRoute() {
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_pickupLatLng, _deliveryLatLng],
        color: const Color(0xFF00695C),
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );
  }

  void _fitMarkersInBounds() {
    if (_mapController == null) return;

    final double minLat = _pickupLatLng.latitude < _deliveryLatLng.latitude ? _pickupLatLng.latitude : _deliveryLatLng.latitude;
    final double maxLat = _pickupLatLng.latitude > _deliveryLatLng.latitude ? _pickupLatLng.latitude : _deliveryLatLng.latitude;
    final double minLng = _pickupLatLng.longitude < _deliveryLatLng.longitude ? _pickupLatLng.longitude : _deliveryLatLng.longitude;
    final double maxLng = _pickupLatLng.longitude > _deliveryLatLng.longitude ? _pickupLatLng.longitude : _deliveryLatLng.longitude;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.validateOrder,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildMapSection(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        title: AppLocalizations.of(context)!.deliveryAddressLabel,
                        subtitle: widget.deliveryAddress,
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        icon: Icons.access_time,
                        title: AppLocalizations.of(context)!.deliveryTime,
                        subtitle: widget.estimatedTime,
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        icon: Icons.receipt_outlined,
                        title: AppLocalizations.of(context)!.orderNumber,
                        subtitle: widget.orderNumber,
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        icon: Icons.payments_outlined,
                        title: AppLocalizations.of(context)!.totalLabel,
                        subtitle: AppLocalizations.of(context)!.totalValue(widget.totalPrice.toStringAsFixed(2)),
                        isTotal: true,
                      ),
                      _buildDivider(),
                      _buildInfoRow(
                        icon: Icons.credit_card,
                        title: AppLocalizations.of(context)!.paymentMethodLabel,
                        subtitle: widget.paymentMethod,
                      ),
                      _buildDivider(),
                      _buildOrderItemsSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildValidateButton(),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00695C)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 250,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  (_pickupLatLng.latitude + _deliveryLatLng.latitude) / 2,
                  (_pickupLatLng.longitude + _deliveryLatLng.longitude) / 2,
                ),
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {
                _mapController = controller;
                Future.delayed(const Duration(milliseconds: 500), () {
                  _fitMarkersInBounds();
                });
              },
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFF00695C),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.estimatedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00695C),
                      ),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isTotal ? const Color(0xFF00695C).withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isTotal ? const Color(0xFF00695C) : Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isTotal ? const Color(0xFF00695C) : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isTotal ? 16 : 13,
                    fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
                    color: isTotal ? const Color(0xFF00695C) : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant_menu, size: 20, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.orderDetailsLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: widget.orderItems.asMap().entries.map((entry) {
                      final item = entry.value;
                      final isLast = entry.key == widget.orderItems.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item['quantity']}x ${item['name']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (item['price'] != null)
                              Text(
                                '${item['price']} DA',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[200], height: 1);
  }

  Widget _buildValidateButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _validateOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00695C),
              disabledBackgroundColor: Colors.grey[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.validate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _validateOrder() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF00695C),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.confirmOrder,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.confirmOrderMessage,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(AppLocalizations.of(context)!.totalLabel, AppLocalizations.of(context)!.totalValue(widget.totalPrice.toStringAsFixed(2))),
                  const Divider(height: 16),
                  _buildSummaryRow(AppLocalizations.of(context)!.payment, widget.paymentMethod),
                  const Divider(height: 16),
                  _buildSummaryRow(AppLocalizations.of(context)!.deliveryTime, widget.estimatedTime),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitOrder();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00695C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              AppLocalizations.of(context)!.confirm,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _submitOrder() async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.orderValidatedSuccessfully,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.verificationError} ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
