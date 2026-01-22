import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/src/features/order/models/order_model.dart';

class OrderTrackingStepsWidget extends StatelessWidget {
  final String orderStatus;
  const OrderTrackingStepsWidget({super.key, required this.orderStatus});

  static const List<String> _icons = <String>[
    MediaRes.trackingOrderIconStep1,
    MediaRes.trackingOrderIconStep2,
    MediaRes.trackingOrderIconStep3,
    MediaRes.trackingOrderIconStep4,
  ];
  static const List<String> _stepStatuses = <String>[
    OrderStatus.accepted,
    OrderStatus.assigned,
    OrderStatus.delivering,
    OrderStatus.collected,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(children: _buildStepWidgets());
  }

  List<Widget> _buildStepWidgets() {
    final int activeIndex = _getActiveStepIndex();
    final List<Widget> widgets = <Widget>[];
    for (int i = 0; i < _icons.length; i++) {
      final bool isActive = i <= activeIndex && activeIndex != -1;
      widgets.add(_buildStepIcon(asset: _icons[i], isActive: isActive));
      if (i < _icons.length - 1) {
        widgets.add(_buildConnector());
      }
    }
    return widgets;
  }

  int _getActiveStepIndex() {
    return _stepStatuses.indexOf(orderStatus);
  }

  Widget _buildStepIcon({required String asset, required bool isActive}) {
    final Color iconColor =
        isActive ? ColorApp.primary : ColorApp.greyIconColor;
    return Container(
        width: 37,
        height: 37,
        alignment: Alignment.center,
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ColorApp.white,
            border: Border.all(color: ColorApp.greyBorder, width: 2)),
        child: SvgPicture.asset(asset,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)));
  }

  Widget _buildConnector() {
    return Expanded(
        child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: ColorApp.greyBorder));
  }
}
