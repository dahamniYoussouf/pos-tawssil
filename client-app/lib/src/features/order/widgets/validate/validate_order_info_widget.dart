import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/order/widgets/validate/validate_order_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';

class ValidateOrderDetailsSection extends StatelessWidget {
  const ValidateOrderDetailsSection(
      {super.key,
      required this.deliveryAddress,
      required this.estimatedTime,
      required this.totalPrice,
      required this.paymentMethod,
      required this.items,
      required this.orderDetailsLabel,
      required this.localization});
  final String deliveryAddress;
  final String estimatedTime;
  final double totalPrice;
  final String paymentMethod;
  final List<ValidateOrderItemData> items;
  final String orderDetailsLabel;
  final AppLocalizations localization;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          OrderInformationRow(
              title: localization.deliveryAddressLabel, value: deliveryAddress),
          const SizedBox(height: 16),
          OrderInformationRow(
              title: localization.deliveryTime, value: estimatedTime),
          const SizedBox(height: 16),
          OrderInformationRow(
              title: localization.totalLabel,
              value: localization.totalValue(totalPrice.toStringAsFixed(2))),
          const SizedBox(height: 16),
          OrderInformationRow(
              title: localization.paymentMethodLabel, value: paymentMethod),
          const SizedBox(height: 24),
          Text(orderDetailsLabel,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 12),
          OrderItemsList(items: items),
          const SizedBox(height: 300)
        ]);
  }
}

class OrderInformationRow extends StatelessWidget {
  const OrderInformationRow(
      {super.key, required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: ColorApp.black)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  color: ColorApp.grey,
                  fontWeight: FontWeight.w900))
        ]);
  }
}

class OrderItemsList extends StatelessWidget {
  const OrderItemsList({super.key, required this.items});
  final List<ValidateOrderItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((ValidateOrderItemData item) {
          return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                        child: Text('${item.name} x${item.quantity}',
                            style: const TextStyle(
                                fontSize: 14,
                                color: ColorApp.black,
                                fontWeight: FontWeight.w500))),
                    if (item.price != null)
                      Text('${item.price} DA',
                          style: const TextStyle(
                              fontSize: 14,
                              color: ColorApp.black,
                              fontWeight: FontWeight.w600))
                  ]));
        }).toList());
  }
}
