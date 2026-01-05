import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';

class PremiumBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const PremiumBanner({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ColorApp.premiumBannerGradientStart,
              ColorApp.premiumBannerGradientEnd
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '${AppLocalizations.of(context)!.switchToPremium} ',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        TextSpan(
                          text: AppLocalizations.of(context)!.premium,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: ColorApp.premiumColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.moreServices,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Image.asset(MediaRes.promoImage)),
          ],
        ),
      ),
    );
  }
}
