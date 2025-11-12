import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/src/core/res/color_app.dart';
import 'package:frontend/src/core/res/media_res.dart';
import 'package:frontend/src/features/order/models/order_model.dart';

class OrderTimeline extends StatelessWidget {
  final OrderModel order;
  final AppLocalizations localization;
  const OrderTimeline({super.key, required this.order, required this.localization});

  @override
  Widget build(BuildContext context) {
    final List<_TimelineItemData> items = _createTimelineItems();
    final int activeIndex = items.indexWhere((item) => item.status == order.status);
    if (activeIndex == -1) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: ColorApp.greyDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ColorApp.primary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          for (int index = 0; index < items.length; index++) _OrderTimelineStep(item: items[index], index: index, activeIndex: activeIndex, totalCount: items.length),
        ],
      ),
    );
  }

  List<_TimelineItemData> _createTimelineItems() {
    return <_TimelineItemData>[
      _TimelineItemData(
        status: OrderStatus.pending,
        title: localization.orderTracking,
        description: '',
        icon: MediaRes.suivIcon,
      ),
      _TimelineItemData(
        status: OrderStatus.accepted,
        title: localization.orderStatusAccepted,
        description: localization.orderStatusAcceptedDescription,
        icon: MediaRes.acceptIcon,
      ),
      _TimelineItemData(
        status: OrderStatus.preparing,
        title: localization.orderStatusPreparing,
        description: localization.orderStatusPreparingDescription,
        icon: MediaRes.prepareIcon,
      ),
      if (order.orderType == "delivery")
        _TimelineItemData(
          status: OrderStatus.delivering,
          title: localization.orderStatusDelivering,
          description: localization.orderStatusDeliveringDescription,
          icon: MediaRes.routeIcon,
        ),
      if (order.orderType == "delivery")
        _TimelineItemData(
          status: OrderStatus.delivered,
          title: localization.orderStatusDelivered,
          description: localization.orderStatusDeliveredDescription,
          icon: MediaRes.deliveryEndIcon,
        ),
      if (order.orderType != "delivery")
        _TimelineItemData(
          status: OrderStatus.readyToCollect,
          title: localization.orderStatusPretRecuperer,
          description: localization.orderStatusPretRecupererDescription,
          icon: MediaRes.pretRecupererIcon,
        ),
      if (order.orderType != "delivery")
        _TimelineItemData(
          status: OrderStatus.collected,
          title: localization.orderStatusRecuperer,
          description: localization.orderStatusRecupererDescription,
          icon: MediaRes.recupererIcon,
        ),
    ];
  }
}

class _OrderTimelineStep extends StatelessWidget {
  final _TimelineItemData item;
  final int index;
  final int activeIndex;
  final int totalCount;
  const _OrderTimelineStep({required this.item, required this.index, required this.activeIndex, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final bool isActive = index <= activeIndex;
    final bool isLast = index == totalCount - 1;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrderTimelineIndicator(icon: item.icon, isActive: isActive, isLast: isLast),
          const SizedBox(width: 8),
          Expanded(child: _OrderTimelineTexts(item: item, isActive: isActive)),
        ],
      ),
    );
  }
}

class _OrderTimelineIndicator extends StatelessWidget {
  final String icon;
  final bool isActive;
  final bool isLast;
  const _OrderTimelineIndicator({required this.icon, required this.isActive, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isActive ? ColorApp.primary : ColorApp.greyLight;
    final Color iconColor = isActive ? ColorApp.primary : ColorApp.greyLight;
    return SizedBox(
      width: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(icon, width: 24, height: 24, color: iconColor),
          if (!isLast)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 2,
              height: 13,
              decoration: BoxDecoration(color: borderColor),
            ),
        ],
      ),
    );
  }
}

class _OrderTimelineTexts extends StatelessWidget {
  final _TimelineItemData item;
  final bool isActive;
  const _OrderTimelineTexts({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? ColorApp.primary : ColorApp.grey,
          ),
        ),
      ],
    );
  }
}

class _TimelineItemData {
  final String status;
  final String title;
  final String? description;
  final String icon;
  const _TimelineItemData({required this.status, required this.title, required this.description, required this.icon});
}
