import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/features/home/pages/home_page.dart';

class DeclinedOrderWidget extends StatelessWidget {
  final String? refusalReason;

  const DeclinedOrderWidget({
    super.key,
    this.refusalReason,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: ColorApp.redColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cancel_outlined,
                    size: 64,
                    color: ColorApp.redColor,
                  ),
                ),
                const SizedBox(height: 32),
                // Title
                Text(
                  localization.orderDeclinedByRestaurant,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ColorApp.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Message
                Text(
                  localization.orderDeclinedMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: ColorApp.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Show refusal reason if available
                if (refusalReason != null && refusalReason!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorApp.orangeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ColorApp.orangeColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.info_outline,
                          color: ColorApp.orangeColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            refusalReason!,
                            style: TextStyle(
                              fontSize: 14,
                              color: ColorApp.black,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorApp.primary,
                      foregroundColor: ColorApp.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      localization.close,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

