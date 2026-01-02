import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AdditionalOption {
  final String id;
  final String name;
  final double price;

  const AdditionalOption({
    required this.id,
    required this.name,
    required this.price,
  });
}

class MenuItemDetailOptionsSection extends StatelessWidget {
  final List<AdditionalOption> options;
  final Set<String> selectedOptions;
  final ValueChanged<String> onOptionToggled;

  const MenuItemDetailOptionsSection({
    Key? key,
    required this.options,
    required this.selectedOptions,
    required this.onOptionToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.additionalOptions,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: ColorApp.black,
          ),
        ),
        const SizedBox(height: 12),
        ...options.map((option) {
          return _MenuDetailOptionItem(
            option: option,
            isSelected: selectedOptions.contains(option.id),
            onTap: () => onOptionToggled(option.id),
          );
        }),
      ],
    );
  }
}

class _MenuDetailOptionItem extends StatelessWidget {
  final AdditionalOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuDetailOptionItem({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? ColorApp.primary.withOpacity(0.05) : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: ColorApp.black,
                  ),
                ),
              ),
              Text(
                option.price > 0
                    ? '+ ${option.price.toStringAsFixed(0)} DA'
                    : 'Free',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: option.price > 0 ? ColorApp.primary : ColorApp.grey,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? ColorApp.primary : ColorApp.grey,
                    width: 2,
                  ),
                  color: isSelected ? ColorApp.primary : ColorApp.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: ColorApp.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
