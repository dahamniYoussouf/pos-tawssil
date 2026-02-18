import 'package:flutter/material.dart';
import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';

class PermissionScreen extends StatelessWidget {
  final VoidCallback onAuthorized;
  final VoidCallback onDenied;

  const PermissionScreen({
    Key? key,
    required this.onAuthorized,
    required this.onDenied,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
        child: Container(
      color: AppColors.primaryColor,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              margin: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.allowLocation,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.locationPurpose,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  Container(
                    height: 155,
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/permission_map.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.map,
                                size: 60, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Column(
                    children: [
                      _buildPermissionButton(l10n.allowOnce, onAuthorized),
                      _buildPermissionButton(
                          l10n.allowWhenActive, onAuthorized),
                      _buildPermissionButton(l10n.doNotAllow, onDenied,
                          isLast: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildPermissionButton(String text, VoidCallback onPressed,
      {bool isLast = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
          elevation: 0,
          padding: const EdgeInsets.only(left: 10),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.blue,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
