import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/orders/cubit/order_history_cubit.dart';
import 'package:restaurant_app/src/features/orders/cubit/order_history_state.dart';
import 'package:restaurant_app/src/features/orders/models/order_history_filters.dart';

class OrderHistoryFiltersWidget extends StatefulWidget {
  const OrderHistoryFiltersWidget({super.key});

  @override
  State<OrderHistoryFiltersWidget> createState() =>
      _OrderHistoryFiltersWidgetState();
}

class _OrderHistoryFiltersWidgetState extends State<OrderHistoryFiltersWidget> {
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  OrderHistoryFilters? _originalFilters;

  @override
  void initState() {
    super.initState();
    // Store original filters when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cubit = context.read<OrderHistoryCubit>();
        _originalFilters = cubit.state.filters;
      }
    });
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;

    return BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
      builder: (context, state) {
        final filters = state.filters;

        // Sync controllers with current state
        _syncControllers(filters);

        return Container(
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.filters,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        // Restore original filters before closing
                        if (_originalFilters != null) {
                          context
                              .read<OrderHistoryCubit>()
                              .updateFiltersOnly(_originalFilters!);
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildStatusFilter(filters, localizations),
                      const SizedBox(height: 16),
                      _buildOrderTypeFilter(filters, localizations),
                      const SizedBox(height: 16),
                      _buildDateRangeFilter(filters, localizations),
                      const SizedBox(height: 16),
                      _buildPriceRangeFilter(localizations),
                      SizedBox(height: bottomPadding + 16),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + bottomPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await context
                              .read<OrderHistoryCubit>()
                              .clearFilters();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(localizations.reset),
                      ),
                    ),
                    const SizedBox(width: 12),
                    BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
                      builder: (context, state) {
                        return Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: state is OrderHistoryLoading
                                  ? AppColors.grey
                                  : AppColors.primaryColor,
                            ),
                            onPressed: state is OrderHistoryLoading
                                ? null
                                : () async {
                                    await _applyFilters(context);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                            child: state is OrderHistoryLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.white,
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.white),
                                    ))
                                : Text(
                                    localizations.apply,
                                    style:
                                        const TextStyle(color: AppColors.white),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _syncControllers(OrderHistoryFilters filters) {
    final minPriceText = filters.minPrice?.toString() ?? '';
    final maxPriceText = filters.maxPrice?.toString() ?? '';

    if (_minPriceController.text != minPriceText) {
      _minPriceController.text = minPriceText;
    }
    if (_maxPriceController.text != maxPriceText) {
      _maxPriceController.text = maxPriceText;
    }
  }

  Widget _buildStatusFilter(
      OrderHistoryFilters filters, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.statusLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildStatusChip(
              'delivered',
              localizations.delivered,
              filters.status,
            ),
            _buildStatusChip(
              'declined',
              localizations.refuse,
              filters.status,
            ),
            _buildStatusChip(
              'accepted',
              localizations.accepted,
              filters.status,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(
    String status,
    String label,
    List<String>? selectedStatuses,
  ) {
    final isSelected = selectedStatuses?.contains(status) ?? false;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        final cubit = context.read<OrderHistoryCubit>();
        final currentStatuses = List<String>.from(selectedStatuses ?? []);
        if (selected) {
          if (!currentStatuses.contains(status)) {
            currentStatuses.add(status);
          }
        } else {
          currentStatuses.remove(status);
        }
        cubit.setStatusOnly(currentStatuses.isEmpty ? null : currentStatuses);
      },
    );
  }

  Widget _buildOrderTypeFilter(
      OrderHistoryFilters filters, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.orderTypeLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: filters.orderType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(localizations.all),
            ),
            DropdownMenuItem(
              value: 'delivery',
              child: Text(localizations.deliveryOrderType),
            ),
            DropdownMenuItem(
              value: 'pickup',
              child: Text(localizations.pickupOrderType),
            ),
          ],
          onChanged: (value) {
            context.read<OrderHistoryCubit>().setOrderTypeOnly(value);
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(
      OrderHistoryFilters filters, AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.dateRangeLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: filters.dateFrom ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    final normalizedDate =
                        DateTime(date.year, date.month, date.day);
                    context.read<OrderHistoryCubit>().setDateRangeOnly(
                          normalizedDate,
                          filters.dateTo,
                        );
                  }
                },
                child: Text(
                  filters.dateFrom != null
                      ? '${filters.dateFrom!.day}/${filters.dateFrom!.month}/${filters.dateFrom!.year}'
                      : localizations.dateFromLabel,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: filters.dateTo ?? DateTime.now(),
                    firstDate: filters.dateFrom ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    final normalizedDate =
                        DateTime(date.year, date.month, date.day);
                    context.read<OrderHistoryCubit>().setDateRangeOnly(
                          filters.dateFrom,
                          normalizedDate,
                        );
                  }
                },
                child: Text(
                  filters.dateTo != null
                      ? '${filters.dateTo!.day}/${filters.dateTo!.month}/${filters.dateTo!.year}'
                      : localizations.dateToLabel,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.priceLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
            const SizedBox(width: 8),
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

  Future<void> _applyFilters(BuildContext context) async {
    final cubit = context.read<OrderHistoryCubit>();
    final currentFilters = cubit.state.filters;

    final minPrice = _minPriceController.text.isNotEmpty
        ? double.tryParse(_minPriceController.text)
        : null;
    final maxPrice = _maxPriceController.text.isNotEmpty
        ? double.tryParse(_maxPriceController.text)
        : null;

    final updatedFilters = currentFilters.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
    );

    await cubit.applyFilters(updatedFilters);
  }
}
