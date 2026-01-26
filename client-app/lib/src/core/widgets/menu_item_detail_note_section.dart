import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

class MenuItemDetailNoteSection extends StatelessWidget {
  final String note;
  final ValueChanged<String> onNoteChanged;

  const MenuItemDetailNoteSection({
    Key? key,
    required this.note,
    required this.onNoteChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                MediaRes.noteIcon,
                width: 22,
                height: 22,
                color: ColorApp.black,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.noteForKitchen,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: ColorApp.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 115,
            decoration: BoxDecoration(
              color: ColorApp.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.noteForKitchen,
                hintStyle: TextStyle(
                  color: ColorApp.grey,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: ColorApp.backgroundGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorApp.greyBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorApp.greyBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorApp.primary),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: ColorApp.black,
              ),
              onChanged: onNoteChanged,
            ),
          ),
          const SizedBox(height: 150),
        ],
      ),
    );
  }
}
