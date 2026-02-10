import 'package:flutter/material.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';

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
      backgroundColor: AppColors.white,
      title: Text(
        data.title,
        style: const TextStyle(color: AppColors.black),
        textAlign: TextAlign.center,
      ),
      content: Text(
        data.content,
        style: const TextStyle(color: AppColors.grey),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(data.borderRadius),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  data.onCancel?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: data.cancelButtonColor ?? AppColors.white,
                  foregroundColor: data.cancelTextColor ?? AppColors.grey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.greyLight,
                ),
                child: Text(
                  data.cancelText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: data.cancelTextColor ?? AppColors.grey,
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
                  foregroundColor: data.confirmTextColor ?? AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(data.borderRadius),
                  ),
                  disabledBackgroundColor: AppColors.greyLight,
                ),
                child: Text(
                  data.confirmText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: data.confirmTextColor ?? AppColors.white,
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
