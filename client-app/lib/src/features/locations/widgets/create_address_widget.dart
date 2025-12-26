import 'dart:async';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/create_address_ui_cubit.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/map_location_state.dart';
import 'package:client_app/src/features/locations/cubit/favorite_address_cubit.dart';
import 'package:client_app/src/features/locations/cubit/favorite_address_state.dart';
import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:client_app/src/features/locations/cubit/location_state.dart';
import 'package:client_app/src/features/locations/services/google_places_service.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/address_search_cubit.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/address_search_state.dart';
import 'package:client_app/src/features/locations/pages/location_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/map_location_cubit.dart';
import 'package:client_app/src/features/locations/models/favorite_address_model.dart';

class CreateAddressWidget extends StatefulWidget {
  final FavoriteAddressModel? addressToEdit;

  const CreateAddressWidget({this.addressToEdit});

  @override
  State<CreateAddressWidget> createState() => CreateAddressWidgetState();
}

class CreateAddressWidgetState extends State<CreateAddressWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  GoogleMapController? _mapController;
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;
  LatLng? _pendingCameraPosition;

  @override
  void initState() {
    super.initState();
    if (widget.addressToEdit != null) {
      _nameController.text = widget.addressToEdit!.name;
      _searchController.text = widget.addressToEdit!.address;
    }
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
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
    _debounceTimer?.cancel();
    _removeOverlay();
    _mapController?.dispose();
    _nameController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    final query = _searchController.text.trim();

    if (query.length < 2) {
      context.read<AddressSearchCubit>().resetState();
      _removeOverlay();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AddressSearchCubit>().getAutocompleteSuggestions(query);
      }
    });
  }

  void _onFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _removeOverlay();
        }
      });
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showSuggestionsOverlay(List<PlacePrediction> predictions) {
    _removeOverlay();

    if (predictions.isEmpty || !_searchFocusNode.hasFocus) {
      return;
    }

    _overlayEntry = _createOverlayEntry(predictions);
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry(List<PlacePrediction> predictions) {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(16, 0),
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              margin: const EdgeInsets.only(top: 50),
              decoration: BoxDecoration(
                color: ColorApp.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(color: ColorApp.greyBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  itemCount: predictions.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 56,
                    endIndent: 16,
                    color: ColorApp.greyBorder,
                  ),
                  itemBuilder: (context, index) =>
                      _buildSuggestionItem(predictions[index]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(PlacePrediction prediction) {
    return InkWell(
      onTap: () {
        _searchController.text = prediction.description;
        _searchFocusNode.unfocus();
        _removeOverlay();
        context.read<AddressSearchCubit>().selectPlace(prediction);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorApp.greyIconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_on,
                color: ColorApp.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prediction.mainText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorApp.textBlack,
                        ),
                  ),
                  if (prediction.secondaryText.isNotEmpty)
                    Text(
                      prediction.secondaryText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: ColorApp.textBlack,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
              _buildMap(context, uiCubit, mapLocationCubit),
              _buildSearchBar(context),
              _buildAddressForm(context, localizations, uiCubit),
              _buildSaveButton(context, localizations, uiCubit),
              _buildSearchButton(context, localizations, uiCubit),
            ],
          )),
    );
  }

  void _initializeLocation(
    BuildContext context,
    CreateAddressUiCubit uiCubit,
    MapLocationCubit mapLocationCubit,
  ) async {
    if (widget.addressToEdit != null) {
      final address = widget.addressToEdit!;
      final position = LatLng(address.lat, address.lng);
      uiCubit.updatePositionAndAddress(
        position: position,
        address: address.address,
        lat: address.lat,
        lng: address.lng,
        isDefault: address.isDefault,
      );
      mapLocationCubit.updateLocation(address.lat, address.lng);
      _pendingCameraPosition = position;
      if (_mapController != null) {
        _updateCameraPosition(position);
      }
      return;
    }
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
      _pendingCameraPosition = position;
      if (_mapController != null) {
        _updateCameraPosition(position);
        _pendingCameraPosition = null;
      }
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
      _pendingCameraPosition = latLng;
      if (_mapController != null) {
        _updateCameraPosition(latLng);
        _pendingCameraPosition = null;
      }
    } catch (e) {
      // Handle error
    }
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return _CreateAddressHeader(
      localizations: localizations,
      isEditMode: widget.addressToEdit != null,
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
          _removeOverlay();
        } else if (state is AddressSearchSuggestions) {
          _showSuggestionsOverlay(state.predictions);
        } else if (state is AddressSearchError) {
          _removeOverlay();
        }
      },
      builder: (context, state) {
        final localizations = AppLocalizations.of(context)!;
        return CompositedTransformTarget(
          link: _layerLink,
          child: Container(
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
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: localizations.searchForLocation,
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12),
                  child: SvgPicture.asset(MediaRes.searchIcon,
                      height: 20,
                      width: 20,
                      colorFilter: ColorFilter.mode(
                          ColorApp.textBlack, BlendMode.srcIn)),
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
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                size: 20, color: ColorApp.greyIconColor),
                            onPressed: () {
                              _searchController.clear();
                              context.read<AddressSearchCubit>().resetState();
                              _removeOverlay();
                            },
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
    return BlocListener<MapLocationCubit, MapLocationState>(
      listener: (context, mapState) {
        if (mapState is MapLocationSuccess) {
          _searchController.text = mapState.address;
          uiCubit.updateSelectedAddress(
            address: mapState.address,
            lat: mapState.latitude,
            lng: mapState.longitude,
          );
        }
      },
      child: BlocListener<CreateAddressUiCubit, CreateAddressUiState>(
        listener: (context, uiState) {
          if (uiState is CreateAddressUiInitial &&
              _mapController != null &&
              _pendingCameraPosition != null) {
            _updateCameraPosition(_pendingCameraPosition!);
            _pendingCameraPosition = null;
          }
        },
        child: BlocBuilder<CreateAddressUiCubit, CreateAddressUiState>(
          builder: (context, uiState) {
            if (uiState is CreateAddressUiInitial) {
              return GestureDetector(
                  onTap: () => _navigateToLocationSelection(
                        context,
                        uiState.currentPosition,
                        uiCubit,
                        mapLocationCubit,
                      ),
                  child: Container(
                    height: 220,
                    margin: const EdgeInsets.only(
                        left: 16, right: 16, bottom: 8, top: 8),
                    decoration: BoxDecoration(
                      color: ColorApp.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          GestureDetector(
                              onTap: () => _navigateToLocationSelection(
                                    context,
                                    uiState.currentPosition,
                                    uiCubit,
                                    mapLocationCubit,
                                  ),
                              child: GoogleMap(
                                onMapCreated: (controller) {
                                  _mapController = controller;
                                  if (_pendingCameraPosition != null) {
                                    _updateCameraPosition(
                                        _pendingCameraPosition!);
                                    _pendingCameraPosition = null;
                                  }
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
                                myLocationEnabled: false,
                                myLocationButtonEnabled: false,
                                mapType: MapType.normal,
                                zoomControlsEnabled: false,
                                compassEnabled: false,
                                mapToolbarEnabled: false,
                              )),
                          IgnorePointer(
                            child: _buildMapMarker(),
                          ),
                          Positioned(
                            top: 5,
                            right: 10,
                            child: IconButton(
                                onPressed: () => _navigateToLocationSelection(
                                      context,
                                      uiState.currentPosition,
                                      uiCubit,
                                      mapLocationCubit,
                                    ),
                                icon: Icon(
                                  Icons.map_outlined,
                                  color: ColorApp.primary,
                                )),
                          )
                        ],
                      ),
                    ),
                  ));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Future<void> _navigateToLocationSelection(
    BuildContext context,
    LatLng currentPosition,
    CreateAddressUiCubit uiCubit,
    MapLocationCubit mapLocationCubit,
  ) async {
    final selectedPosition = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSelectionPage(
          initialPosition: currentPosition,
        ),
      ),
    );

    if (selectedPosition != null && mounted) {
      uiCubit.updatePosition(selectedPosition);
      await mapLocationCubit.updateLocation(
        selectedPosition.latitude,
        selectedPosition.longitude,
      );

      // Update address when location is fetched
      final mapState = mapLocationCubit.state;
      if (mapState is MapLocationSuccess) {
        uiCubit.updateSelectedAddress(
          address: mapState.address,
          lat: mapState.latitude,
          lng: mapState.longitude,
        );
      }

      _updateCameraPosition(selectedPosition);
    }
  }

  Widget _buildMapMarker() {
    return const _MapMarker();
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
                padding: const EdgeInsets.only(
                    left: 16, right: 16, bottom: 8, top: 8),
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
                              height: 27,
                              width: 27,
                              colorFilter: ColorFilter.mode(
                                  ColorApp.textBlack, BlendMode.srcIn)),
                          SvgPicture.asset(MediaRes.arrowDownIcon,
                              height: 20,
                              width: 20,
                              colorFilter: ColorFilter.mode(
                                  ColorApp.textBlack, BlendMode.srcIn)),
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

  Widget _buildSearchButton(BuildContext context,
      AppLocalizations localizations, CreateAddressUiCubit uiCubit) {
    return BlocConsumer<LocationCubit, LocationState>(
      listener: (context, state) {
        if (state is LocationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is LocationSuccess) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final isLoading = state is LocationLoading;
        return BlocBuilder<CreateAddressUiCubit, CreateAddressUiState>(
          builder: (context, uiState) {
            if (uiState is CreateAddressUiInitial &&
                uiState.selectedLat != null &&
                uiState.selectedLng != null &&
                uiState.selectedAddress.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => _handleAddressSelected(
                              context,
                              uiState.selectedAddress,
                              uiState.selectedLat!,
                              uiState.selectedLng!,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorApp.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: ColorApp.primary),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ColorApp.primary,
                              ),
                            ),
                          )
                        : Text(
                            localizations.searchingFor,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: ColorApp.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
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
                      elevation: 0,
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
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: ColorApp.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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

  void _handleAddressSelected(
      BuildContext context, String address, double lat, double lng,
      {String? favoriteAddressId}) {
    final locationCubit = context.read<LocationCubit>();
    locationCubit.saveManualAddress(address,
        favoriteAddressId: favoriteAddressId);
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
    if (widget.addressToEdit != null && widget.addressToEdit!.id != null) {
      await cubit.updateFavoriteAddress(
        id: widget.addressToEdit!.id!,
        name: name,
        address: uiState.selectedAddress,
        lat: uiState.selectedLat!,
        lng: uiState.selectedLng!,
        isDefault: uiState.isDefault,
      );
    } else {
      await cubit.createFavoriteAddress(
        name: name,
        address: uiState.selectedAddress,
        lat: uiState.selectedLat!,
        lng: uiState.selectedLng!,
        isDefault: uiState.isDefault,
      );
    }
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

class _CreateAddressHeader extends StatelessWidget {
  final AppLocalizations localizations;
  final bool isEditMode;

  const _CreateAddressHeader({
    required this.localizations,
    required this.isEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isEditMode
                ? localizations.editAddressTitle
                : localizations.addNewAddressTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ColorApp.textBlack,
                ),
          ),
        ],
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker();

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
