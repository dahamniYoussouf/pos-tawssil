import 'dart:async';

import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/order/index.dart';

class StatusCardWidget extends StatefulWidget {
  final OrderModel order;
  const StatusCardWidget({super.key, required this.order});

  @override
  State<StatusCardWidget> createState() => _StatusCardWidgetState();
}

class _StatusCardWidgetState extends State<StatusCardWidget> {
  Timer? _countdownTimer;
  Duration? _remainingTime;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void didUpdateWidget(covariant StatusCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.estimatedDeliveryTime !=
        widget.order.estimatedDeliveryTime) {
      _startCountdownTimer();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    final DateTime? estimatedDeliveryTime = widget.order.estimatedDeliveryTime;
    if (estimatedDeliveryTime == null) {
      setState(() => _remainingTime = null);
      return;
    }
    final DateTime now = DateTime.now();
    if (estimatedDeliveryTime.isBefore(now)) {
      setState(() => _remainingTime = Duration.zero);
      return;
    }
    setState(() => _remainingTime = estimatedDeliveryTime.difference(now));
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final DateTime current = DateTime.now();
      if (estimatedDeliveryTime.isBefore(current)) {
        setState(() => _remainingTime = Duration.zero);
        timer.cancel();
        return;
      }
      setState(
          () => _remainingTime = estimatedDeliveryTime.difference(current));
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(context, widget.order.status);
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: ColorApp.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StatusIcon(icon: statusInfo.icon),
              Text(
                statusInfo.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ColorApp.textBlack,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            statusInfo.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColorApp.textBlack.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (_remainingTime != null) ...[
            const SizedBox(height: 12),
            _EstimatedTimeWidget(remainingTime: _remainingTime),
          ],
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final String icon;
  const _StatusIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.centerLeft,
      child: Text(
        icon,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}

class _EstimatedTimeWidget extends StatelessWidget {
  final Duration? remainingTime;
  const _EstimatedTimeWidget({required this.remainingTime});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              '${localizations.estimatedTime} : ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColorApp.textBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              _formatDuration(context, remainingTime),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ColorApp.textBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ));
  }
}

String _formatDuration(BuildContext context, Duration? duration) {
  final localizations = AppLocalizations.of(context)!;
  if (duration == null) return '-- ${localizations.minutes}';
  if (duration.isNegative || duration.inMinutes <= 0) {
    return '0 ${localizations.minutes}';
  }
  return '${duration.inMinutes} ${localizations.minutes}';
}

class _OrderStatusInfo {
  final String icon;
  final String title;
  final String description;

  const _OrderStatusInfo({
    required this.icon,
    required this.title,
    required this.description,
  });
}

_OrderStatusInfo _getStatusInfo(BuildContext context, String status) {
  final localizations = AppLocalizations.of(context)!;
  switch (status) {
    case OrderStatus.pending:
      return _OrderStatusInfo(
        icon: '⏳',
        title: localizations.statusCardPendingTitle,
        description: localizations.statusCardPendingDescription,
      );
    case OrderStatus.accepted:
      return _OrderStatusInfo(
        icon: '✅',
        title: localizations.statusCardAcceptedTitle,
        description: localizations.statusCardAcceptedDescription,
      );
    case OrderStatus.preparing:
      return _OrderStatusInfo(
        icon: '🍳',
        title: localizations.statusCardPreparingTitle,
        description: localizations.statusCardPreparingDescription,
      );
    case OrderStatus.assigned:
      return _OrderStatusInfo(
        icon: '🛵',
        title: localizations.statusCardAssignedTitle,
        description: localizations.statusCardAssignedDescription,
      );
    case OrderStatus.delivering:
      return _OrderStatusInfo(
        icon: '🛵',
        title: localizations.statusCardDeliveringTitle,
        description: localizations.statusCardDeliveringDescription,
      );
    case OrderStatus.delivered:
      return _OrderStatusInfo(
        icon: '✅',
        title: localizations.statusCardDeliveredTitle,
        description: localizations.statusCardDeliveredDescription,
      );
    case OrderStatus.readyToCollect:
      return _OrderStatusInfo(
        icon: '✅',
        title: localizations.statusCardReadyToCollectTitle,
        description: localizations.statusCardReadyToCollectDescription,
      );
    case OrderStatus.collected:
      return _OrderStatusInfo(
        icon: '✅',
        title: localizations.statusCardCollectedTitle,
        description: localizations.statusCardCollectedDescription,
      );
    default:
      return _OrderStatusInfo(
        icon: '⏳',
        title: localizations.statusCardDefaultTitle,
        description: localizations.statusCardDefaultDescription,
      );
  }
}
