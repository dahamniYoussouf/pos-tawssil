import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'permission_screen.dart';
import 'sharing_screen.dart';
import 'gps_disabled_popup.dart';
import 'restaurant_suggestion_page.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class LocationScreen extends StatefulWidget {
  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  int currentScreen = 0;
  final UserService _userService = UserService();
  bool _isProcessing = false;

  static const String _locationAreaKey = 'location_area';
  static const String _locationCityKey = 'location_city';
  static const String _locationLatitudeKey = 'location_latitude';
  static const String _locationLongitudeKey = 'location_longitude';
  static const String _locationFullAddressKey = 'location_full_address';

  Future<bool> setCurrentLocationLongitude(String longitude) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lngSuccess =
          await prefs.setString(_locationLongitudeKey, longitude);
      print('Longitude saved: $longitude');
      return lngSuccess;
    } catch (e) {
      print('Error setting longitude: $e');
      return false;
    }
  }

  Future<bool> setFullAddress(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('location_full_address', address);
    } catch (e) {
      print('Error saving full address: $e');
      return false;
    }
  }

  Future<String?> getFullAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_locationFullAddressKey);
    } catch (e) {
      print('Error getting full address: $e');
      return null;
    }
  }

  Future<bool> clearLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_locationAreaKey);
      await prefs.remove(_locationCityKey);
      await prefs.remove(_locationLatitudeKey);
      await prefs.remove(_locationLongitudeKey);
      await prefs.remove(_locationFullAddressKey);
      return true;
    } catch (e) {
      print('Error clearing location: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    switch (currentScreen) {
      case 0:
        return PermissionScreen(
          onAuthorized: () => setState(() => currentScreen = 1),
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
        return SharingScreen(
          onShareLocation: () => handleShareGpsLocation(context),
          onAddAddress: _showAddressDialog,
          onGpsDisabled: _showGpsDisabledPopup,
        );
      default:
        return PermissionScreen(
          onAuthorized: () => setState(() => currentScreen = 1),
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
    _sendManualAddressToServer(address);
  }

  Future<void> handleShareGpsLocation(BuildContext context) async {
    print('🚀 === GPS LOCATION HANDLER STARTED ===');
    if (_isProcessing) {
      print('⏳ Already processing location, please wait...');
      return;
    }
    setState(() {
      _isProcessing = true;
    });
    FocusScope.of(context).unfocus();

    try {
      print('🔍 Checking GPS service...');
      bool gpsOn = await LocationService.isLocationServiceEnabled();
      if (!gpsOn) {
        print('❌ GPS is disabled');
        setState(() {
          _isProcessing = false;
        });
        _showGpsDisabledPopup();
        return;
      }

      print('📍 Getting current GPS position (with timeout)...');
      Position? pos;
      try {
        pos = await LocationService.getCurrentLocation();
      } catch (e) {
        print('⚠️ GPS position retrieval error/timeout: $e');
        setState(() {
          _isProcessing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Impossible de récupérer la localisation GPS (temps écoulé).'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (pos == null) {
        print('❌ Failed to get GPS position (null)');
        setState(() {
          _isProcessing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de récupérer la localisation GPS.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('✅ GPS Coordinates obtained: ${pos.latitude}, ${pos.longitude}');

      String area = '';
      String city = '';
      String fullAddress = '';
      try {
        print('🗺️ Starting reverse geocoding (with timeout)...');
        List<geocoding.Placemark> placemarks = await geocoding
            .placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          area = (place.subLocality ??
                  place.locality ??
                  place.subAdministrativeArea ??
                  '')
              .trim();
          city = (place.administrativeArea ?? place.country ?? '').trim();
          final parts = <String?>[
            place.name,
            place.subLocality,
            place.locality,
            place.subAdministrativeArea,
            place.administrativeArea,
            place.postalCode,
            place.country
          ]
              .where((p) => p != null && p.trim().isNotEmpty)
              .map((p) => p!.trim())
              .toList();
          fullAddress = parts.join(', ');
          if (fullAddress.isEmpty) {
            fullAddress =
                'Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}';
          }
          print(
              '📍 Geocoding result: Area=$area, City=$city, FullAddress=$fullAddress');
        } else {
          fullAddress =
              'Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}';
          area = fullAddress;
          city = '';
          print('⚠️ No placemarks found, using coordinates as fallback');
        }
      } catch (e) {
        print(
            '⚠️ Geocoding error or timeout: $e — using coordinates as fallback');
        fullAddress =
            'Lat: ${pos.latitude.toStringAsFixed(6)}, Lng: ${pos.longitude.toStringAsFixed(6)}';
        area = fullAddress;
        city = '';
      }

      print('💾 Saving numeric coordinates to preferences...');
      await _userService.setCurrentLocationLatitude(pos.latitude.toString());
      await _userService.setCurrentLocationLongitude(pos.longitude.toString());
      await _userService.setCurrentLocationAreaCity(area: area, city: city);
      bool savedFull = await _userService.setFullAddress(fullAddress);
      print('💾 Latitude and Longitude saved');
      print('💾 Area/City saved, FullAddress saved: $savedFull');

      print('🌐 Sending GPS coordinates to server...');
      print(
          '📤 Data being sent: lat=${pos.latitude}, lng=${pos.longitude}, addressFallback=$fullAddress');

      bool success = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          success = await LocationService.sendLocationWithCoordinates(
                  '', pos.latitude, pos.longitude)
              .timeout(const Duration(seconds: 10));
          print('📤 Attempt $attempt: server response success=$success');
          if (success) break;
        } catch (e) {
          print('⚠️ Attempt $attempt send error: $e');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: 2 * attempt));
          }
        }
      }

      setState(() {
        _isProcessing = false;
      });

      if (success) {
        print('✅ GPS location sent successfully!');
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => RestaurantSuggestionPage()),
            (route) => false,
          );
          print('🎉 GPS navigation completed!');
        }
      } else {
        print('❌ GPS location send failed after retries');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Erreur lors de l\'envoi de la localisation. Vérifiez votre connexion.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      print('❌ CRITICAL Error in handleShareGpsLocation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
    print('🏁 === GPS LOCATION HANDLER ENDED ===');
  }

  Future<void> _sendManualAddressToServer(String address) async {
    if (_isProcessing) {
      print('⏳ Already processing, please wait...');
      return;
    }
    setState(() {
      _isProcessing = true;
    });

    try {
      print('📝 Manual address entered: $address');

      List<String> addressParts =
          address.split(',').map((e) => e.trim()).toList();
      String area = addressParts.isNotEmpty ? addressParts[0] : address;
      String city = addressParts.length > 1 ? addressParts[1] : address;
      print('📍 Manual location: Area=$area, City=$city');

      // Try to geocode the manual address to obtain coordinates and save them
      try {
        print('🔍 Attempting to geocode manual address...');
        List<geocoding.Location> locations =
            await geocoding.locationFromAddress(address);
        if (locations.isNotEmpty) {
          final loc = locations.first;
          print(
              '📍 Geocoding successful for manual address: ${loc.latitude}, ${loc.longitude}');
          final latSaved = await _userService
              .setCurrentLocationLatitude(loc.latitude.toString());
          final lngSaved = await _userService
              .setCurrentLocationLongitude(loc.longitude.toString());
        } else {
          print('⚠️ Geocoding returned no locations for manual address');
        }
      } catch (e) {
        print('⚠️ Geocoding failed for manual address: $e');
      }

      // Save area/city using the correct method
      await _userService.setCurrentLocationAreaCity(area: area, city: city);
      print('💾 Location saved to preferences (area/city)');

      bool success = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          success = await LocationService.sendAddressOnly(address)
              .timeout(const Duration(seconds: 10));
          print('📤 sendAddressOnly attempt $attempt => success=$success');
          if (success) break;
        } catch (e) {
          print('⚠️ sendAddressOnly attempt $attempt error: $e');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: 2 * attempt));
          }
        }
      }

      setState(() {
        _isProcessing = false;
      });

      if (success) {
        print('✅ Manual address sent successfully!');
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => RestaurantSuggestionPage()),
            (route) => false,
          );
          print('🎉 Manual address navigation completed!');
        }
      } else {
        print('❌ Manual address failed after retries');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Erreur lors de l\'envoi de l\'adresse. Vérifiez votre connexion.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      print('❌ Error in _sendManualAddressToServer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showGpsDisabledPopup() {
    FocusScope.of(context).unfocus();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GpsDisabledPopup(
        onRetry: () async {
          bool gpsOn = await LocationService.isLocationServiceEnabled();
          if (gpsOn) {
            Navigator.of(context).pop();
            handleShareGpsLocation(context);
          } else {
            print('GPS toujours désactivé');
          }
        },
      ),
    );
  }
}
