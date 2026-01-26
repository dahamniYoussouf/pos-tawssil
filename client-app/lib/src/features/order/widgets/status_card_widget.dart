import 'dart:async';

import 'package:flutter/material.dart';
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
    final statusInfo = _getStatusInfo(widget.order.status);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorApp.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorApp.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusIcon(icon: statusInfo.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusInfo.title,
                      style: const TextStyle(
                        color: ColorApp.textBlack,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusInfo.description,
                      style: TextStyle(
                        color: ColorApp.textBlack.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      alignment: Alignment.center,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorApp.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: ColorApp.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'Temps estimé : ${_formatDuration(remainingTime)}',
            style: TextStyle(
              color: ColorApp.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration? duration) {
  if (duration == null) return '-- minutes';
  if (duration.isNegative || duration.inMinutes <= 0) return '0 minutes';
  return '${duration.inMinutes} minutes';
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

_OrderStatusInfo _getStatusInfo(String status) {
  switch (status) {
    case OrderStatus.pending:
      return const _OrderStatusInfo(
        icon: '⏳',
        title: 'Commande en attente',
        description: 'Votre commande a bien été transmise au restaurant et est en attente de confirmation.',
      );
    case OrderStatus.accepted:
      return const _OrderStatusInfo(
        icon: '✅',
        title: 'Commande acceptée',
        description: 'Le restaurant a accepté votre commande et va commencer la préparation.',
      );
    case OrderStatus.preparing:
      return const _OrderStatusInfo(
        icon: '🍳',
        title: 'Commande en préparation',
        description: 'Votre commande est actuellement en cours de préparation au restaurant.',
      );
    case OrderStatus.assigned:
      return const _OrderStatusInfo(
        icon: '🛵',
        title: 'Livreur assigné',
        description: 'Un livreur a été assigné à votre commande.',
      );
    case OrderStatus.delivering:
      return const _OrderStatusInfo(
        icon: '🛵',
        title: 'Livreur en route vers vous',
        description: 'Le livreur est en route vers votre adresse et arrivera prochainement.',
      );
    case OrderStatus.delivered:
      return const _OrderStatusInfo(
        icon: '✅',
        title: 'Commande livrée',
        description: 'Votre commande a été livrée avec succès.',
      );
    case OrderStatus.readyToCollect:
      return const _OrderStatusInfo(
        icon: '✅',
        title: 'Prêt à récupérer',
        description: 'Votre commande est prête à être récupérée.',
      );
    case OrderStatus.collected:
      return const _OrderStatusInfo(
        icon: '✅',
        title: 'Commande récupérée',
        description: 'Votre commande a été récupérée avec succès.',
      );
    default:
      return const _OrderStatusInfo(
        icon: '⏳',
        title: 'En cours',
        description: 'Votre commande est en cours de traitement.',
      );
  }
}
