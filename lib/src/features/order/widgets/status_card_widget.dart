import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/src/features/order/index.dart';

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
    if (oldWidget.order.estimatedDeliveryTime != widget.order.estimatedDeliveryTime) {
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
      setState(() => _remainingTime = estimatedDeliveryTime.difference(current));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00695C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Countdown Timer Circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2, style: BorderStyle.solid),
            ),
            child: Center(
              child: Text(
                _formatDuration(_remainingTime),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(widget.order.status, l10n!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(widget.order.status, l10n),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration? duration) {
  if (duration == null) return '-- min';
  if (duration.isNegative || duration.inMinutes <= 0) return '0 min';
  return '${duration.inMinutes} min';
}

String _getStatusText(String status, AppLocalizations l10n) {
  switch (status) {
    case OrderStatus.pending:
      return l10n.orderStatusPending;
    case OrderStatus.accepted:
      return l10n.orderStatusAccepted;
    case OrderStatus.preparing:
      return l10n.orderStatusPreparing;
    case OrderStatus.assigned:
      return l10n.orderStatusAssigned;
    case OrderStatus.delivering:
      return l10n.orderStatusDelivering;
    case OrderStatus.delivered:
      return l10n.orderStatusDelivered;
    default:
      return status;
  }
}

String _getStatusDescription(String status, AppLocalizations l10n) {
  switch (status) {
    case OrderStatus.pending:
      return l10n.orderStatusPendingDescription;
    case OrderStatus.accepted:
      return l10n.orderStatusAcceptedDescription;
    case OrderStatus.preparing:
      return l10n.orderStatusPreparingDescription;
    case OrderStatus.assigned:
      return l10n.orderStatusAssignedDescription;
    case OrderStatus.delivering:
      return l10n.orderStatusDeliveringDescription;
    case OrderStatus.delivered:
      return l10n.orderStatusDeliveredDescription;
    default:
      return '';
  }
}
