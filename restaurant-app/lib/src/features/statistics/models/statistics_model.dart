class StatisticsModel {
  final int totalOrders;
  final double totalRevenue;
  final int acceptedOrders;
  final int preparingOrders;
  final int deliveringOrders;
  final int deliveredOrders;
  final int pickedUpOrders;
  final double averageOrderValue;
  final Map<String, int> ordersByStatus;
  final Map<String, double> revenueByStatus;
  final Map<String, StatisticsPeriodData> periodData;

  StatisticsModel({
    required this.totalOrders,
    required this.totalRevenue,
    required this.acceptedOrders,
    required this.preparingOrders,
    required this.deliveringOrders,
    required this.deliveredOrders,
    required this.pickedUpOrders,
    required this.averageOrderValue,
    required this.ordersByStatus,
    required this.revenueByStatus,
    required this.periodData,
  });

  StatisticsPeriodData? getPeriodData(String period) => periodData[period];

  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    Map<String, int> parseOrdersByStatus(dynamic value) {
      if (value == null || value is! Map) return {};
      final Map<String, int> result = {};
      value.forEach((key, val) {
        result[key.toString()] = parseInt(val);
      });
      return result;
    }

    Map<String, double> parseRevenueByStatus(dynamic value) {
      if (value == null || value is! Map) return {};
      final Map<String, double> result = {};
      value.forEach((key, val) {
        result[key.toString()] = parseDouble(val);
      });
      return result;
    }

    bool isPeriodPayload(dynamic value) {
      if (value is! Map) return false;
      const periodKeys = {'today', 'yesterday', 'week', 'month', 'all'};
      return periodKeys.any((key) => value.containsKey(key));
    }

    Map<String, StatisticsPeriodData> parsePeriodData(dynamic value) {
      if (value is! Map) return <String, StatisticsPeriodData>{};
      final Map<String, StatisticsPeriodData> result = {};
      for (final entry in value.entries) {
        final key = entry.key.toString();
        if (entry.value is! Map<String, dynamic>) continue;
        result[key] = StatisticsPeriodData.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
      return result;
    }

    final Map<String, StatisticsPeriodData> periodData =
        isPeriodPayload(data) ? parsePeriodData(data) : {};
    final allPeriod = periodData['all'];

    final totalOrders = parseInt(
        allPeriod?.orders ?? data['total_orders'] ?? data['totalOrders']);
    final totalRevenue = parseDouble(
        allPeriod?.revenue ?? data['total_revenue'] ?? data['totalRevenue']);
    final acceptedOrders =
        parseInt(data['accepted_orders'] ?? data['acceptedOrders'] ?? 0);
    final preparingOrders =
        parseInt(data['preparing_orders'] ?? data['preparingOrders'] ?? 0);
    final deliveringOrders =
        parseInt(data['delivering_orders'] ?? data['deliveringOrders'] ?? 0);
    final deliveredOrders =
        parseInt(data['delivered_orders'] ?? data['deliveredOrders'] ?? 0);
    final pickedUpOrders =
        parseInt(data['picked_up_orders'] ?? data['pickedUpOrders'] ?? 0);

    final averageOrderValue =
        totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    final ordersByStatus =
        parseOrdersByStatus(data['orders_by_status'] ?? data['ordersByStatus']);
    final revenueByStatus = parseRevenueByStatus(
        data['revenue_by_status'] ?? data['revenueByStatus']);

    return StatisticsModel(
      totalOrders: totalOrders,
      totalRevenue: totalRevenue,
      acceptedOrders: acceptedOrders,
      preparingOrders: preparingOrders,
      deliveringOrders: deliveringOrders,
      deliveredOrders: deliveredOrders,
      pickedUpOrders: pickedUpOrders,
      averageOrderValue: averageOrderValue,
      ordersByStatus: ordersByStatus,
      revenueByStatus: revenueByStatus,
      periodData: periodData,
    );
  }
}

class StatisticsPeriodData {
  final int reviews;
  final int orders;
  final double revenue;
  final List<StatisticsChartDataPoint> chartData;

  const StatisticsPeriodData({
    required this.reviews,
    required this.orders,
    required this.revenue,
    required this.chartData,
  });

  factory StatisticsPeriodData.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    List<StatisticsChartDataPoint> parseChartData(dynamic value) {
      if (value is! List) return const [];
      return value
          .whereType<Map<String, dynamic>>()
          .map(StatisticsChartDataPoint.fromJson)
          .toList();
    }

    return StatisticsPeriodData(
      reviews: parseInt(json['reviews']),
      orders: parseInt(json['orders']),
      revenue: parseDouble(json['revenue']),
      chartData: parseChartData(json['chartData']),
    );
  }
}

class StatisticsChartDataPoint {
  final String time;
  final double mobile;
  final double pos;

  const StatisticsChartDataPoint({
    required this.time,
    required this.mobile,
    required this.pos,
  });

  factory StatisticsChartDataPoint.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return StatisticsChartDataPoint(
      time: json['time']?.toString() ?? '',
      mobile: parseDouble(json['mobile']),
      pos: parseDouble(json['pos']),
    );
  }
}
