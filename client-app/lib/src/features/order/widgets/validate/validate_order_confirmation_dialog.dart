import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';

class ValidateOrderConfirmationDialog extends StatelessWidget {
  const ValidateOrderConfirmationDialog(
      {super.key,
      required this.title,
      required this.message,
      required this.totalLabel,
      required this.totalValue,
      required this.paymentLabel,
      required this.paymentValue,
      required this.deliveryTimeLabel,
      required this.deliveryTimeValue,
      required this.cancelLabel,
      required this.confirmLabel,
      required this.onCancel,
      required this.onConfirm});
  final String title;
  final String message;
  final String totalLabel;
  final String totalValue;
  final String paymentLabel;
  final String paymentValue;
  final String deliveryTimeLabel;
  final String deliveryTimeValue;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: <Widget>[
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: ColorApp.white,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.check_circle_outline,
                  color: ColorApp.primary, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18)))
        ]),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(message, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!)),
                  child: Column(children: <Widget>[
                    OrderSummaryRow(label: totalLabel, value: totalValue),
                    const Divider(height: 16),
                    OrderSummaryRow(label: paymentLabel, value: paymentValue),
                    const Divider(height: 16),
                    OrderSummaryRow(
                        label: deliveryTimeLabel, value: deliveryTimeValue)
                  ]))
            ]),
        actions: <Widget>[
          TextButton(
              onPressed: onCancel,
              child:
                  Text(cancelLabel, style: TextStyle(color: Colors.grey[600]))),
          ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                  backgroundColor: ColorApp.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: Text(confirmLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.white)))
        ]);
  }
}

class OrderSummaryRow extends StatelessWidget {
  const OrderSummaryRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ]);
  }
}

class ValidateOrderItemData {
  const ValidateOrderItemData(
      {required this.name, required this.quantity, this.price});
  final String name;
  final int quantity;
  final String? price;

  factory ValidateOrderItemData.fromMap(Map<String, dynamic> map) {
    final dynamic rawQuantity = map['quantity'];
    final dynamic rawPrice = map['price'];
    final int parsedQuantity =
        rawQuantity is int ? rawQuantity : int.tryParse('$rawQuantity') ?? 0;
    return ValidateOrderItemData(
        name: '${map['name']}',
        quantity: parsedQuantity,
        price: rawPrice?.toString());
  }
}
