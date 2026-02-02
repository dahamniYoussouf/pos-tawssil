import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';

class ConfirmationDialogData {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final Color? confirmButtonColor;
  final Color? cancelButtonColor;
  final Color? confirmTextColor;
  final Color? cancelTextColor;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool barrierDismissible;
  final double borderRadius;

  const ConfirmationDialogData({
    required this.title,
    required this.content,
    required this.confirmText,
    required this.cancelText,
    required this.onConfirm,
    this.onCancel,
    this.confirmButtonColor,
    this.cancelButtonColor,
    this.confirmTextColor,
    this.cancelTextColor,
    this.barrierDismissible = true,
    this.borderRadius = 24,
  });
}

class ConfirmationDialog extends StatelessWidget {
  final ConfirmationDialogData data;

  const ConfirmationDialog({
    super.key,
    required this.data,
  });

  static void show(
    BuildContext context,
    ConfirmationDialogData data, {
    bool useRootNavigator = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: data.barrierDismissible,
      useRootNavigator: useRootNavigator,
      builder: (dialogContext) => ConfirmationDialog(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: Text(
        data.title,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontWeight: FontWeight.w700,
          fontFamily: 'Gilmer',
        ),
        textAlign: TextAlign.center,
      ),
      content: Text(
        data.content,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontFamily: 'Gilmer',
        ),
        textAlign: TextAlign.center,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(data.borderRadius),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  data.onCancel?.call();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  data.cancelText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilmer',
                    color: data.cancelTextColor ?? const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  data.onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      data.confirmButtonColor ?? AppColors.primaryColor,
                  foregroundColor: data.confirmTextColor ?? Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  data.confirmText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Gilmer',
                    color: data.confirmTextColor ?? Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
