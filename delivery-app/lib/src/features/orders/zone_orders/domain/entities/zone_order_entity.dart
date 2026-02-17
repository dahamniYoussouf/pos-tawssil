import 'package:equatable/equatable.dart';

enum ZoneLoadLevel { high, medium, low }

class ZoneOrderEntity extends Equatable {
  final String id;
  final String name;
  final int availableOrders;
  final int estimatedMinutes;
  final double progress;
  final ZoneLoadLevel loadLevel;

  const ZoneOrderEntity({
    required this.id,
    required this.name,
    required this.availableOrders,
    required this.estimatedMinutes,
    required this.progress,
    required this.loadLevel,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        availableOrders,
        estimatedMinutes,
        progress,
        loadLevel,
      ];
}
