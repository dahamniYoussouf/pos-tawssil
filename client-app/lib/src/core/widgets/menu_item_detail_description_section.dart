import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';

class MenuItemDetailDescriptionSection extends StatelessWidget {
  final String description;
  final VoidCallback? onShowAll;

  const MenuItemDetailDescriptionSection({
    Key? key,
    required this.description,
    this.onShowAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: ColorApp.grey,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: onShowAll,
              child: Text(
                AppLocalizations.of(context)!.showAll,
                style: TextStyle(
                  fontSize: 14,
                  color: ColorApp.grey,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.end,
              ),
            )
          ],
        )
      ],
    );
  }
}

