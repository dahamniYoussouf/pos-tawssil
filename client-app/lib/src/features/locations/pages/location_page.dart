import 'package:client_app/src/features/home/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import '../../permissions/pages/permission_page.dart';
import '../../../core/widgets/sharing_screen.dart';
import '../widgets/gps_disabled_popup.dart';
import '../cubit/location_cubit.dart';
import '../cubit/location_state.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationCubit, LocationState>(
      listener: (context, state) {
        if (state is LocationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: ColorApp.redColor,
            ),
          );
        }
      },
      child: BlocBuilder<LocationCubit, LocationState>(
        builder: (context, state) {
          if (state is LocationInitial ||
              state is LocationPermissionRequesting) {
            return PermissionPage(
              onAuthorized: () =>
                  context.read<LocationCubit>().requestLocationPermission(),
              onDenied: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.permissionDenied),
                    backgroundColor: ColorApp.redColor,
                  ),
                );
              },
            );
          } else if (state is LocationPermissionGranted ||
              state is LocationGpsDisabled) {
            if (state is LocationGpsDisabled) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showGpsDisabledPopup(context);
              });
            }
            return SharingScreen(
              onShareLocation: () {
                FocusScope.of(context).unfocus();
                context.read<LocationCubit>().getGpsLocation();
              },
              onAddAddress: () {
                FocusScope.of(context).unfocus();
                _showAddressDialog(context);
              },
              isLoading: state is LocationLoading,
            );
          } else if (state is LocationPermissionDenied) {
            return PermissionPage(
              onAuthorized: () =>
                  context.read<LocationCubit>().requestLocationPermission(),
              onDenied: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.permissionDenied),
                    backgroundColor: ColorApp.redColor,
                  ),
                );
              },
            );
          }
          return SharingScreen(
            onShareLocation: () {
              FocusScope.of(context).unfocus();
              context
                  .read<LocationCubit>()
                  .getGpsLocation()
                  .whenComplete(() => _navigateToHome(context, context));
            },
            onAddAddress: () {
              FocusScope.of(context).unfocus();
              _showAddressDialog(context);
            },
            isLoading: state is LocationLoading,
          );
        },
      ),
    );
  }

  void _showAddressDialog(BuildContext context) {
    final TextEditingController addressController = TextEditingController();
    final BuildContext pageContext = context;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => BlocBuilder<LocationCubit, LocationState>(
        builder: (builderContext, state) {
          final bool isLoading = state is LocationLoading;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorApp.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorApp.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: ColorApp.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(builderContext)!.enterAddress,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ColorApp.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: ColorApp.greyDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ColorApp.greyLight,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: addressController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 16,
                        color: ColorApp.black,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(builderContext)!.addressHint,
                        hintStyle: const TextStyle(
                          color: ColorApp.greyMedium,
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.home,
                          color: ColorApp.greyMedium,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty && !isLoading) {
                          builderContext
                              .read<LocationCubit>()
                              .saveManualAddress(value.trim())
                              .whenComplete(
                                () =>
                                    _navigateToHome(dialogContext, pageContext),
                              );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(builderContext)!.cancel,
                            style: const TextStyle(
                              color: ColorApp.greyMedium,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  final value = addressController.text.trim();
                                  if (value.isNotEmpty) {
                                    builderContext
                                        .read<LocationCubit>()
                                        .saveManualAddress(value)
                                        .whenComplete(
                                          () => _navigateToHome(
                                              dialogContext, pageContext),
                                        );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorApp.primary,
                            foregroundColor: ColorApp.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        ColorApp.white),
                                  ),
                                )
                              : Text(
                                  AppLocalizations.of(builderContext)!.confirm,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToHome(BuildContext dialogContext, BuildContext pageContext) {
    final state = context.read<LocationCubit>().state;
    // check if the state is not LocationSuccess
    if (state is LocationSuccess) {
      Navigator.of(dialogContext).pop();
      Navigator.of(pageContext).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomePage()),
        (route) => false,
      );
    }
  }

  void _showGpsDisabledPopup(BuildContext context) {
    FocusScope.of(context).unfocus();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GpsDisabledPopup(
        onRetry: () async {
          Navigator.of(dialogContext).pop();
          context.read<LocationCubit>().getGpsLocation();
        },
      ),
    );
  }
}
