import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/cart/cubit/cart_cubit.dart';
import 'package:client_app/src/features/order/index.dart';
import 'package:client_app/src/features/order/widgets/order_tracking_steps_widget.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const double _cardRadius = 17.0;
const double _cardPadding = 16.0;
const double _rowSpacing = 12.0;
const double _sectionSpacing = 16.0;
const double _orderItemImageSize = 64.0;
const double _orderItemImageRadius = 12.0;
const double _orderItemImageSpacing = 12.0;
const double _orderItemDescriptionSpacing = 4.0;

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
  final List<CartItem> items;
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
        const SizedBox(height: 8),

        // estimated time
        OrderInformationRow(
            title: localization.deliveryTime, value: estimatedTime),
        const SizedBox(height: _sectionSpacing),

        BlocBuilder<OrderCubit, OrderState>(builder: (context, state) {
          final String orderStatus = _getOrderStatusFromState(state: state);
          return OrderTrackingStepsWidget(orderStatus: orderStatus);
        }),
        const SizedBox(height: _rowSpacing),
        Divider(indent: 4, endIndent: 4, color: ColorApp.greyBorder),

        const SizedBox(height: _rowSpacing),

        OrderInformationRow(
            title: localization.deliveryAddressLabel,
            value: deliveryAddress.substring(0, 10) + '...'),
        const SizedBox(height: _rowSpacing),
        Divider(indent: 4, endIndent: 4, color: ColorApp.textBlack),
      ]),
      _OrderInfoCard(children: [
        Text(localization.products(items.length),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ColorApp.textBlack)),
        const SizedBox(height: _rowSpacing),
        OrderItemsList(items: items),
        const SizedBox(height: _rowSpacing),
        OrderInformationRow(
            title: localization.totalLabel,
            value: localization.totalValue(totalPrice.toStringAsFixed(2))),
      ])
    ]);
  }

  String _getOrderStatusFromState({required OrderState state}) {
    if (state is OrderLoaded) {
      return state.order.status;
    }
    if (state is OrderCreated) {
      return state.order.status;
    }
    if (state is OrderRefused) {
      return state.order.status;
    }
    if (state is OrderDelayed) {
      return state.order.status;
    }
    return OrderStatus.pending;
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
  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    final List<Widget> itemWidgets = [];
    for (int i = 0; i < items.length; i++) {
      final CartItem item = items[i];
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
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final String formattedPrice = item.totalPrice.toStringAsFixed(0);
    final String description = item.menuItem.description?.trim() ?? '';
    final bool hasDescription = description.isNotEmpty;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _OrderItemImage(imageUrl: item.imageUrl),
      const SizedBox(width: _orderItemImageSpacing),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${item.menuItemName} x${item.quantity}',
            style: const TextStyle(
                fontSize: 16,
                color: ColorApp.textBlack,
                fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        if (hasDescription)
          const SizedBox(height: _orderItemDescriptionSpacing),
        if (hasDescription)
          Text(description,
              style: const TextStyle(
                  fontSize: 13,
                  color: ColorApp.textGrey,
                  fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
      ])),
      const SizedBox(width: _orderItemImageSpacing),
      Text('$formattedPrice DA',
          style: const TextStyle(
              fontSize: 14,
              color: ColorApp.textBlack,
              fontWeight: FontWeight.w700))
    ]);
  }
}

class _OrderItemImage extends StatelessWidget {
  const _OrderItemImage({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const _OrderItemImagePlaceholder();
    }
    return ClipRRect(
        borderRadius: BorderRadius.circular(_orderItemImageRadius),
        child: Image.network(imageUrl,
            width: _orderItemImageSize,
            height: _orderItemImageSize,
            fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
          return const _OrderItemImagePlaceholder();
        }));
  }
}

class _OrderItemImagePlaceholder extends StatelessWidget {
  const _OrderItemImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: _orderItemImageSize,
        height: _orderItemImageSize,
        decoration: BoxDecoration(
            color: ColorApp.backgroundGrey,
            borderRadius: BorderRadius.circular(_orderItemImageRadius)),
        child: const Icon(Icons.restaurant, size: 28, color: ColorApp.grey));
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.only(
            left: _cardPadding, right: _cardPadding, bottom: _cardPadding),
        decoration: BoxDecoration(
          color: ColorApp.white,
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children));
  }
}
