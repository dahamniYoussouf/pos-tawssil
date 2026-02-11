import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/orders/cubit/orders_cubit.dart';
import 'package:restaurant_app/src/features/orders/cubit/orders_state.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({
    super.key,
    required this.order,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('d MMM yyyy ,hh:mm a', 'fr').format(date);
  }

  String _formatPrice(double price) {
    return '${NumberFormat('#,###').format(price)}DA';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.borderLight, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(l10n),
            const SizedBox(height: 20),
            _buildItemsByCategory(),
            //Prix Totale +  
            _buildFooter(context, l10n),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.orderTitle(order.orderNumber),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDate(order.createdAt),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textLightGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsByCategory() {
    // Group items by categoryName
    final Map<String, List<OrderItem>> grouped = {};
    for (final item in order.items) {
      final cat = item.categoryName ?? 'PIZZA';
      grouped.putIfAbsent(cat, () => []);
      grouped[cat]!.add(item);
    }

    final entries = grouped.entries.toList();
    final widgets = <Widget>[];

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];

      // Category title (green)
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            entry.key,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      );

      // Items in this category
      for (final item in entry.value) {
        widgets.add(_buildMainItem(item));
        if (item.specialInstructions != null &&
            item.specialInstructions!.isNotEmpty) {
          for (final line in item.specialInstructions!.split('\n')) {
            if (line.trim().isNotEmpty) {
              widgets.add(_buildModifierRow(line.trim()));
            }
          }
        }
      }
      if (i < entries.length - 1) {
        widgets.add(const Divider(height: 24, color: AppColors.borderLight));
      }
    }
    widgets.add(const Divider(height: 24, color: AppColors.borderLight));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildMainItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${item.name} ',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  TextSpan(
                    text: 'X ${item.quantity}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            _formatPrice(item.totalPrice),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildModifierRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLightGrey,
              ),
            ),
          ),
          const Text(
            '0DA',  
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLightGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            // Prix Totale on left side
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.totalPrice,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLightGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${NumberFormat('#,###').format(order.totalPrice)} DA',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
            if (order.status == OrderStatus.pending)
              _buildActionButtons(context, l10n),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<OrdersCubit, OrdersState>(builder: (context, state) {
      final actionLoading =
          state is OrderActionLoading && state.orderId == order.id;
      final isCancelLoading =
          actionLoading && state.actionType == OrderActionType.cancel;
      final isAcceptLoading =
          actionLoading && state.actionType == OrderActionType.accept;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: (isCancelLoading || isAcceptLoading)
                  ? null
                  : () => context.read<OrdersCubit>().cancelOrder(order.id),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                side: const BorderSide(color: AppColors.greyLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isCancelLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.black),
                      ),
                    )
                  : Text(
                      l10n.refuse,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // Accepter button
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: (isCancelLoading || isAcceptLoading)
                  ? null
                  : () => context.read<OrdersCubit>().acceptOrder(order.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isAcceptLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : Text(
                      l10n.accept,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
        ],
      );
    });
  }
}
