import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/location_selection_cubit.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/location_selection_state.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/map_location_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSelectionPage extends StatefulWidget {
  final LatLng initialPosition;

  const LocationSelectionPage({
    super.key,
    required this.initialPosition,
  });

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  GoogleMapController? _mapController;
  late final LocationSelectionCubit _locationSelectionCubit;

  @override
  void initState() {
    super.initState();
    _locationSelectionCubit = LocationSelectionCubit(
      initialPosition: widget.initialPosition,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _locationSelectionCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocProvider.value(
      value: _locationSelectionCubit,
      child: Scaffold(
        backgroundColor: ColorApp.white,
        body: SafeArea(
          child: Column(
            children: [
              _LocationHeader(localizations: localizations),
              Expanded(
                child: Stack(
                  children: [
                    _LocationMap(
                      initialPosition: widget.initialPosition,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      onCameraMove: (position) {
                        _locationSelectionCubit.updatePosition(position.target);
                      },
                      onCameraIdle: () {
                        final state = _locationSelectionCubit.state;
                        if (state is LocationSelectionInitial) {
                          _locationSelectionCubit.selectLocation(
                            state.currentPosition,
                          );
                          _updateLocation(state.currentPosition);
                        }
                      },
                    ),
                    const _LocationPinMarker(),
                  ],
                ),
              ),
              _ConfirmButton(
                localizations: localizations,
                onConfirm: () => _handleConfirm(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateLocation(LatLng position) {
    final mapLocationCubit = context.read<MapLocationCubit>();
    mapLocationCubit.updateLocation(
      position.latitude,
      position.longitude,
    );
  }

  void _handleConfirm(BuildContext context) {
    final state = _locationSelectionCubit.state;
    if (state is LocationSelectionInitial && state.selectedPosition != null) {
      Navigator.of(context).pop(state.selectedPosition);
    }
  }
}

class _LocationHeader extends StatelessWidget {
  final AppLocalizations localizations;

  const _LocationHeader({required this.localizations});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: ColorApp.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: ColorApp.textBlack,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              localizations.location,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorApp.textBlack,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationMap extends StatelessWidget {
  final LatLng initialPosition;
  final Function(GoogleMapController) onMapCreated;
  final Function(CameraPosition) onCameraMove;
  final VoidCallback onCameraIdle;

  const _LocationMap({
    required this.initialPosition,
    required this.onMapCreated,
    required this.onCameraMove,
    required this.onCameraIdle,
  });

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: onMapCreated,
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 15,
      ),
      onCameraMove: onCameraMove,
      onCameraIdle: onCameraIdle,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      zoomControlsEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: false,
    );
  }
}

class _LocationPinMarker extends StatelessWidget {
  const _LocationPinMarker();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on,
              color: ColorApp.primary,
              size: 48,
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: ColorApp.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final AppLocalizations localizations;
  final VoidCallback onConfirm;

  const _ConfirmButton({
    required this.localizations,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationSelectionCubit, LocationSelectionState>(
      builder: (context, state) {
        final isEnabled =
            state is LocationSelectionInitial && state.selectedPosition != null;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorApp.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isEnabled ? onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorApp.primary,
                disabledBackgroundColor: ColorApp.greyBorder,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                localizations.confirm,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ColorApp.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}
