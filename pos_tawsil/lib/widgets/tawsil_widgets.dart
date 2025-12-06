// lib/widgets/tawsil_widgets.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Badge Widget - Pour afficher des compteurs ou statuts
class TawsilBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;

  const TawsilBadge({
    Key? key,
    required this.text,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TawsilSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? TawsilColors.primary,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
      ),
      child: Text(
        text,
        style: TawsilTextStyles.badge.copyWith(
          color: textColor ?? TawsilColors.textOnPrimary,
        ),
      ),
    );
  }
}

/// Status Badge - Pour les statuts de commandes
class TawsilStatusBadge extends StatelessWidget {
  final String status;

  const TawsilStatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = TawsilColors.warning.withOpacity(0.2);
        textColor = TawsilColors.warning;
        displayText = 'En attente';
        break;
      case 'confirmed':
        backgroundColor = TawsilColors.info.withOpacity(0.2);
        textColor = TawsilColors.info;
        displayText = 'Confirmée';
        break;
      case 'preparing':
        backgroundColor = TawsilColors.accent.withOpacity(0.2);
        textColor = Colors.orange[800]!;
        displayText = 'En préparation';
        break;
      case 'ready':
        backgroundColor = TawsilColors.primary.withOpacity(0.2);
        textColor = TawsilColors.primary;
        displayText = 'Prête';
        break;
      case 'completed':
        backgroundColor = TawsilColors.success.withOpacity(0.2);
        textColor = TawsilColors.success;
        displayText = 'Terminée';
        break;
      case 'cancelled':
        backgroundColor = TawsilColors.error.withOpacity(0.2);
        textColor = TawsilColors.error;
        displayText = 'Annulée';
        break;
      default:
        backgroundColor = TawsilColors.textSecondary.withOpacity(0.2);
        textColor = TawsilColors.textSecondary;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TawsilSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.sm),
      ),
      child: Text(
        displayText,
        style: TawsilTextStyles.badge.copyWith(
          color: textColor,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Empty State Widget
class TawsilEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const TawsilEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TawsilSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(TawsilSpacing.lg),
              decoration: BoxDecoration(
                color: TawsilColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(TawsilBorderRadius.full),
              ),
              child: Icon(
                icon,
                size: 64,
                color: TawsilColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: TawsilSpacing.lg),
            Text(
              title,
              style: TawsilTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: TawsilSpacing.sm),
              Text(
                subtitle!,
                style: TawsilTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: TawsilSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading Widget
class TawsilLoading extends StatelessWidget {
  final String? message;

  const TawsilLoading({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(TawsilColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: TawsilSpacing.md),
            Text(
              message!,
              style: TawsilTextStyles.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// Error Widget
class TawsilError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const TawsilError({
    Key? key,
    required this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TawsilSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: TawsilColors.error,
            ),
            const SizedBox(height: TawsilSpacing.lg),
            Text(
              'Une erreur est survenue',
              style: TawsilTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TawsilSpacing.sm),
            Text(
              message,
              style: TawsilTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: TawsilSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Info Banner - Pour les messages informatifs
class TawsilInfoBanner extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onDismiss;

  const TawsilInfoBanner({
    Key? key,
    required this.message,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? TawsilColors.info.withOpacity(0.1);
    final fgColor = textColor ?? TawsilColors.info;

    return Container(
      margin: const EdgeInsets.all(TawsilSpacing.md),
      padding: const EdgeInsets.all(TawsilSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(TawsilBorderRadius.md),
        border: Border.all(
          color: fgColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.info_outline_rounded,
            color: fgColor,
            size: 20,
          ),
          const SizedBox(width: TawsilSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TawsilTextStyles.bodySmall.copyWith(
                color: fgColor,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: fgColor),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Confirmation Dialog
class TawsilConfirmDialog {
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    IconData? icon,
    Color? iconColor,
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TawsilBorderRadius.lg),
        ),
        title: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(TawsilSpacing.sm),
                decoration: BoxDecoration(
                  color: (iconColor ?? TawsilColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TawsilBorderRadius.sm),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? TawsilColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: TawsilSpacing.sm),
            ],
            Expanded(
              child: Text(
                title,
                style: TawsilTextStyles.headingMedium,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TawsilTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDanger
                ? ElevatedButton.styleFrom(
                    backgroundColor: TawsilColors.error,
                  )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

/// Section Header
class TawsilSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsets? padding;

  const TawsilSectionHeader({
    Key? key,
    required this.title,
    this.trailing,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(TawsilSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TawsilTextStyles.headingMedium,
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Price Display Widget
class TawsilPriceDisplay extends StatelessWidget {
  final double price;
  final TextStyle? style;
  final String currency;

  const TawsilPriceDisplay({
    Key? key,
    required this.price,
    this.style,
    this.currency = 'DA',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      '${price.toStringAsFixed(2)} $currency',
      style: style ?? TawsilTextStyles.priceMedium,
    );
  }
}