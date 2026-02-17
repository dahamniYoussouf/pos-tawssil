import 'package:delivery_app/src/features/orders/zone_orders/domain/entities/zone_order_entity.dart';
import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ZoneOrderCard extends StatelessWidget {
  final ZoneOrderEntity zone;
  final VoidCallback? onTap;

  const ZoneOrderCard({
    super.key,
    required this.zone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  zone.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
              _LoadBadge(level: zone.loadLevel),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 18,
                color: Color(0xFFFF8A3D),
              ),
              const SizedBox(width: 6),
              Text(
                localizations.zoneOrdersAvailable(zone.availableOrders),
                style: const TextStyle(
                  color: Color(0xFFFF8A3D),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ZoneProgress(
                  value: zone.progress,
                  estimatedMinutes: zone.estimatedMinutes,
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6EFF64),
                    foregroundColor: const Color(0xFF0B1A14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: Text(
                    localizations.zoneOrdersGo,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ZoneProgress extends StatelessWidget {
  final double value;
  final int estimatedMinutes;

  const _ZoneProgress({
    required this.value,
    required this.estimatedMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.zoneOrdersEstimatedTime(estimatedMinutes),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF67F75B)),
          ),
        ),
      ],
    );
  }
}

class _LoadBadge extends StatelessWidget {
  final ZoneLoadLevel level;

  const _LoadBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final info = _badgeInfo(level, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: info.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: info.text,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  _BadgeInfo _badgeInfo(ZoneLoadLevel level, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    switch (level) {
      case ZoneLoadLevel.high:
        return _BadgeInfo(
          label: localizations.zoneOrdersLoadHigh,
          background: const Color(0xFF66DB68),
          text: const Color(0xFF176B29),
        );
      case ZoneLoadLevel.medium:
        return _BadgeInfo(
          label: localizations.zoneOrdersLoadMedium,
          background: const Color(0xFF6A717A),
          text: const Color(0xFFF0F4F8),
        );
      case ZoneLoadLevel.low:
        return _BadgeInfo(
          label: localizations.zoneOrdersLoadLow,
          background: const Color(0xFF93A0AF),
          text: const Color(0xFFF9FAFB),
        );
    }
  }
}

class _BadgeInfo {
  final String label;
  final Color background;
  final Color text;

  const _BadgeInfo({
    required this.label,
    required this.background,
    required this.text,
  });
}
