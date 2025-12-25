import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/src/core/widgets/confirmation_dialog.dart';
import 'package:client_app/src/features/locations/cubit/favorite_address_cubit.dart';
import 'package:client_app/src/features/locations/cubit/favorite_address_state.dart';
import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:client_app/src/features/locations/cubit/location_state.dart';
import 'package:client_app/src/features/locations/models/favorite_address_model.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/address_search_cubit.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/address_search_state.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/address_selection_ui_cubit.dart';
import 'package:client_app/src/features/locations/widgets/create_address_widget.dart';
import 'package:client_app/src/features/locations/widgets/address_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class AddressSelectionOverLay {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, GlobalKey locationKey) {
    if (_overlayEntry != null) {
      return;
    }
    final overlay = Overlay.of(context);
    final renderBox =
        locationKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) {
      return;
    }
    final position = renderBox.localToGlobal(Offset.zero);
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => hide(),
              child: Container(
                color: Colors.black54,
              ),
            ),
          ),
          BlocProvider(
            create: (context) => AddressSelectionUiCubit(),
            child: _AddressSelectionOverlayContent(
              topPosition: position.dy,
            ),
          ),
        ],
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _AddressSelectionOverlayContent extends StatelessWidget {
  final double topPosition;

  const _AddressSelectionOverlayContent({
    required this.topPosition,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final horizontalPadding = 20.0;
    return Positioned(
      top: topPosition,
      left: horizontalPadding,
      right: horizontalPadding,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(right: 50),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          decoration: const BoxDecoration(
            color: ColorApp.white,
            borderRadius: BorderRadius.all(Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, localizations),
              const SizedBox(height: 4),
              _buildSearchBar(context, localizations),
              const SizedBox(height: 4),
              Flexible(
                child: BlocConsumer<FavoriteAddressCubit, FavoriteAddressState>(
                  listener: (context, state) {
                    if (state is FavoriteAddressError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message)),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is FavoriteAddressLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCurrentAddressSection(context, localizations,
                              addresses: state is FavoriteAddressLoaded
                                  ? state.addresses
                                  : []),
                          _buildSavedAddressesSection(
                              context,
                              localizations,
                              state is FavoriteAddressLoaded
                                  ? state.addresses
                                  : []),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _buildActionButtons(context, localizations),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAddressSelected(
      BuildContext context, String address, double lat, double lng) {
    final locationCubit = context.read<LocationCubit>();
    locationCubit.saveManualAddress(address);
    AddressSelectionOverLay.hide();
  }

  void _handleUseCurrentLocation(BuildContext context) async {
    final locationCubit = context.read<LocationCubit>();
    await locationCubit.requestLocationPermission();
    await locationCubit.getGpsLocation();
    AddressSelectionOverLay.hide();
  }

  void _showCreateAddressDialog(BuildContext context) {
    AddressSelectionOverLay.hide();
    showDialog(
      context: context,
      builder: (context) => const CreateAddressWidget(),
    );
  }

  void _handleEditAddress(BuildContext context, FavoriteAddressModel address) {
    AddressSelectionOverLay.hide();
    showDialog(
      context: context,
      builder: (context) => CreateAddressWidget(addressToEdit: address),
    );
  }

  void _handleDeleteAddress(
      BuildContext context, FavoriteAddressModel address) {
    final localizations = AppLocalizations.of(context)!;
    if (address.id == null) {
      return;
    }
    final favoriteAddressCubit = context.read<FavoriteAddressCubit>();
    final addressId = address.id!;
    AddressSelectionOverLay.hide();
    ConfirmationDialog.show(
      context,
      ConfirmationDialogData(
        title: localizations.delete,
        content: localizations.deleteAddressConfirmation,
        confirmText: localizations.delete,
        cancelText: localizations.cancel,
        confirmButtonColor: ColorApp.redColorLight,
        confirmTextColor: ColorApp.white,
        onConfirm: () {
          favoriteAddressCubit.deleteFavoriteAddress(addressId);
        },
      ),
      useRootNavigator: true,
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations localizations) {
    return BlocBuilder<AddressSelectionUiCubit, AddressSelectionUiState>(
      builder: (context, uiState) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.changeLocation,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ColorApp.textBlack,
                    ),
              ),
              SvgPicture.asset(MediaRes.upArrowIcon,
                  height: 10,
                  width: 10,
                  colorFilter: ColorFilter.mode(
                    ColorApp.primary,
                    BlendMode.srcIn,
                  ))
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, AppLocalizations localizations) {
    return BlocProvider(
      create: (context) => AddressSearchCubit(),
      child: BlocConsumer<AddressSearchCubit, AddressSearchState>(
        listener: (context, state) {
          if (state is AddressSearchSuccess) {
            _handleAddressSelected(
                context, state.address, state.latitude, state.longitude);
          } else if (state is AddressSearchError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: ColorApp.textBlack,
                  ),
              decoration: InputDecoration(
                hintText: localizations.searchForLocation,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    MediaRes.searchIcon,
                    height: 12,
                    width: 12,
                    colorFilter: ColorFilter.mode(
                      ColorApp.greyIconColor,
                      BlendMode.srcIn,
                    ),
                  ),
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
                  borderSide: BorderSide(color: ColorApp.primary),
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  context.read<AddressSearchCubit>().searchAddress(value);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentAddressSection(
      BuildContext context, AppLocalizations localizations,
      {List<FavoriteAddressModel> addresses = const []}) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, locationState) {
        if (locationState is LocationSuccess) {
          final matchingAddresses = addresses
              .where((address) =>
                  address.lat == locationState.latitude &&
                  address.lng == locationState.longitude)
              .toList();
          final addressId = matchingAddresses.isNotEmpty
              ? matchingAddresses.first.id ?? ''
              : '';
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.currentAddress,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorApp.textBlack,
                  ),
                ),
                const SizedBox(height: 8),
                _buildAddressItem(
                  context,
                  FavoriteAddressModel(
                    id: addressId,
                    name: locationState.fullAddress,
                    address: locationState.fullAddress,
                    lat: locationState.latitude!,
                    lng: locationState.longitude!,
                    isDefault: false,
                  ),
                  hideDelete: true,
                  onTap: () {
                    if (locationState.latitude != null &&
                        locationState.longitude != null) {
                      _handleAddressSelected(
                        context,
                        locationState.fullAddress,
                        locationState.latitude!,
                        locationState.longitude!,
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSavedAddressesSection(BuildContext context,
      AppLocalizations localizations, List<FavoriteAddressModel> addresses) {
    if (addresses.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.savedAddresses,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorApp.textBlack,
                ),
          ),
          const SizedBox(height: 8),
          ...addresses.map((address) => _buildAddressItem(context, address)),
        ],
      ),
    );
  }

  Widget _buildAddressItem(BuildContext context, FavoriteAddressModel address,
      {VoidCallback? onTap, bool hideDelete = false}) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 0,
      visualDensity: VisualDensity.compact,
      leading: SvgPicture.asset(
        MediaRes.locationIcon,
        height: 20,
        width: 20,
      ),
      title: Text(
        address.name,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: ColorApp.textBlack,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: AddressPopupMenu(
        onEdit: () => _handleEditAddress(context, address),
        onDelete: () => _handleDeleteAddress(context, address),
        hideDelete: hideDelete,
      ),
      onTap: onTap ??
          () {
            _handleAddressSelected(
              context,
              address.address,
              address.lat,
              address.lng,
            );
          },
    );
  }

  Widget _buildActionButtons(
      BuildContext context, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showCreateAddressDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorApp.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                localizations.addNewAddress,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ColorApp.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleUseCurrentLocation(context),
              icon: Image.asset(
                MediaRes.locationImage,
                height: 18,
                width: 18,
              ),
              label: Text(
                localizations.useCurrentLocation,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ColorApp.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ColorApp.primary, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
