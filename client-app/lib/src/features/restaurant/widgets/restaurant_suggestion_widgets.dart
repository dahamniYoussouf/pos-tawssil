import 'package:flutter/material.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/res/color_app.dart';

class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: ColorApp.primary),
          SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.loadingRestaurants),
        ],
      ),
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    Key? key,
    required this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: ColorApp.redColor),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.error,
            style: TextStyle(color: ColorApp.redColor),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)!.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorApp.primary,
              foregroundColor: ColorApp.white,
            ),
          ),
        ],
      ),
    );
  }
}

