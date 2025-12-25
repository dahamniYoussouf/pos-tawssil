import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

enum AddressMenuAction {
  edit,
  delete,
}

class AddressPopupMenu extends StatefulWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color? iconColor;
  final bool hideDelete;
  const AddressPopupMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.iconColor,
    this.hideDelete = false,
  });

  @override
  State<AddressPopupMenu> createState() => _AddressPopupMenuState();
}

class _AddressPopupMenuState extends State<AddressPopupMenu> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _showPopupMenu(BuildContext context) {
    if (_overlayEntry != null) {
      return;
    }
    final localizations = AppLocalizations.of(context)!;
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
            width: 150,
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
                      _buildMenuItem(
                        overlayContext,
                        localizations,
                        AddressMenuAction.edit,
                        MediaRes.editIcon,
                        localizations.edit,
                        ColorApp.textBlack,
                      ),
                      if (!widget.hideDelete)
                        _buildMenuItem(
                          overlayContext,
                          localizations,
                          AddressMenuAction.delete,
                          null,
                          localizations.delete,
                          Colors.red,
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

  Widget _buildMenuItem(
    BuildContext context,
    AppLocalizations localizations,
    AddressMenuAction action,
    String? iconPath,
    String text,
    Color textColor,
  ) {
    return InkWell(
      onTap: () {
        _hidePopupMenu();
        switch (action) {
          case AddressMenuAction.edit:
            widget.onEdit();
            break;
          case AddressMenuAction.delete:
            if (!widget.hideDelete) {
              widget.onDelete();
            }
            break;
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (iconPath != null)
              SvgPicture.asset(
                iconPath,
                height: 16,
                width: 16,
                colorFilter: ColorFilter.mode(
                  ColorApp.textBlack,
                  BlendMode.srcIn,
                ),
              )
            else if (!widget.hideDelete)
              const Icon(
                Icons.delete_outline,
                size: 16,
                color: ColorApp.textBlack,
              ),
            const SizedBox(width: 8),
            Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
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
        child: SvgPicture.asset(
          MediaRes.listIcon,
          height: 12,
          width: 12,
          colorFilter: ColorFilter.mode(
            widget.iconColor ?? ColorApp.textBlack,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
