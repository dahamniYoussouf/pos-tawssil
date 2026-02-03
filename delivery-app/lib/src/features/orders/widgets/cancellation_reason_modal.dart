import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/core/res/app_theme.dart';
import 'package:flutter/material.dart';

class CancellationReasonModal extends StatefulWidget {
  final Function(String reason, String? otherReason) onConfirm;

  const CancellationReasonModal({
    super.key,
    required this.onConfirm,
  });

  @override
  State<CancellationReasonModal> createState() =>
      _CancellationReasonModalState();
}

class _CancellationReasonModalState extends State<CancellationReasonModal> {
  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();
  bool _showOtherField = false;

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Using hardcoded strings matching the mockup as we might not have all in ARB yet
    // I will use localizations if possible, falling back to French as in mockup
    final Map<String, String> reasons = {
      'driver_late': localizations.cancelReasonDriverLate,
      'client_canceled': localizations.cancelReasonClientCanceled,
      'technical_issue': localizations.cancelReasonTechnicalIssue,
      'other': localizations.cancelReasonOther,
    };

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close Button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.greyLight),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            Text(
              "Pourquoi souhaitez-vous annuler cette commande ?",
              style: AppTextStyles.gilmerBold.copyWith(
                fontSize: 20,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Aidez-nous à améliorer votre expérience.",
              style: TextStyle(
                color: AppColors.textMedium,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Reason Options
            ...reasons.entries.map((entry) {
              final String key = entry.key;
              final String label = entry.value;
              final bool isSelected = _selectedReason == key;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedReason = key;
                      _showOtherField = key == 'other';
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.greyLight,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: AppTextStyles.gilmerMedium.copyWith(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Other Reason Field
            if (_showOtherField) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _otherReasonController,
                decoration: InputDecoration(
                  hintText: "Saisissez votre raison ici...",
                  fillColor: AppColors.backgroundLight,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 3,
              ),
            ],

            const SizedBox(height: 32),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedReason == null
                    ? null
                    : () {
                        widget.onConfirm(
                          reasons[_selectedReason!]!,
                          _showOtherField ? _otherReasonController.text : null,
                        );
                        Navigator.of(context).pop();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFF14336), // Vibrant red matching mockup
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Confirmer L'annulation",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Return Button
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "Retour",
                  style: TextStyle(
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
