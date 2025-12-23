import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/src/features/locations/cubit/favorite_address_cubit.dart';
import 'package:client_app/src/features/locations/cubit/favorite_address_state.dart';
import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:client_app/src/features/locations/cubit/location_state.dart';
import 'package:client_app/src/features/restaurant/widgets/cubit/address_search_cubit.dart';
import 'package:client_app/src/features/restaurant/widgets/cubit/address_search_state.dart';
import 'package:client_app/src/features/restaurant/widgets/cubit/create_address_ui_cubit.dart';
import 'package:client_app/src/features/restaurant/widgets/cubit/map_location_cubit.dart';
import 'package:client_app/src/features/restaurant/widgets/cubit/map_location_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CreateAddressWidget extends StatefulWidget {
  const CreateAddressWidget();

  @override
  State<CreateAddressWidget> createState() => CreateAddressWidgetState();
}

class CreateAddressWidgetState extends State<CreateAddressWidget> {
  final TextEditingController _nameController = TextEditingController();
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final uiCubit = context.read<CreateAddressUiCubit>();
        final mapLocationCubit = context.read<MapLocationCubit>();
        _initializeLocation(context, uiCubit, mapLocationCubit);
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final uiCubit = context.read<CreateAddressUiCubit>();
    final mapLocationCubit = context.read<MapLocationCubit>();
    return Dialog(
      backgroundColor: ColorApp.white,
      child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(localizations),
              SizedBox(
                height: 220,
                child: Stack(
                  children: [
                    _buildMap(context, uiCubit, mapLocationCubit),
                    _buildMapMarker(),
                  ],
                ),
              ),
              _buildSearchBar(context),
              _buildAddressForm(context, localizations, uiCubit),
              _buildSaveButton(context, localizations, uiCubit),
            ],
          )),
    );
  }

  void _initializeLocation(
    BuildContext context,
    CreateAddressUiCubit uiCubit,
    MapLocationCubit mapLocationCubit,
  ) async {
    final locationCubit = context.read<LocationCubit>();
    final locationState = locationCubit.state;
    if (locationState is LocationSuccess &&
        locationState.latitude != null &&
        locationState.longitude != null) {
      final position = LatLng(
        locationState.latitude!,
        locationState.longitude!,
      );
      uiCubit.updatePositionAndAddress(
        position: position,
        address: locationState.fullAddress,
        lat: locationState.latitude!,
        lng: locationState.longitude!,
      );
      mapLocationCubit.updateLocation(
        locationState.latitude!,
        locationState.longitude!,
      );
      _updateCameraPosition(position);
    } else {
      await _getCurrentLocation(context, uiCubit, mapLocationCubit);
    }
  }

  Future<void> _getCurrentLocation(
    BuildContext context,
    CreateAddressUiCubit uiCubit,
    MapLocationCubit mapLocationCubit,
  ) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      uiCubit.updatePosition(latLng);
      mapLocationCubit.updateLocation(position.latitude, position.longitude);
      _updateCameraPosition(latLng);
    } catch (e) {
      // Handle error
    }
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            localizations.addNewAddressTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorApp.textBlack,
                ),
          ),
          GestureDetector(
            child: const Icon(Icons.close, color: ColorApp.textGrey),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return BlocConsumer<AddressSearchCubit, AddressSearchState>(
      listener: (context, state) {
        if (state is AddressSearchSuccess) {
          final uiCubit = context.read<CreateAddressUiCubit>();
          final mapLocationCubit = context.read<MapLocationCubit>();
          final position = LatLng(state.latitude, state.longitude);
          uiCubit.updatePositionAndAddress(
            position: position,
            address: state.address,
            lat: state.latitude,
            lng: state.longitude,
          );
          mapLocationCubit.updateLocation(state.latitude, state.longitude);
          _updateCameraPosition(position);
        } else if (state is AddressSearchError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final localizations = AppLocalizations.of(context)!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: localizations.searchForLocation,
              prefixIcon: Padding(
                padding: EdgeInsets.all(12),
                child: SvgPicture.asset(MediaRes.searchIcon,
                    height: 20,
                    width: 20,
                    colorFilter: ColorFilter.mode(
                        ColorApp.greyIconColor, BlendMode.srcIn)),
              ),
              filled: true,
              fillColor: ColorApp.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorApp.greyBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorApp.greyBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ColorApp.greyBorder),
              ),
              suffixIcon: state is AddressSearchLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ColorApp.textBlack,
                ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                context.read<AddressSearchCubit>().searchAddress(value);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildMap(
    BuildContext context,
    CreateAddressUiCubit uiCubit,
    MapLocationCubit mapLocationCubit,
  ) {
    return BlocBuilder<CreateAddressUiCubit, CreateAddressUiState>(
      builder: (context, uiState) {
        if (uiState is CreateAddressUiInitial) {
          return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorApp.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: uiState.currentPosition,
                    zoom: 15,
                  ),
                  onCameraMove: (position) {
                    uiCubit.updatePosition(position.target);
                  },
                  onCameraIdle: () {
                    final currentState = uiCubit.state;
                    if (currentState is CreateAddressUiInitial) {
                      mapLocationCubit.updateLocation(
                        currentState.currentPosition.latitude,
                        currentState.currentPosition.longitude,
                      );
                    }
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMapMarker() {
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

  Widget _buildAddressForm(
    BuildContext context,
    AppLocalizations localizations,
    CreateAddressUiCubit uiCubit,
  ) {
    return BlocBuilder<MapLocationCubit, MapLocationState>(
      builder: (context, state) {
        return BlocBuilder<CreateAddressUiCubit, CreateAddressUiState>(
          builder: (context, uiState) {
            if (uiState is CreateAddressUiInitial) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 48,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: ColorApp.white,
                        border: Border.all(color: ColorApp.greyBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(MediaRes.locationIconBlack,
                              height: 27, width: 27),
                          SvgPicture.asset(MediaRes.arrowDownIcon,
                              height: 20, width: 20),
                        ],
                      ),
                    ),
                    Expanded(
                        child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: localizations.addressNameHint,
                        filled: true,
                        fillColor: ColorApp.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: ColorApp.greyBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: ColorApp.greyBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: ColorApp.greyBorder),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ColorApp.textBlack,
                          ),
                    )),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildSaveButton(
    BuildContext context,
    AppLocalizations localizations,
    CreateAddressUiCubit uiCubit,
  ) {
    return BlocConsumer<FavoriteAddressCubit, FavoriteAddressState>(
      listener: (context, state) {
        if (state is FavoriteAddressError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is FavoriteAddressLoading;
        return BlocBuilder<CreateAddressUiCubit, CreateAddressUiState>(
          builder: (context, uiState) {
            if (uiState is CreateAddressUiInitial) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => _saveAddress(
                              context,
                              _nameController.text.trim(),
                              uiState,
                              localizations,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorApp.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ColorApp.white,
                              ),
                            ),
                          )
                        : Text(
                            localizations.saveAddress,
                            style: const TextStyle(
                              color: ColorApp.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Future<void> _saveAddress(
    BuildContext context,
    String name,
    CreateAddressUiInitial uiState,
    AppLocalizations localizations,
  ) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseEnterAddressName)),
      );
      return;
    }
    if (uiState.selectedLat == null || uiState.selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.pleaseSelectLocation)),
      );
      return;
    }
    final cubit = context.read<FavoriteAddressCubit>();
    await cubit.createFavoriteAddress(
      name: name,
      address: uiState.selectedAddress,
      lat: uiState.selectedLat!,
      lng: uiState.selectedLng!,
      isDefault: uiState.isDefault,
    );
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _updateCameraPosition(LatLng position) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15),
      );
    }
  }
}
