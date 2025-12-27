import 'package:client_app/l10n/app_localizations.dart';

extension AppLocalizationsErrorExtension on AppLocalizations {
  /// Translates error messages from the cubit
  /// Handles both simple translation keys and keys with dynamic content (format: "key|value")
  String translateErrorMessage(String errorMessage) {
    // Check if it's a translation key with dynamic content (format: "key|value")
    if (errorMessage.contains('|')) {
      final parts = errorMessage.split('|');
      if (parts.length == 2) {
        final key = parts[0];
        final dynamicValue = parts[1];
        return _translateWithDynamicValue(key, dynamicValue);
      }
    }

    // Check for specific API error messages that need translation
    if (_isKnownApiErrorMessage(errorMessage)) {
      return _translateApiErrorMessage(errorMessage);
    }

    // Check if it's a known translation key
    if (_isTranslationKey(errorMessage)) {
      return _translateKey(errorMessage);
    }

    // If it's not a translation key (e.g., server error message), return as-is
    return errorMessage;
  }

  bool _isKnownApiErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();
    return (lowerMessage.contains('maximum') &&
            lowerMessage.contains('adresses favorites')) ||
        (lowerMessage.contains('maximum') &&
            lowerMessage.contains('favorite addresses'));
  }

  String _translateApiErrorMessage(String message) {
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('maximum') &&
        (lowerMessage.contains('adresses favorites') ||
            lowerMessage.contains('favorite addresses'))) {
      return errorMaxFavoriteAddressesReached;
    }
    return message;
  }

  bool _isTranslationKey(String message) {
    return message.startsWith('error') &&
        (message == 'errorPhoneNumberRequired' ||
            message == 'errorPhoneNumberInvalid' ||
            message == 'errorPhoneNumberMinLength' ||
            message == 'errorCodeSendFailed' ||
            message == 'errorCodeLength' ||
            message == 'errorCodeInvalid' ||
            message == 'errorFirstNameRequired' ||
            message == 'errorLastNameRequired' ||
            message == 'errorProfileUpdateFailed' ||
            message == 'errorProfileFetchFailed' ||
            message == 'errorMaxFavoriteAddressesReached');
  }

  String _translateKey(String key) {
    switch (key) {
      case 'errorPhoneNumberRequired':
        return errorPhoneNumberRequired;
      case 'errorPhoneNumberInvalid':
        return errorPhoneNumberInvalid;
      case 'errorPhoneNumberMinLength':
        return errorPhoneNumberMinLength;
      case 'errorCodeSendFailed':
        return errorCodeSendFailed;
      case 'errorCodeLength':
        return errorCodeLength;
      case 'errorCodeInvalid':
        return errorCodeInvalid;
      case 'errorFirstNameRequired':
        return errorFirstNameRequired;
      case 'errorLastNameRequired':
        return errorLastNameRequired;
      case 'errorProfileUpdateFailed':
        return errorProfileUpdateFailed;
      case 'errorProfileFetchFailed':
        return errorProfileFetchFailed;
      case 'errorMaxFavoriteAddressesReached':
        return errorMaxFavoriteAddressesReached;
      default:
        return key;
    }
  }

  String _translateWithDynamicValue(String key, String dynamicValue) {
    switch (key) {
      case 'errorConnection':
        return errorConnection(dynamicValue);
      case 'errorVerification':
        return errorVerification(dynamicValue);
      case 'errorProfileUpdate':
        return errorProfileUpdate(dynamicValue);
      case 'errorProfileFetch':
        return errorProfileFetch(dynamicValue);
      case 'errorCategoriesLoading':
        return errorCategoriesLoadingFailed;
      case 'errorRestaurantsLoading':
        return errorRestaurantsLoadingFailed;
      case 'errorRestaurantsSearch':
        return errorRestaurantsSearchFailed;
      case 'errorRestaurantDetailsLoading':
        return errorRestaurantDetailsLoadingFailed;
      case 'errorRestaurantsFilterByCategory':
        return errorRestaurantsFilterByCategoryFailed;
      default:
        return '$key: $dynamicValue';
    }
  }
}
