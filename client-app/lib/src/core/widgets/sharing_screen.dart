import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';

class SharingScreen extends StatelessWidget {
  final VoidCallback onShareLocation;
  final VoidCallback onAddAddress;
  final bool isLoading;

  const SharingScreen({
    Key? key,
    required this.onShareLocation,
    required this.onAddAddress,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: ColorApp.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
              flex: 40,
              child: Container(
                width: double.infinity,
                child: Image.asset(
                  'assets/map_background.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child:
                          const Icon(Icons.map, size: 60, color: Colors.grey),
                    );
                  },
                ),
              )),
          const SizedBox(height: 25),
          Expanded(
              flex: 60,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      l10n.shareLocationTitle,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: ColorApp.black,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.shareLocationDescription,
                      style: TextStyle(
                        fontSize: 16,
                        color: ColorApp.grey,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onShareLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorApp.primary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: ColorApp.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                l10n.shareLocationButton,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: ColorApp.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: isLoading ? null : onAddAddress,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: ColorApp.greyBorder),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.grey,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                l10n.addAddressButton,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: ColorApp.black,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
