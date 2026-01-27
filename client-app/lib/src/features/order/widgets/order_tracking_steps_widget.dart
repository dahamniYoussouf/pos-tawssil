import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/src/features/order/models/order_model.dart';

class OrderTrackingStepsWidget extends StatelessWidget {
  final String orderStatus;
  const OrderTrackingStepsWidget({super.key, required this.orderStatus});

  static const List<_StepData> _steps = <_StepData>[
    _StepData(
      iconAsset: MediaRes.trackingOrderIconStep1,
      status: OrderStatus.pending,
    ),
    _StepData(
      iconAsset: MediaRes.trackingOrderIconStep2,
      status: OrderStatus.accepted,
    ),
    _StepData(
      iconAsset: MediaRes.trackingOrderIconStep3,
      status: OrderStatus.preparing,
    ),
    _StepData(
      iconAsset: MediaRes.trackingOrderIconStep4,
      status: OrderStatus.delivering,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(children: _buildStepWidgets());
  }

  List<Widget> _buildStepWidgets() {
    final int activeIndex = _getActiveStepIndex();
    final List<Widget> widgets = <Widget>[];
    for (int i = 0; i < _steps.length; i++) {
      final bool isPrimary = _shouldStepBePrimary(i, activeIndex);
      final bool isCompleted = i < activeIndex;
      widgets.add(
        _StepIconWidget(
          iconAsset: _steps[i].iconAsset,
          isPrimary: isPrimary,
          isCompleted: isCompleted,
        ),
      );
      if (i < _steps.length - 1) {
        widgets.add(_ConnectorWidget(isActive: isCompleted));
      }
    }
    return widgets;
  }

  bool _shouldStepBePrimary(int stepIndex, int activeIndex) {
    if (activeIndex == -1) return false;
    // Step should be primary when we've moved past its status
    if (stepIndex < activeIndex) return true;
    // Special case: last step becomes primary when delivered or collected
    if (stepIndex == _steps.length - 1 && stepIndex == activeIndex) {
      return orderStatus == OrderStatus.delivered ||
          orderStatus == OrderStatus.collected;
    }
    return false;
  }

  int _getActiveStepIndex() {
    final List<String> statusHierarchy = <String>[
      OrderStatus.pending,
      OrderStatus.accepted,
      OrderStatus.preparing,
      OrderStatus.assigned,
      OrderStatus.delivering,
      OrderStatus.delivered,
      OrderStatus.collected,
    ];
    final int currentStatusIndex = statusHierarchy.indexOf(orderStatus);
    if (currentStatusIndex == -1) return -1;
    for (int i = _steps.length - 1; i >= 0; i--) {
      final int stepStatusIndex = statusHierarchy.indexOf(_steps[i].status);
      if (currentStatusIndex >= stepStatusIndex) {
        return i;
      }
    }
    return -1;
  }
}

class _StepData {
  final String iconAsset;
  final String status;

  const _StepData({
    required this.iconAsset,
    required this.status,
  });
}

class _StepIconWidget extends StatelessWidget {
  final String iconAsset;
  final bool isPrimary;
  final bool isCompleted;

  const _StepIconWidget({
    required this.iconAsset,
    required this.isPrimary,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        isPrimary ? ColorApp.primary.withOpacity(0.1) : ColorApp.white;
    final Color borderColor =
        isPrimary ? ColorApp.primary : ColorApp.greyBorder;
    final Color iconColor =
        isPrimary ? ColorApp.primary : ColorApp.greyIconColor;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: SvgPicture.asset(
        iconAsset,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }
}

class _ConnectorWidget extends StatelessWidget {
  final bool isActive;

  const _ConnectorWidget({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isActive ? ColorApp.primary : ColorApp.greyBorder,
      ),
    );
  }
}
