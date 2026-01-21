import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/order/widgets/validate/validate_order_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';

const double _cardRadius = 17.0;
const double _cardPadding = 16.0;
const double _rowSpacing = 12.0;
const double _sectionSpacing = 16.0;

class ValidateOrderDetailsSection extends StatelessWidget {
  const ValidateOrderDetailsSection(
      {super.key,
      required this.deliveryAddress,
      required this.estimatedTime,
      required this.totalPrice,
      required this.paymentMethod,
      required this.items,
      required this.orderDetailsLabel,
      required this.localization,
      required this.orderNumber});
  final String deliveryAddress;
  final String estimatedTime;
  final double totalPrice;
  final String paymentMethod;
  final List<ValidateOrderItemData> items;
  final String orderDetailsLabel;
  final AppLocalizations localization;
  final String orderNumber;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _OrderInfoCard(children: [
        Text(localization.orderValidationTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: ColorApp.textBlack)),
        const SizedBox(height: 8),
        Text(localization.orderValidationDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorApp.textGrey)),
        const SizedBox(height: _rowSpacing),
        OrderInformationRow(
            title: localization.deliveryAddressLabel,
            value: deliveryAddress.substring(0, 10) + '...'),
        const SizedBox(height: _rowSpacing),
        // estimated time
        OrderInformationRow(
            title: localization.deliveryTime, value: estimatedTime),
        const SizedBox(height: _rowSpacing),
        OrderInformationRow(
            title: localization.totalLabel,
            value: localization.totalValue(totalPrice.toStringAsFixed(2))),
      ]),
      const SizedBox(height: _sectionSpacing),
      _OrderInfoCard(children: [
        Text(orderDetailsLabel,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ColorApp.textBlack)),
        const SizedBox(height: _rowSpacing),
        OrderItemsList(items: items),
      ])
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
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorApp.textBlack)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  color: ColorApp.greyIconColor,
                  fontWeight: FontWeight.w700))
        ]);
  }
}

class OrderItemsList extends StatelessWidget {
  const OrderItemsList({super.key, required this.items});
  final List<ValidateOrderItemData> items;

  @override
  Widget build(BuildContext context) {
    final List<Widget> itemWidgets = [];
    for (int i = 0; i < items.length; i++) {
      final ValidateOrderItemData item = items[i];
      itemWidgets.add(_OrderItemRow(item: item));
      if (i != items.length - 1) {
        itemWidgets.add(const Divider(height: 16, color: ColorApp.greyDivider));
      }
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: itemWidgets);
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});
  final ValidateOrderItemData item;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
          child: Text('${item.name} x${item.quantity}',
              style: const TextStyle(
                  fontSize: 14,
                  color: ColorApp.textBlack,
                  fontWeight: FontWeight.w600))),
      if (item.price != null)
        Text('${item.price} DA',
            style: const TextStyle(
                fontSize: 14,
                color: ColorApp.textBlack,
                fontWeight: FontWeight.w700))
    ]);
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(_cardPadding),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children));
  }
}
