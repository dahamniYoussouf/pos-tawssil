import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/core/res/media_res.dart';
import 'package:delivery_app/src/features/orders/pages/track_orders_page.dart';
import 'package:flutter/material.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
        backgroundColor: AppColors.white,
        body: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(height: 32),
                Center(
                  child: Image.asset(
                    MediaRes.logo,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  localizations.homeTitle,
                  style: TextStyle(color: AppColors.primaryColor, fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  localizations.homeSubtitle,
                  style: TextStyle(color: AppColors.black, fontSize: 14),
                ),
              ],
            )),
        bottomNavigationBar: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TrackOrdersPage(),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryColor, borderRadius: BorderRadius.circular(12)),
            child: Text(
              localizations.getOrders,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.black, fontSize: 16),
            ),
          ),
        ));
  }
}
