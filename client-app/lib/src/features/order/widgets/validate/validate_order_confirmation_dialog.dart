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
