import 'package:frontend/l10n/app_localizations.dart';

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

    // Check if it's a known translation key
    if (_isTranslationKey(errorMessage)) {
      return _translateKey(errorMessage);
    }

    // If it's not a translation key (e.g., server error message), return as-is
    return errorMessage;
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
            message == 'errorProfileUpdateFailed');
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
      default:
        return '$key: $dynamicValue';
    }
  }
}
