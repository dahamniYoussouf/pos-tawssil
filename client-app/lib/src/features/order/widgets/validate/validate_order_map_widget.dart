import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ValidateOrderMapCard extends StatefulWidget {
  const ValidateOrderMapCard(
      {super.key,
      required this.pickupLatLng,
      required this.deliveryLatLng,
      required this.markers,
      required this.polylines,
      required this.onMapCreated,
      required this.estimatedTime,
      this.height = 200,
      this.borderRadius = 16});
  final LatLng pickupLatLng;
  final LatLng deliveryLatLng;
  final List<Marker> markers;
  final List<Polyline> polylines;
  final ValueChanged<MapController> onMapCreated;
  final String estimatedTime;
  final double height;
  final double borderRadius;

  @override
  State<ValidateOrderMapCard> createState() => _ValidateOrderMapCardState();
}

class _ValidateOrderMapCardState extends State<ValidateOrderMapCard> {
  late final MapController _mapController;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isMapReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _isMapReady = true;
          widget.onMapCreated(_mapController);
          _fitBounds();
        }
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fitBounds() {
    final LatLngBounds bounds = LatLngBounds.fromPoints(
      <LatLng>[widget.pickupLatLng, widget.deliveryLatLng],
    );
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = LatLng(
        (widget.pickupLatLng.latitude + widget.deliveryLatLng.latitude) / 2,
        (widget.pickupLatLng.longitude + widget.deliveryLatLng.longitude) / 2);
    return SizedBox(
        height: widget.height,
        child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 12,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.flingAnimation |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: <Widget>[
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.tawsil.delivery',
                  ),
                  if (widget.polylines.isNotEmpty)
                    PolylineLayer(
                      polylines: widget.polylines,
                    ),
                  if (widget.markers.isNotEmpty)
                    MarkerLayer(
                      markers: widget.markers,
                    ),
                ])));
  }
}
