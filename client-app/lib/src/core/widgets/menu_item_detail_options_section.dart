import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';

class OptionGroupData {
  final String id;
  final String name;
  final bool isRequired;
  final List<OptionItemData> options;

  const OptionGroupData({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.options,
  });
}

class OptionItemData {
  final String id;
  final String name;
  final double price;
  final bool isAvailable;

  const OptionItemData({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
  });
}

class MenuItemDetailOptionsSection extends StatelessWidget {
  final List<OptionGroupData> optionGroups;
  final Map<String, Set<String>> selectedOptionsByGroup;
  final void Function(String groupId, String optionId, bool isRequired)
      onOptionToggled;

  const MenuItemDetailOptionsSection({
    Key? key,
    required this.optionGroups,
    required this.selectedOptionsByGroup,
    required this.onOptionToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          itemCount: optionGroups.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return _OptionGroupSection(
              group: optionGroups[index],
              selectedOptionIds:
                  selectedOptionsByGroup[optionGroups[index].id] ?? <String>{},
              onOptionToggled: onOptionToggled,
              isListView: index == 0,
            );
          },
        ),
      ],
    );
  }
}

class _OptionGroupSection extends StatelessWidget {
  final OptionGroupData group;
  final Set<String> selectedOptionIds;
  final void Function(String groupId, String optionId, bool isRequired)
      onOptionToggled;
  final bool isListView;

  const _OptionGroupSection({
    required this.group,
    required this.selectedOptionIds,
    required this.onOptionToggled,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    final int selectedCount = selectedOptionIds.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OptionGroupHeader(
            title: group.name,
            isRequired: group.isRequired,
            selectedCount: selectedCount,
          ),
          const SizedBox(height: 10),
          if (isListView)
            ListView.builder(
              itemCount: group.options.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return _OptionItemTile(
                  option: group.options[index],
                  isRequiredGroup: group.isRequired,
                  isSelected:
                      selectedOptionIds.contains(group.options[index].id),
                  onTap: group.options[index].isAvailable
                      ? () => onOptionToggled(
                          group.id, group.options[index].id, group.isRequired)
                      : null,
                );
              },
            ),
          if (!isListView)
            GridView.builder(
              itemCount: group.options.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 1,
                crossAxisSpacing: 4,
                childAspectRatio: 2.8,
              ),
              itemBuilder: (context, index) {
                return _OptionItemTile(
                  option: group.options[index],
                  isRequiredGroup: group.isRequired,
                  isSelected:
                      selectedOptionIds.contains(group.options[index].id),
                  onTap: group.options[index].isAvailable
                      ? () => onOptionToggled(
                          group.id, group.options[index].id, group.isRequired)
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _OptionGroupHeader extends StatelessWidget {
  final String title;
  final bool isRequired;
  final int selectedCount;

  const _OptionGroupHeader({
    required this.title,
    required this.isRequired,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final String selectionText = isRequired
        ? localizations.optionSelectionRequired(selectedCount)
        : localizations.optionSelectionOptional(selectedCount);
    final String helperText = isRequired
        ? localizations.optionRequiredHint
        : localizations.optionOptionalHint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: ColorApp.black,
              ),
            ),
            const SizedBox(width: 8),
            _OptionGroupBadge(isRequired: isRequired),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          helperText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorApp.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          selectionText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ColorApp.grey,
          ),
        ),
      ],
    );
  }
}

class _OptionGroupBadge extends StatelessWidget {
  final bool isRequired;

  const _OptionGroupBadge({
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isRequired ? ColorApp.redColor : ColorApp.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isRequired
            ? localizations.optionRequiredBadge
            : localizations.optionOptionalBadge,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: ColorApp.white,
        ),
      ),
    );
  }
}

class _OptionItemTile extends StatelessWidget {
  final OptionItemData option;
  final bool isRequiredGroup;
  final bool isSelected;
  final VoidCallback? onTap;

  const _OptionItemTile({
    required this.option,
    required this.isRequiredGroup,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color selectorColor = isSelected ? ColorApp.primary : ColorApp.grey;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final String priceText = option.price > 0
        ? localizations.optionAdditionalPrice(option.price.toStringAsFixed(0))
        : localizations.free;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ColorApp.greyBorder),
            color: option.isAvailable
                ? isSelected
                    ? ColorApp.primary.withOpacity(0.05)
                    : null
                : ColorApp.greyBorder,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: option.isAvailable ? ColorApp.black : ColorApp.grey,
                  ),
                ),
              ),
              Text(
                option.isAvailable
                    ? priceText
                    : AppLocalizations.of(context)!.notAvailable,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: option.isAvailable
                      ? option.price > 0
                          ? ColorApp.primary
                          : ColorApp.grey
                      : ColorApp.redColor,
                ),
              ),
              const SizedBox(width: 8),
              if (option.isAvailable) ...[
                isRequiredGroup
                    ? _RadioSelector(
                        isSelected: isSelected,
                        color: selectorColor,
                      )
                    : _CheckboxSelector(
                        isSelected: isSelected,
                        color: selectorColor,
                      ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioSelector extends StatelessWidget {
  final bool isSelected;
  final Color color;

  const _RadioSelector({
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            )
          : null,
    );
  }
}

class _CheckboxSelector extends StatelessWidget {
  final bool isSelected;
  final Color color;

  const _CheckboxSelector({
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 2),
        color: isSelected ? color : ColorApp.transparent,
      ),
      child: isSelected
          ? const Icon(
              Icons.check,
              size: 16,
              color: ColorApp.white,
            )
          : null,
    );
  }
}
