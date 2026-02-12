import 'package:flutter/material.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';

class ItemActifSwitch extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const ItemActifSwitch({
    super.key,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              localizations.itemActive,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryColor,
            activeTrackColor: AppColors.primaryColor.withValues(alpha: 0.5),
            inactiveThumbColor: AppColors.greyLight,
            inactiveTrackColor: AppColors.greyLight.withValues(alpha: 0.5),
            trackOutlineColor: WidgetStateProperty.resolveWith(
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.transparent;
                }
                return AppColors.greyLight;
              },
            ),
          ),
        ],
      ),
    );
  }
}
