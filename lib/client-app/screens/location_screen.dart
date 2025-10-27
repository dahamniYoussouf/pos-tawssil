import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'permission_screen.dart';
import 'sharing_screen.dart';
import 'gps_disabled_popup.dart';
import 'restaurant_suggestion_page.dart';
import '../blocs/location/location_cubit.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  int currentScreen = 0;



  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LocationCubit(),
      child: BlocListener<LocationCubit, LocationState>(
        listener: (context, state) {
          if (state is LocationPermissionGranted) {
            setState(() => currentScreen = 1);
          } else if (state is LocationPermissionDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is LocationSuccess) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => RestaurantSuggestionPage()),
              (route) => false,
            );
          } else if (state is LocationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          body: _buildCurrentScreen(),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (currentScreen) {
      case 0:
        return PermissionScreen(
          onAuthorized: () {
            context.read<LocationCubit>().requestLocationPermission();
          },
          onDenied: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Vous avez refusé l\'autorisation. Activez la localisation dans les paramètres.'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
      case 1:
        return BlocBuilder<LocationCubit, LocationState>(
          builder: (context, state) {
            return SharingScreen(
              onShareLocation: () => _handleShareGpsLocation(context),
              onAddAddress: _showAddressDialog,
              onGpsDisabled: _showGpsDisabledPopup,
            );
          },
        );
      default:
        return PermissionScreen(
          onAuthorized: () {
            context.read<LocationCubit>().requestLocationPermission();
          },
          onDenied: () {},
        );
    }
  }

  void _showAddressDialog() {
  final TextEditingController addressController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006C4A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF006C4A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Entrer une adresse',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E2E2E),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Address input field
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE9ECEF),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: addressController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2E2E2E),
                ),
                decoration: const InputDecoration(
                  hintText: 'Ex: 123 Rue de la République, Alger',
                  hintStyle: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.home,
                    color: Color(0xFF9E9E9E),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.pop(dialogContext);
                    _handleAddManualAddress(value.trim());
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        color: Color(0xFF6C757D),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final value = addressController.text.trim();
                      if (value.isNotEmpty) {
                        Navigator.pop(dialogContext);
                        _handleAddManualAddress(value);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006C4A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirmer',
                      style: TextStyle(
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
    ),
  );
}

  void _handleAddManualAddress(String address) {
    context.read<LocationCubit>().setManualAddress(address);
  }

  void _handleShareGpsLocation(BuildContext context) {
    FocusScope.of(context).unfocus();
    context.read<LocationCubit>().getCurrentLocation();
  }



  void _showGpsDisabledPopup() {
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocBuilder<LocationCubit, LocationState>(
        builder: (context, state) {
          return GpsDisabledPopup(
            onRetry: () {
              Navigator.of(context).pop();
              context.read<LocationCubit>().getCurrentLocation();
            },
          );
        },
      ),
    );
  }
}