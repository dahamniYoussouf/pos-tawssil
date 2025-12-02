import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/statistics/cubit/statistics_cubit.dart';

enum DateFilterType {
  today,
  thisWeek,
  thisMonth,
  custom,
}

class StatisticsFilters extends StatefulWidget {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? selectedStatus;
  final double? minPrice;
  final double? maxPrice;
  final VoidCallback onApplyFilters;

  const StatisticsFilters({
    super.key,
    required this.dateFrom,
    required this.dateTo,
    required this.selectedStatus,
    required this.minPrice,
    required this.maxPrice,
    required this.onApplyFilters,
  });

  @override
  State<StatisticsFilters> createState() => _StatisticsFiltersState();
}

class _StatisticsFiltersState extends State<StatisticsFilters> {
  DateFilterType _selectedDateFilter = DateFilterType.thisMonth;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _updateDateFilterFromDates();
    _minPriceController.text = widget.minPrice?.toString() ?? '';
    _maxPriceController.text = widget.maxPrice?.toString() ?? '';
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _updateDateFilterFromDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (widget.dateFrom != null && widget.dateTo != null) {
      final from = DateTime(
          widget.dateFrom!.year, widget.dateFrom!.month, widget.dateFrom!.day);
      final to = DateTime(
          widget.dateTo!.year, widget.dateTo!.month, widget.dateTo!.day);

      if (from == today && to == today) {
        _selectedDateFilter = DateFilterType.today;
      } else {
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        if (from == startOfWeek && to == endOfWeek) {
          _selectedDateFilter = DateFilterType.thisWeek;
        } else {
          final startOfMonth = DateTime(now.year, now.month, 1);
          if (from == startOfMonth && to == now) {
            _selectedDateFilter = DateFilterType.thisMonth;
          } else {
            _selectedDateFilter = DateFilterType.custom;
          }
        }
      }
    }
  }

  void _applyDateFilter(DateFilterType type) {
    final now = DateTime.now();
    DateTime? from;
    DateTime? to;

    switch (type) {
      case DateFilterType.today:
        from = DateTime(now.year, now.month, now.day);
        to = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DateFilterType.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        from = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        to = now;
        break;
      case DateFilterType.thisMonth:
        from = DateTime(now.year, now.month, 1);
        to = now;
        break;
      case DateFilterType.custom:
        _showDateRangePicker();
        return;
    }

    context.read<StatisticsCubit>().setDateRange(from, to);
    _selectedDateFilter = type;
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: widget.dateFrom != null && widget.dateTo != null
          ? DateTimeRange(start: widget.dateFrom!, end: widget.dateTo!)
          : null,
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      context.read<StatisticsCubit>().setDateRange(picked.start, picked.end);
      _selectedDateFilter = DateFilterType.custom;
    }
  }

  void _applyFilters() {
    final minPrice = _minPriceController.text.isNotEmpty
        ? double.tryParse(_minPriceController.text)
        : null;
    final maxPrice = _maxPriceController.text.isNotEmpty
        ? double.tryParse(_maxPriceController.text)
        : null;

    context.read<StatisticsCubit>().setPriceRange(minPrice, maxPrice);
    widget.onApplyFilters();
  }

  void _clearFilters() {
    context.read<StatisticsCubit>().clearFilters();
    _minPriceController.clear();
    _maxPriceController.clear();
    _selectedDateFilter = DateFilterType.thisMonth;
    widget.onApplyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.greyVeryLight,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDateFilterChips(),
                    ),
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 16),
                  _buildStatusFilter(localizations),
                  const SizedBox(height: 16),
                  _buildPriceFilter(localizations),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearFilters,
                          style: OutlinedButton.styleFrom(
                            side:
                                const BorderSide(color: AppColors.primaryColor),
                          ),
                          child: Text(
                            localizations.reset,
                            style:
                                const TextStyle(color: AppColors.primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                          ),
                          child: Text(localizations.apply),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (widget.dateFrom != null && widget.dateTo != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                '${DateFormat('dd MMM yyyy', 'fr').format(widget.dateFrom!)} - ${DateFormat('dd MMM yyyy', 'fr').format(widget.dateTo!)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateFilterChips() {
    final localizations = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      children: [
        _buildFilterChip(
          localizations.today,
          DateFilterType.today,
        ),
        _buildFilterChip(
          localizations.thisWeek,
          DateFilterType.thisWeek,
        ),
        _buildFilterChip(
          localizations.thisMonth,
          DateFilterType.thisMonth,
        ),
        _buildFilterChip(
          localizations.custom,
          DateFilterType.custom,
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, DateFilterType type) {
    final isSelected = _selectedDateFilter == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _applyDateFilter(type);
        }
      },
      selectedColor: AppColors.primaryColor.withOpacity(0.3),
      checkmarkColor: AppColors.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryColor : AppColors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatusFilter(AppLocalizations localizations) {
    final statuses = [
      {'value': 'accepted', 'label': localizations.accepted},
      {'value': 'preparing', 'label': localizations.preparing},
      {'value': 'delivering', 'label': localizations.delivering},
      {'value': 'delivered', 'label': localizations.delivered},
      {'value': 'picked-up', 'label': localizations.pickedUp},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.statusLabel,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: Text(localizations.all),
              selected: widget.selectedStatus == null,
              onSelected: (selected) {
                if (selected) {
                  context.read<StatisticsCubit>().setStatus(null);
                }
              },
              selectedColor: AppColors.primaryColor.withOpacity(0.3),
              checkmarkColor: AppColors.primaryColor,
            ),
            ...statuses.map((status) {
              final isSelected = widget.selectedStatus == status['value'];
              return FilterChip(
                label: Text(status['label']!),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    context.read<StatisticsCubit>().setStatus(status['value']);
                  } else {
                    context.read<StatisticsCubit>().setStatus(null);
                  }
                },
                selectedColor: AppColors.primaryColor.withOpacity(0.3),
                checkmarkColor: AppColors.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primaryColor : AppColors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceFilter(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.priceRangeLabel,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: localizations.minPrice,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: localizations.maxPrice,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
