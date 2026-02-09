import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/statistics/cubit/statistics_cubit.dart';
import 'package:restaurant_app/src/features/statistics/cubit/statistics_state.dart';
import 'package:restaurant_app/src/features/statistics/widgets/statistics_filters.dart';
import 'package:restaurant_app/src/features/statistics/widgets/statistics_display.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsCubit>().fetchStatistics();
    });
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
            color: AppColors.primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<StatisticsCubit, StatisticsState>(
        builder: (context, state) {
          return Column(
            children: [
              StatisticsFilters(
                dateFrom: state.dateFrom,
                dateTo: state.dateTo,
                selectedStatus: state.selectedStatus,
                minPrice: state.minPrice,
                maxPrice: state.maxPrice,
                onApplyFilters: () {
                  context.read<StatisticsCubit>().fetchStatistics();
                },
              ),
              Expanded(
                child: BlocConsumer<StatisticsCubit, StatisticsState>(
                  listener: (context, state) {
                    if (state is StatisticsError) {
                      final localizations = AppLocalizations.of(context)!;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_translateErrorMessage(
                              state.message, localizations)),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    final localizations = AppLocalizations.of(context)!;
                    if (state is StatisticsLoading &&
                        state.statistics == null) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      );
                    }
                    if (state is StatisticsError && state.statistics == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _translateErrorMessage(
                                  state.message, localizations),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context
                                    .read<StatisticsCubit>()
                                    .fetchStatistics();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                              ),
                              child: Text(localizations.retry),
                            ),
                          ],
                        ),
                      );
                    }
                    if (state.statistics != null) {
                      return StatisticsDisplay(statistics: state.statistics!);
                    }
                    return Center(
                      child: Text(localizations.noDataAvailable),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _translateErrorMessage(
      String message, AppLocalizations localizations) {
    if (message == 'errorDateRangeRequired') {
      return localizations.errorDateRangeRequired;
    } else if (message.contains('Failed to fetch statistics')) {
      return localizations.errorFailedToFetchOrders;
    } else if (message.contains('Error fetching statistics:')) {
      return message.replaceAll('Error fetching statistics: ', '');
    }
    return message;
  }
}
