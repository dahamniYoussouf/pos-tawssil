import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';
import 'package:restaurant_app/src/features/orders/models/order_model.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final order = ModalRoute.of(context)!.settings.arguments as OrderModel;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.orderDetails,
          style: const TextStyle(
            color: AppColors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOrderContent(context, order, l10n),
            const SizedBox(height: 16),
            _buildPaymentSection(context, order, l10n),
            const SizedBox(height: 16),
            _buildOrderHistorySection(context, order, l10n),
            const SizedBox(height: 80), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(context, l10n),
    );
  }

  Widget _buildOrderContent(
      BuildContext context, OrderModel order, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orderContent,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Grouped by Category would be better, but OrderModel doesn't have it explicitly.
          // We'll list items and show their details.
          ...order.items
              .map((item) => _buildOrderItem(context, item, l10n))
              .toList(),
          const Divider(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${NumberFormat('#,###').format(order.totalPrice)} DA',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textLightGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
      BuildContext context, OrderItem item, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (item.categoryName ?? 'ORDER ITEM').toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.accentGreen,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${item.name} ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  TextSpan(
                    text: '${item.quantity} x',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGreen,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${NumberFormat('#,###').format(item.price)} DA',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF96A1B2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPaymentSection(
      BuildContext context, OrderModel order, AppLocalizations l10n) {
    // For "Livreur doit payer", we use 85% of total price as a placeholder for commission logic
    // In many systems, it's Total - Commission.
    final mustPay = order.totalPrice * 0.85;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.payment,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),
          _buildPaymentRow(
              l10n.paymentType, order.paymentMethod?.toUpperCase() ?? 'CASH'),
          const SizedBox(height: 12),
          _buildPaymentRow(l10n.initialPrice,
              '${NumberFormat('#,###').format(order.totalPrice)} DA'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.deliveryManMustPay,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              Text(
                '${NumberFormat('#,###').format(mustPay)} DA',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5AD5A4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF96A1B2),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSteel,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderHistorySection(
      BuildContext context, OrderModel order, AppLocalizations l10n) {
    final status = order.status.toLowerCase();

    // Logic for Timeline Status
    // Step 1: Received Order
    // Checked if status is not pending or declined
    final isReceivedChecked =
        status != OrderStatus.pending && status != OrderStatus.declined;

    // Step 2: Accepted by Delivery
    // Checked if status has moved to assigned, delivering or delivered
    final isAcceptedChecked = [
      OrderStatus.assigned,
      OrderStatus.arrived,
      OrderStatus.delivering,
      OrderStatus.delivered,
      OrderStatus.collected
    ].contains(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.orderHistory,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),
          _buildTimelineItem(
            time: order.createdAt != null
                ? DateFormat('HH:mm').format(order.createdAt!)
                : '',
            status: l10n.receivedOrder,
            isCurrent: isReceivedChecked,
          ),
          _buildTimelineItem(
            time: order.updatedAt != null
                ? DateFormat('HH:mm').format(order.updatedAt!)
                : '',
            status: l10n.acceptedByDelivery,
            isCurrent: isAcceptedChecked,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String status,
    bool isCurrent = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 24.0),
              child: Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.timelineGrey,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(isCurrent ? 1 : 0.2),
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                ),
                child: isCurrent
                    ? const Center(
                        child: Icon(Icons.check, size: 8, color: Colors.white),
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.timelineLine,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent
                      ? AppColors.accentGreen
                      : AppColors.textLightGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(37),
      color: AppColors.backgroundPage,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.print_outlined),
        label: Text(l10n.printReceipt),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonGrey,
          foregroundColor: AppColors.buttonText,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
