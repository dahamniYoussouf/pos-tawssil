import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:client_app/src/features/cart/cubit/cart_cubit.dart';
import 'package:client_app/src/features/restaurant/models/menu_model.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onQuantityDecrease;
  final VoidCallback onQuantityIncrease;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  const CartItemCard({
    Key? key,
    required this.item,
    required this.onQuantityDecrease,
    required this.onQuantityIncrease,
    required this.onRemove,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorApp.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: ColorApp.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: ColorApp.backgroundGrey,
                    image: item.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item.imageUrl),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
                  ),
                  child: item.imageUrl.isEmpty
                      ? Icon(Icons.restaurant, color: ColorApp.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.menuItemName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.price.toStringAsFixed(0)} DA',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ColorApp.primary),
                      ),
                      Container(
                        height: 26,
                        width: 85,
                        margin: EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: ColorApp.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                                onTap: onQuantityDecrease,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: ColorApp.white,
                                    border:
                                        Border.all(color: ColorApp.greyBorder),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(Icons.remove, size: 18),
                                )),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                                onTap: onQuantityIncrease,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: ColorApp.white,
                                    border:
                                        Border.all(color: ColorApp.greyBorder),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(Icons.add, size: 18),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.note != null && item.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${AppLocalizations.of(context)!.note}: ${item.note}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (item.selectedOptions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: ColorApp.greyBorder),
              const SizedBox(height: 12),
              _CartItemSelectedOptions(
                selectedOptionGroups: _buildSelectedOptionGroups(item),
              ),
            ],
          ])),
      Positioned(
        top: 5,
        right: 10,
        child: IconButton(
          onPressed: onRemove,
          icon: SvgPicture.asset(MediaRes.closeIcon, width: 20, height: 20),
        ),
      ),
      Positioned(
        top: 5,
        right: 35,
        child: IconButton(
          onPressed: onEdit,
          icon: SvgPicture.asset(MediaRes.editIcon, width: 20, height: 20),
        ),
      ),
    ]);
  }

  List<_SelectedOptionGroup> _buildSelectedOptionGroups(CartItem item) {
    final Map<String, List<MenuItemOption>> optionsByGroupId =
        <String, List<MenuItemOption>>{};
    for (final MenuItemOption option in item.selectedOptions) {
      final String? groupId =
          option.optionGroupId ?? _findGroupIdForOption(item, option.id);
      if (groupId == null) {
        continue;
      }
      optionsByGroupId.putIfAbsent(groupId, () => <MenuItemOption>[]);
      optionsByGroupId[groupId]!.add(option);
    }
    final List<_SelectedOptionGroup> groups = <_SelectedOptionGroup>[];
    for (final MapEntry<String, List<MenuItemOption>> entry
        in optionsByGroupId.entries) {
      final MenuItemOptionGroup? group =
          _findGroupById(item.menuItem.optionGroups, entry.key);
      groups.add(_SelectedOptionGroup(
        title: group?.nom ?? 'Options',
        options: entry.value,
      ));
    }
    return groups;
  }

  MenuItemOptionGroup? _findGroupById(
    List<MenuItemOptionGroup> groups,
    String groupId,
  ) {
    for (final MenuItemOptionGroup group in groups) {
      if (group.id == groupId) {
        return group;
      }
    }
    return null;
  }

  String? _findGroupIdForOption(CartItem item, String optionId) {
    for (final MenuItemOptionGroup group in item.menuItem.optionGroups) {
      final bool hasOption =
          group.options.any((MenuItemOption option) => option.id == optionId);
      if (hasOption) {
        return group.id;
      }
    }
    return null;
  }
}

class _SelectedOptionGroup {
  final String title;
  final List<MenuItemOption> options;

  const _SelectedOptionGroup({
    required this.title,
    required this.options,
  });
}

class _CartItemSelectedOptions extends StatelessWidget {
  final List<_SelectedOptionGroup> selectedOptionGroups;

  const _CartItemSelectedOptions({
    required this.selectedOptionGroups,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: selectedOptionGroups.map((group) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: ColorApp.black,
                ),
              ),
              const SizedBox(height: 6),
              ...group.options.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          option.nom,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ColorApp.black,
                          ),
                        ),
                      ),
                      Text(
                        option.prix > 0
                            ? '+ ${option.prix.toStringAsFixed(0)} DA'
                            : 'Free',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: option.prix > 0
                              ? ColorApp.primary
                              : ColorApp.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      }).toList(),
    );
  }
}
