import 'dart:ui';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/extensions/app_localizations_extension.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/src/core/widgets/confirmation_dialog.dart';
import 'package:client_app/src/features/locations/cubit/favorite_address_cubit.dart';
import 'package:client_app/src/features/locations/cubit/favorite_address_state.dart';
import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:client_app/src/features/locations/cubit/location_state.dart';
import 'package:client_app/src/features/locations/models/favorite_address_model.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/address_selection_ui_cubit.dart';
import 'package:client_app/src/features/locations/widgets/create_address_widget.dart';
import 'package:client_app/src/features/locations/widgets/address_popup_menu.dart';
import 'package:client_app/src/features/restaurant/cubit/homepage_cubit.dart';
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
          decoration: BoxDecoration(
            color: ColorApp.white.withOpacity(0.94),
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
                child: BlocBuilder<AddressSelectionUiCubit,
                    AddressSelectionUiState>(
                  builder: (context, uiState) {
                    final searchQuery = uiState is AddressSelectionUiInitial
                        ? uiState.searchQuery.toLowerCase().trim()
                        : '';
                    return BlocConsumer<FavoriteAddressCubit,
                        FavoriteAddressState>(
                      listener: (context, state) {
                        if (state is FavoriteAddressError) {
                          final localizations = AppLocalizations.of(context)!;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations
                                    .translateErrorMessage(state.message),
                              ),
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is FavoriteAddressLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final allAddresses = state is FavoriteAddressLoaded
                            ? state.addresses
                            : <FavoriteAddressModel>[];
                        final filteredAddresses = searchQuery.isEmpty
                            ? allAddresses
                            : allAddresses.where((address) {
                                final nameMatch = address.name
                                    .toLowerCase()
                                    .contains(searchQuery);
                                final addressMatch = address.address
                                    .toLowerCase()
                                    .contains(searchQuery);
                                return nameMatch || addressMatch;
                              }).toList();
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCurrentAddressSection(
                                context,
                                localizations,
                                addresses: filteredAddresses,
                              ),
                            ],
                          ),
                        );
                      },
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
      BuildContext context, String address, double lat, double lng,
      {String? favoriteAddressId}) {
    final locationCubit = context.read<LocationCubit>();
    locationCubit.saveManualAddress(address,
        favoriteAddressId: favoriteAddressId);
    AddressSelectionOverLay.hide();
  }

  void _handleUseCurrentLocation(BuildContext context) async {
    final locationCubit = context.read<LocationCubit>();
    await locationCubit.requestLocationPermission();

    await locationCubit.getGpsLocation();
    // reload nearby restaurants
    await context.read<HomepageCubit>().loadHomepage();
    AddressSelectionOverLay.hide();
  }

  void _showCreateAddressDialog(BuildContext context) {
    AddressSelectionOverLay.hide();
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const CreateAddressWidget(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.transparent,
              ),
            ),
            FadeTransition(
              opacity: animation,
              child: child,
            ),
          ],
        );
      },
    );
  }

  void _handleEditAddress(BuildContext context, FavoriteAddressModel address) {
    AddressSelectionOverLay.hide();
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) =>
          CreateAddressWidget(addressToEdit: address),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.transparent,
              ),
            ),
            FadeTransition(
              opacity: animation,
              child: child,
            ),
          ],
        );
      },
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
              GestureDetector(
                onTap: () => AddressSelectionOverLay.hide(),
                child: SvgPicture.asset(MediaRes.upArrowIcon,
                    height: 10,
                    width: 10,
                    colorFilter: ColorFilter.mode(
                      ColorApp.primary,
                      BlendMode.srcIn,
                    )),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context, AppLocalizations localizations) {
    return _SearchBarWidget(localizations: localizations);
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
          final addressId = locationState.favoriteAddressId ??
              (matchingAddresses.isNotEmpty
                  ? matchingAddresses.first.id
                  : null);
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
                        favoriteAddressId: addressId,
                      );
                    }
                  },
                ),
                _buildSavedAddressesSection(
                    context,
                    localizations,
                    // remove the current address from the list
                    addresses
                        .where((address) => address.id != addressId)
                        .toList()),
              ],
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildSavedAddressesSection(BuildContext context,
      AppLocalizations localizations, List<FavoriteAddressModel> addresses) {
    if (addresses.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
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
        address.iconUrl ?? MediaRes.locationIconAddress,
        height: 20,
        width: 20,
        colorFilter: ColorFilter.mode(
          hideDelete ? ColorApp.primary : ColorApp.textBlack,
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        address.name.isEmpty ? address.address : address.name,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: hideDelete ? ColorApp.primary : ColorApp.textBlack,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: address.id?.isNotEmpty ?? false
          ? AddressPopupMenu(
              onEdit: () => _handleEditAddress(context, address),
              onDelete: () => _handleDeleteAddress(context, address),
              hideDelete: hideDelete,
            )
          : null,
      onTap: onTap ??
          () {
            _handleAddressSelected(
              context,
              address.address,
              address.lat,
              address.lng,
              favoriteAddressId: address.id,
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

class _SearchBarWidget extends StatefulWidget {
  final AppLocalizations localizations;

  const _SearchBarWidget({required this.localizations});

  @override
  State<_SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<_SearchBarWidget> {
  late TextEditingController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddressSelectionUiCubit, AddressSelectionUiState>(
      listener: (context, state) {
        if (state is AddressSelectionUiInitial) {
          if (!_isInitialized || _controller.text != state.searchQuery) {
            _controller.text = state.searchQuery;
            _isInitialized = true;
          }
        }
      },
      child: BlocBuilder<AddressSelectionUiCubit, AddressSelectionUiState>(
        builder: (context, uiState) {
          final searchQuery =
              uiState is AddressSelectionUiInitial ? uiState.searchQuery : '';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: ColorApp.textBlack,
                  ),
              decoration: InputDecoration(
                hintText: widget.localizations.searchForLocation,
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
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          context
                              .read<AddressSelectionUiCubit>()
                              .clearSearchQuery();
                        },
                      )
                    : null,
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
              onChanged: (value) {
                context
                    .read<AddressSelectionUiCubit>()
                    .updateSearchQuery(value);
              },
            ),
          );
        },
      ),
    );
  }
}
