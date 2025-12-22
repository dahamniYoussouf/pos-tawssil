import 'package:flutter/material.dart';
import 'package:client_app/src/core/res/color_app.dart';

class OrderSummaryRow extends StatelessWidget {
  const OrderSummaryRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 13, color: ColorApp.textGrey)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ColorApp.textBlack,
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
