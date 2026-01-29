import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';
//filter
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
              label: Text(_getFilterLabel(filter)),
              selected: isSelected,
              onSelected: (_) => onFilterChanged(filter),
              selectedColor: ColorApp.primary,
              checkmarkColor: ColorApp.white,
              labelStyle: TextStyle(
                color: isSelected ? ColorApp.white : ColorApp.textGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: ColorApp.backgroundGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? ColorApp.primary : ColorApp.greyBorder,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
// here the filter switcher
  String _getFilterLabel(OrderHistoryFilter filter) {
    switch (filter) {
      case OrderHistoryFilter.all:
        return 'Tous';
      case OrderHistoryFilter.ongoing:
        return 'En cours';
      case OrderHistoryFilter.delivered:
        return 'Livré';
      case OrderHistoryFilter.cancelled:
        return 'Annulé';
    }
  }
}
