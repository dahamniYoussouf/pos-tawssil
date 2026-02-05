import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/app_theme.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/core/res/media_res.dart';
import 'package:delivery_app/src/features/home/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DeliverySuccessPage extends StatelessWidget {
  final double tripEarnings;
  final double distance;
  final int orderCount;
  final double sessionTotal;

  const DeliverySuccessPage({
    super.key,
    this.tripEarnings = 350.0,
    this.distance = 4.2,
    this.orderCount = 3,
    this.sessionTotal = 2400.0,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Image.asset(
          MediaRes.logo,
          height: 38,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 2),
              // Success Icon Area
              Center(
                child: Container(
                  child: Center(
                    child: SvgPicture.asset(
                      MediaRes.successIcon,
                      width: 84,
                      height: 84,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                localizations.deliveryCompleted,
                style: AppTextStyles.gilmerBold.copyWith(
                  fontSize: 28,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                localizations.greatJobToday,
                style: AppTextStyles.gilmerMedium.copyWith(
                  fontSize: 16,
                  color: Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              //  Card
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      localizations.tripEarnings,
                      style: AppTextStyles.gilmerMedium.copyWith(
                        fontSize: 16,
                        color: Colors.white38,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "+${tripEarnings.toInt()} ${localizations.currency}",
                      style: AppTextStyles.gilmerBold.copyWith(
                        fontSize: 52,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBadge("${orderCount} ${localizations.orders}",
                            const Color(0xFF07A26F)),
                        const SizedBox(width: 12),
                        _buildBadge("${distance} KM", AppColors.primaryBlue),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.darkCard.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.sessionTotal,
                      style: AppTextStyles.gilmerMedium.copyWith(
                        fontSize: 15,
                        color: Colors.white38,
                      ),
                    ),
                    Text(
                      "${sessionTotal.toInt()} ${localizations.currency}",
                      style: AppTextStyles.gilmerBold.copyWith(
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Map Image Area
              ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      MediaRes.mapImage,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                    // hna Itineraire termine
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(
                        localizations.routeCompleted,
                        style: AppTextStyles.gilmerBold.copyWith(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    localizations.backToRadar,
                    style: AppTextStyles.gilmerBold.copyWith(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: AppTextStyles.gilmerBold.copyWith(
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}
