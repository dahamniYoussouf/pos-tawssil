import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/core/res/app_theme.dart';
import 'package:flutter/material.dart';

class CancellationReasonModal extends StatelessWidget {
  final Function(String reason, String? otherReason) onConfirm;

  const CancellationReasonModal({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF14336).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF14336),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              localizations.cancelModalTitle,
              style: AppTextStyles.gilmerBold.copyWith(
                fontSize: 20,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localizations.cancelModalSubtitle,
              style: const TextStyle(
                color: AppColors.textMedium,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Confirm Cancellation Button (Red)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  onConfirm('cancelled_by_driver', null);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF14336),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  localizations.confirmCancellation,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Return Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  localizations.back,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
