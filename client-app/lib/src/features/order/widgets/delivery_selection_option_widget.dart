import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

class DeliveryOptionSection extends StatelessWidget {
  final String selectedOption;
  final ValueChanged<String> onOptionSelected;

  const DeliveryOptionSection({
    required this.selectedOption,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            AppLocalizations.of(context)!.deliveryOption,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: ColorApp.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(2.0),
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: ColorApp.backgroundGrey,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ColorApp.greyBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: DeliveryOptionWidget(
                  label: AppLocalizations.of(context)!.delivery,
                  value: 'delivery',
                  isSelected: selectedOption == 'delivery',
                  onTap: () => onOptionSelected('delivery'),
                  radiusLeft: 24,
                  icon: MediaRes.deliveryIcon,
                ),
              ),
              Expanded(
                child: DeliveryOptionWidget(
                  label: AppLocalizations.of(context)!.pickup,
                  value: 'pickup',
                  isSelected: selectedOption == 'pickup',
                  onTap: () => onOptionSelected('pickup'),
                  radiusRight: 24,
                  icon: MediaRes.pickUpIcon,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class DeliveryOptionWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;
  final double? radiusLeft;
  final double? radiusRight;
  final String? icon;

  const DeliveryOptionWidget({
    Key? key,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
    this.radiusLeft,
    this.radiusRight,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? ColorApp.primary : ColorApp.backgroundGrey,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radiusLeft ?? 0),
            bottomLeft: Radius.circular(radiusLeft ?? 0),
            topRight: Radius.circular(radiusRight ?? 0),
            bottomRight: Radius.circular(radiusRight ?? 0),
          ),
          border: Border.all(
            color: isSelected ? ColorApp.primary : ColorApp.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              SvgPicture.asset(icon!,
                  width: 18,
                  height: 18,
                  color: isSelected ? ColorApp.white : ColorApp.black),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                  color: isSelected ? ColorApp.white : ColorApp.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
