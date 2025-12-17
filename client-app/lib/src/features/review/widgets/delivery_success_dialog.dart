import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/res/color_app.dart';
import '../../../core/res/media_res.dart';

class DeliverySuccessDialog extends StatelessWidget {
  final VoidCallback onOkPressed;

  const DeliverySuccessDialog({
    super.key,
    required this.onOkPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -15,
              right: -15,
              child: IconButton(
                icon: const Icon(Icons.close, color: ColorApp.greyLight),
                onPressed: () => Navigator.of(context).pop(),
                constraints: const BoxConstraints(),
              ),
            ),
            // Title
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  l10n.deliverySuccessful,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ColorApp.black,
                  ),
                ),
                const SizedBox(height: 16),
                // Success image
                Image.asset(
                  MediaRes.successImage,
                  width: 200,
                  height: 180,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),

                // Subtitle
                Text(
                  l10n.enjoyYourMeal,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorApp.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.seeYouNextOrder,
                  style: const TextStyle(
                    fontSize: 14,
                    color: ColorApp.black,
                  ),
                ),
                const SizedBox(height: 24),
                // Ok button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onOkPressed();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorApp.primary,
                      foregroundColor: ColorApp.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      l10n.ok,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, VoidCallback onOkPressed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return DeliverySuccessDialog(onOkPressed: onOkPressed);
      },
    );
  }
}
