import 'package:flutter/material.dart';
import 'package:restaurant_app/src/core/res/color_app.dart';

/// Base theme class for order history widgets
abstract class OrderHistoryTheme {
  static const Color primaryColor = AppColors.primaryColor;
  static const Color backgroundColor = AppColors.white;
  static const Color cardBackgroundColor = AppColors.white;
  static const Color textColor = AppColors.black;
  static const Color greyColor = AppColors.grey;
  static const Color greyLightColor = AppColors.greyLight;
  static const Color borderColor = AppColors.greyLight;
}

/// Search bar theme
class OrderHistorySearchTheme extends OrderHistoryTheme {
  static const double borderRadius = 8.0;
  static const double borderWidth = 1.0;
  static const EdgeInsets padding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const Color borderColor = AppColors.primaryColor;
  static const Color iconColor = AppColors.primaryColor;
}

/// Order card theme
class OrderHistoryCardTheme extends OrderHistoryTheme {
  static const double borderRadius = 8.0;
  static const double borderWidth = 1.0;
  static const EdgeInsets margin =
      EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const EdgeInsets padding = EdgeInsets.all(16);
  static const Color borderColor = AppColors.greyLight;
  static const Color shadowColor = Colors.black12;
  static const double elevation = 2.0;
}

/// Status badge theme
class OrderHistoryStatusTheme extends OrderHistoryTheme {
  static const double borderRadius = 4.0;
  static const EdgeInsets padding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  static const TextStyle textStyle = TextStyle(
    color: AppColors.white,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'accepté':
        return const Color(0xFF4CAF50); // Green
      case 'declined':
      case 'annulé':
        return const Color(0xFFE57373); // Light red/pink
      case 'delivered':
      case 'livrer':
        return const Color(0xFFFFB74D); // Light yellow/orange
      case 'preparing':
      case 'en préparation':
        return const Color(0xFF42A5F5); // Blue
      case 'assigned':
      case 'assigné':
        return const Color(0xFF9C27B0); // Purple
      case 'pending':
      case 'en attente':
        return const Color(0xFFFFA726); // Orange
      case 'delivering':
      case 'en livraison':
        return const Color(0xFF26A69A); // Teal
      default:
        return AppColors.grey;
    }
  }
}

/// Header theme
class OrderHistoryHeaderTheme extends OrderHistoryTheme {
  static const TextStyle titleStyle = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  static const double iconSize = 24.0;
  static const Color iconColor = AppColors.primaryColor;
}
