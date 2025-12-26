import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AddressIconPopupMenu extends StatefulWidget {
  final String? selectedIcon;
  final Function(String) onIconSelected;
  const AddressIconPopupMenu({
    super.key,
    this.selectedIcon,
    required this.onIconSelected,
  });

  @override
  State<AddressIconPopupMenu> createState() => _AddressIconPopupMenuState();
}

class _AddressIconPopupMenuState extends State<AddressIconPopupMenu> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  String get _currentIcon => widget.selectedIcon ?? MediaRes.locationIconBlack;

  void _showPopupMenu(BuildContext context) {
    if (_overlayEntry != null) {
      return;
    }
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hidePopupMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: 120,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 12),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIconMenuItem(
                        overlayContext,
                        MediaRes.locationIconAddress,
                      ),
                      _buildIconMenuItem(
                        overlayContext,
                        MediaRes.homeIcon,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  Widget _buildIconMenuItem(
    BuildContext context,
    String iconPath,
  ) {
    final isSelected = _currentIcon == iconPath;
    return InkWell(
      onTap: () {
        _hidePopupMenu();
        widget.onIconSelected(iconPath);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorApp.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              height: 20,
              width: 20,
              colorFilter: ColorFilter.mode(
                isSelected ? ColorApp.primary : ColorApp.textBlack,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            if (isSelected)
              Icon(
                Icons.check,
                size: 16,
                color: ColorApp.primary,
              ),
          ],
        ),
      ),
    );
  }

  void _hidePopupMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hidePopupMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () => _showPopupMenu(context),
        child: Container(
          width: 60,
          height: 48,
          decoration: BoxDecoration(
            color: ColorApp.white,
            border: Border.all(color: ColorApp.greyBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                _currentIcon,
                height: 27,
                width: 27,
                colorFilter: ColorFilter.mode(
                  ColorApp.textBlack,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              SvgPicture.asset(
                MediaRes.arrowDownIcon,
                height: 20,
                width: 20,
                colorFilter: ColorFilter.mode(
                  ColorApp.textBlack,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
