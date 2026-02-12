import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/statistics/cubit/statistics_cubit.dart';
import 'package:restaurant_app/src/features/statistics/cubit/statistics_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  // Fake data
  final Map<String, Map<String, dynamic>> _fakeData = {
    'today': {
      'orders': 42,
      'revenue': 223241,
      'chartData': [
        {'time': '10AM', 'mobile': 5000, 'pos': 4500},
        {'time': '11AM', 'mobile': 6200, 'pos': 5800},
        {'time': '12PM', 'mobile': 8500, 'pos': 7200},
        {'time': '01PM', 'mobile': 7800, 'pos': 8200},
        {'time': '02PM', 'mobile': 7200, 'pos': 8800},
        {'time': '03PM', 'mobile': 8800, 'pos': 7500},
        {'time': '04PM', 'mobile': 9500, 'pos': 8200},
      ],
    },
    'yesterday': {
      'orders': 38,
      'revenue': 198450,
      'chartData': [
        {'time': '10AM', 'mobile': 4500, 'pos': 4200},
        {'time': '11AM', 'mobile': 5800, 'pos': 5400},
        {'time': '12PM', 'mobile': 7800, 'pos': 6800},
        {'time': '01PM', 'mobile': 7200, 'pos': 7800},
        {'time': '02PM', 'mobile': 6800, 'pos': 8200},
        {'time': '03PM', 'mobile': 8200, 'pos': 7100},
        {'time': '04PM', 'mobile': 8800, 'pos': 7800},
      ],
    },
    'week': {
      'orders': 294,
      'revenue': 1562847,
      'chartData': [
        {'time': 'Mon', 'mobile': 35000, 'pos': 32000},
        {'time': 'Tue', 'mobile': 42000, 'pos': 38000},
        {'time': 'Wed', 'mobile': 48000, 'pos': 44000},
        {'time': 'Thu', 'mobile': 45000, 'pos': 48000},
        {'time': 'Fri', 'mobile': 52000, 'pos': 49000},
        {'time': 'Sat', 'mobile': 58000, 'pos': 54000},
        {'time': 'Sun', 'mobile': 55000, 'pos': 52000},
      ],
    },
    'month': {
      'orders': 1247,
      'revenue': 6854923,
      'chartData': [
        {'time': 'W1', 'mobile': 145000, 'pos': 138000},
        {'time': 'W2', 'mobile': 168000, 'pos': 155000},
        {'time': 'W3', 'mobile': 182000, 'pos': 172000},
        {'time': 'W4', 'mobile': 195000, 'pos': 185000},
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsCubit>().fetchStatistics();
    });
  }

  Future<void> _refreshStatistics() async {
    await context.read<StatisticsCubit>().fetchStatistics();
  }

  Map<String, dynamic> _getCurrentData(String period) => _fakeData[period]!;

  int _getDisplayedOrders(String source, String period) {
    final orders = _getCurrentData(period)['orders'] as int;
    if (source == 'all') return orders;
    if (source == 'mobile') return (orders * 0.55).round();
    return (orders * 0.45).round();
  }

  double _getDisplayedRevenue(String source, String period) {
    final revenue = (_getCurrentData(period)['revenue'] as num).toDouble();
    if (source == 'all') return revenue;
    if (source == 'mobile') return revenue * 0.55;
    return revenue * 0.45;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          localizations.statistics,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<StatisticsCubit, StatisticsState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: _refreshStatistics,
            color: AppColors.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSourceFilter(context, localizations, state),
                  const SizedBox(height: 16),
                  _buildPeriodFilter(context, localizations, state),
                  const SizedBox(height: 24),
                  _buildStatCards(localizations, state),
                  const SizedBox(height: 24),
                  _buildRevenueChart(localizations, state),
                  const SizedBox(height: 24),
                  _buildReviewsSection(localizations),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSourceFilter(BuildContext context,
      AppLocalizations localizations, StatisticsState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSourceTab(context, localizations.all, 'all', state),
          ),
          Expanded(
            child: _buildSourceTab(
                context, localizations.appMobile, 'mobile', state),
          ),
          Expanded(
            child: _buildSourceTab(context, localizations.pos, 'pos', state),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceTab(
      BuildContext context, String label, String value, StatisticsState state) {
    final isSelected = state.selectedSource == value;
    return GestureDetector(
      onTap: () {
        context.read<StatisticsCubit>().setSource(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.black : AppColors.textMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodFilter(BuildContext context,
      AppLocalizations localizations, StatisticsState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildPeriodChip(context, localizations.today, 'today', state),
          const SizedBox(width: 12),
          _buildPeriodChip(
              context, localizations.yesterday, 'yesterday', state),
          const SizedBox(width: 12),
          _buildPeriodChip(context, localizations.days7, 'week', state),
          const SizedBox(width: 12),
          _buildPeriodChip(context, localizations.days30, 'month', state),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(
      BuildContext context, String label, String value, StatisticsState state) {
    final isSelected = state.selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        context.read<StatisticsCubit>().setPeriod(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primaryColor : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? AppColors.primaryColor : AppColors.inputBackground,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(
      AppLocalizations localizations, StatisticsState state) {
    final displayedOrders =
        _getDisplayedOrders(state.selectedSource, state.selectedPeriod);
    final displayedRevenue =
        _getDisplayedRevenue(state.selectedSource, state.selectedPeriod);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              value: displayedOrders.toString(),
              label: localizations.commands,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              value: '${(displayedRevenue / 1000).toStringAsFixed(0)}k',
              label: localizations.revenue,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyLight.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(
      AppLocalizations localizations, StatisticsState state) {
    final chartData =
        _getCurrentData(state.selectedPeriod)['chartData'] as List;
    final displayedRevenue =
        _getDisplayedRevenue(state.selectedSource, state.selectedPeriod);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyLight.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.totalRevenueLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${displayedRevenue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} DA',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  localizations.seeDetails,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFE2E8F0),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < chartData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              chartData[value.toInt()]['time'],
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (chartData.length - 1).toDouble(),
                minY: 0,
                maxY: _getMaxY(chartData),
                lineBarsData: [
                  if (state.selectedSource == 'all' ||
                      state.selectedSource == 'mobile')
                    _buildLineChartBarData(
                      chartData,
                      'mobile',
                      AppColors.primaryColor,
                    ),
                  if (state.selectedSource == 'all' ||
                      state.selectedSource == 'pos')
                    _buildLineChartBarData(
                      chartData,
                      'pos',
                      const Color(0xFF64748B),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.selectedSource == 'all' ||
                  state.selectedSource == 'mobile') ...[
                _buildLegendItem(
                    localizations.appMobile, AppColors.primaryColor),
                const SizedBox(width: 24),
              ],
              if (state.selectedSource == 'all' ||
                  state.selectedSource == 'pos')
                _buildLegendItem(localizations.pos, const Color(0xFF64748B)),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineChartBarData(
    List chartData,
    String key,
    Color color,
  ) {
    return LineChartBarData(
      spots: List.generate(
        chartData.length,
        (index) => FlSpot(
          index.toDouble(),
          (chartData[index][key] as num).toDouble(),
        ),
      ),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: Colors.white,
            strokeWidth: 2,
            strokeColor: color,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  double _getMaxY(List chartData) {
    double maxValue = 0;
    for (var data in chartData) {
      final mobileValue = (data['mobile'] as num).toDouble();
      final posValue = (data['pos'] as num).toDouble();
      maxValue = math.max(maxValue, math.max(mobileValue, posValue));
    }
    return maxValue * 1.2;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyLight.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.reviews,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  localizations.seeAllReviews,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Color(0xFFFBBF24),
                size: 32,
              ),
              const SizedBox(width: 8),
              const Text(
                '4.9',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                localizations.totalReviewsCount(20),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
