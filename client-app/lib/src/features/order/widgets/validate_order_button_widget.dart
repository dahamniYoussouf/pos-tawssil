import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/home/pages/home_page.dart';
import 'package:client_app/src/features/order/cubit/order_cubit.dart';

class ValidateOrderButtonWidget extends StatelessWidget {
  final OrderCubit orderCubit;

  const ValidateOrderButtonWidget({
    super.key,
    required this.orderCubit,
  });

  void _onValidatePressed(BuildContext context) {
    // Stop polling
    orderCubit.stopPolling();

    // Navigate to home page and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _onValidatePressed(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorApp.primary,
            foregroundColor: ColorApp.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: Text(
            localization.validate,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
