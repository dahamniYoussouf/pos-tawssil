import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';
import 'package:delivery_app/l10n/app_localizations.dart';

enum OrderHistoryFilter { all, ongoing, delivered, cancelled }

class OrderHistoryFilterBar extends StatelessWidget {
  final OrderHistoryFilter activeFilter;
  final ValueChanged<OrderHistoryFilter> onFilterChanged;

  const OrderHistoryFilterBar({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: OrderHistoryFilter.values.map((filter) {
          final isSelected = activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getFilterLabel(context, filter)),
              selected: isSelected,
              onSelected: (_) => onFilterChanged(filter),
              selectedColor: AppColors.primaryColor,
              checkmarkColor: AppColors.white,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.textGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: AppColors.scaffoldBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryColor : AppColors.greyLight,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterLabel(BuildContext context, OrderHistoryFilter filter) {
    final l10n = AppLocalizations.of(context)!;
    switch (filter) {
      case OrderHistoryFilter.all:
        return l10n.all;
      case OrderHistoryFilter.ongoing:
        return l10n.statusOngoing;
      case OrderHistoryFilter.delivered:
        return l10n.statusDelivered;
      case OrderHistoryFilter.cancelled:
        return l10n.statusCancelled;
    }
  }
}
