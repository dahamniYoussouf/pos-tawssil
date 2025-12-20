import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';

class RestaurantSearchBar extends StatefulWidget {
  final Function(String)? onSearch;
  final bool readOnly;
  final String? hintText;
  final TextEditingController? controller;

  const RestaurantSearchBar({
    Key? key,
    this.onSearch,
    this.readOnly = false,
    this.hintText,
    this.controller,
  }) : super(key: key);

  @override
  State<RestaurantSearchBar> createState() => _RestaurantSearchBarState();
}

class _RestaurantSearchBarState extends State<RestaurantSearchBar> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Only dispose internal controller if widget didn't receive one from parent
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorApp.backgroundGrey,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ColorApp.greyBorder,
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SvgPicture.asset(MediaRes.searchIcon, height: 20, width: 20),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              readOnly: widget.readOnly,
              onChanged: (value) {
                setState(() {}); // Update UI for clear button
                if (widget.onSearch != null) widget.onSearch!(value);
              },
              onSubmitted: (value) {
                if (widget.onSearch != null) {
                  widget.onSearch!(value);
                }
              },
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: ColorApp.black,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText ??
                    AppLocalizations.of(context)?.searchRestaurantPlaceholder ??
                    'Rechercher des restaurant...',
                hintStyle: TextStyle(
                  color: ColorApp.textBlack,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
