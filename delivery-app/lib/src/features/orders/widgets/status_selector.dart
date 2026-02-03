import 'package:flutter/material.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/features/orders/models/order_model.dart';

class StatusSelector extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  const StatusSelector({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  static const List<String> _availableStatuses = [
    OrderStatus.pending,
    OrderStatus.accepted,
    OrderStatus.preparing,
    OrderStatus.assigned,
    OrderStatus.arrived,
    OrderStatus.delivering,
    OrderStatus.delivered,
    OrderStatus.declined,
  ];

  String _getStatusLabel(String status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.assigned:
        return 'Assigned';
      case OrderStatus.arrived:
        return 'Arrived';
      case OrderStatus.delivering:
        return 'Delivering';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.declined:
        return 'Declined';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: AppColors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: _availableStatuses.length,
        itemBuilder: (context, index) {
          final status = _availableStatuses[index];
          final isSelected = status == selectedStatus;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _StatusChip(
              label: _getStatusLabel(status),
              isSelected: isSelected,
              onTap: () => onStatusChanged(status),
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.greyVeryLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.greyLight,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.grey,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
