import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;

  const SearchBarWidget({
    Key? key,
    required this.controller,
    this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: ColorApp.backgroundGrey,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ColorApp.greyBorder,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SvgPicture.asset(MediaRes.searchIcon, height: 20, width: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: ColorApp.textBlack,
                  ),
              decoration: InputDecoration(
                hintText: hintText ?? localizations.searchRestaurantPlaceholder,
                hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ColorApp.textGrey,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
