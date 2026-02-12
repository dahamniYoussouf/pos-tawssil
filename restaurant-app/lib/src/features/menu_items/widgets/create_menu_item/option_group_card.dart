import 'package:flutter/material.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/menu_items/models/menu_item_model.dart';
import 'package:restaurant_app/src/features/menu_items/widgets/create_menu_item/pill_widget.dart';

class OptionGroupCard extends StatelessWidget {
  final MenuItemOptionGroup group;
  final VoidCallback onTap;

  const OptionGroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final optionCount = group.optionsCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.greyLight.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 10),
              ),
            ],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$optionCount ${optionCount != 1 ? localizations.options : localizations.option}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PillWidget(
                    label: group.isRequired
                        ? localizations.optionGroupRequired
                        : localizations.optionGroupOptional,
                    isSelected: group.isRequired,
                  ),
                  const SizedBox(width: 6),
                  PillWidget(
                    label: group.multipleChoice
                        ? localizations.multipleChoice
                        : localizations.singleChoice,
                    isSelected: group.multipleChoice,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
