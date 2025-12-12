import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:client_app/src/features/cart/services/cart_service.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/widgets/menu_item_detail_page.dart';
import 'package:flutter_svg/svg.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onQuantityDecrease;
  final VoidCallback onQuantityIncrease;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  const CartItemCard({
    Key? key,
    required this.item,
    required this.onQuantityDecrease,
    required this.onQuantityIncrease,
    required this.onRemove,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ColorApp.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: ColorApp.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: ColorApp.backgroundGrey,
                    image: item.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item.imageUrl),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
                  ),
                  child: item.imageUrl.isEmpty
                      ? Icon(Icons.restaurant, color: ColorApp.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.menuItemName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item.price.toStringAsFixed(0)} DA',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: ColorApp.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                                onTap: onQuantityDecrease,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: ColorApp.white,
                                    border:
                                        Border.all(color: ColorApp.greyBorder),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(Icons.remove, size: 18),
                                )),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            GestureDetector(
                                onTap: onQuantityIncrease,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: ColorApp.white,
                                    border:
                                        Border.all(color: ColorApp.greyBorder),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(Icons.add, size: 18),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.note != null && item.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${AppLocalizations.of(context)!.note}: ${item.note}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: ColorApp.greyBorder),
            const SizedBox(height: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ...defaultAdditionalOptions.map((option) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          option.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: ColorApp.black,
                          ),
                        ),
                        Text(
                          option.price.toStringAsFixed(0) + ' DA',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: ColorApp.primary,
                          ),
                        ),
                      ],
                    )),
              ],
            ),
          ])),
      Positioned(
        top: 0,
        right: 0,
        child: IconButton(
          onPressed: onRemove,
          icon: SvgPicture.asset(MediaRes.closeIcon, width: 20, height: 20),
        ),
      ),
      Positioned(
        top: 0,
        right: 25,
        child: IconButton(
          onPressed: onEdit,
          icon: SvgPicture.asset(MediaRes.editIcon, width: 20, height: 20),
        ),
      ),
    ]);
  }
}
