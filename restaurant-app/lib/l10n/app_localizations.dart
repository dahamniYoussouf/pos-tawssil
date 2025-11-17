import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'tawsil'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in with your email address and your store\'s password'**
  String get loginSubtitle;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @emailAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get emailAddressHint;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'By logging in, you accept our Terms of Use'**
  String get termsAndConditions;

  /// No description provided for @becomePartner.
  ///
  /// In en, this message translates to:
  /// **'Become a partner →'**
  String get becomePartner;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Become a delivery driver -partner'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'become a partner and manage your restaurant independently. Increase your visibility and your income thanks to tawsil'**
  String get signUpSubtitle;

  /// No description provided for @restaurantName.
  ///
  /// In en, this message translates to:
  /// **'Restaurant name'**
  String get restaurantName;

  /// No description provided for @restaurantNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your restaurant name'**
  String get restaurantNameHint;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberHint;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPasswordHint;

  /// No description provided for @restaurantType.
  ///
  /// In en, this message translates to:
  /// **'Choose restaurant type'**
  String get restaurantType;

  /// No description provided for @restaurantTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select type'**
  String get restaurantTypeHint;

  /// No description provided for @willaya.
  ///
  /// In en, this message translates to:
  /// **'Willaya'**
  String get willaya;

  /// No description provided for @willayaHint.
  ///
  /// In en, this message translates to:
  /// **'Select willaya'**
  String get willayaHint;

  /// No description provided for @zone.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zone;

  /// No description provided for @zoneHint.
  ///
  /// In en, this message translates to:
  /// **'Select zone'**
  String get zoneHint;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell customers about your restaurant'**
  String get descriptionHint;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @addressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the full address'**
  String get addressHint;

  /// No description provided for @locationSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Restaurant location'**
  String get locationSearchLabel;

  /// No description provided for @locationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by address or area'**
  String get locationSearchHint;

  /// No description provided for @locationSearchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get locationSearchButton;

  /// No description provided for @locationLatitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get locationLatitudeLabel;

  /// No description provided for @locationLongitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get locationLongitudeLabel;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get signUp;

  /// No description provided for @signUpTerms.
  ///
  /// In en, this message translates to:
  /// **'By registering with tawsila you accept Terms of Use'**
  String get signUpTerms;

  /// No description provided for @errorEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get errorEmailRequired;

  /// No description provided for @errorPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get errorPasswordRequired;

  /// No description provided for @errorRestaurantNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Restaurant name is required'**
  String get errorRestaurantNameRequired;

  /// No description provided for @errorPhoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get errorPhoneNumberRequired;

  /// No description provided for @errorConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get errorConfirmPasswordRequired;

  /// No description provided for @errorPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get errorPasswordMismatch;

  /// No description provided for @errorRestaurantTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Restaurant type is required'**
  String get errorRestaurantTypeRequired;

  /// No description provided for @errorWillayaRequired.
  ///
  /// In en, this message translates to:
  /// **'Willaya is required'**
  String get errorWillayaRequired;

  /// No description provided for @errorZoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Zone is required'**
  String get errorZoneRequired;

  /// No description provided for @errorDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get errorDescriptionRequired;

  /// No description provided for @errorLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please search for the restaurant location'**
  String get errorLocationRequired;

  /// No description provided for @errorLocationNotFound.
  ///
  /// In en, this message translates to:
  /// **'No matching location found'**
  String get errorLocationNotFound;

  /// No description provided for @errorLocationLookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch location, try again'**
  String get errorLocationLookupFailed;

  /// No description provided for @errorLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get errorLoginFailed;

  /// No description provided for @errorRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get errorRegistrationFailed;

  /// No description provided for @errorLogoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get errorLogoutFailed;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your delivery starts here!'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive your orders, follow addresses and offer exceptional service in record time.'**
  String get homeSubtitle;

  /// No description provided for @getOrders.
  ///
  /// In en, this message translates to:
  /// **'Get orders'**
  String get getOrders;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @orderTitle.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String orderTitle(String id);

  /// No description provided for @orderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Order number'**
  String get orderNumberLabel;

  /// No description provided for @deliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Delivery time'**
  String get deliveryTime;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'MIN'**
  String get minutes;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @kilometers.
  ///
  /// In en, this message translates to:
  /// **'KM'**
  String get kilometers;

  /// No description provided for @deliveryPrice.
  ///
  /// In en, this message translates to:
  /// **'Delivery price'**
  String get deliveryPrice;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total price'**
  String get totalPrice;

  /// No description provided for @refuse.
  ///
  /// In en, this message translates to:
  /// **'Refuse'**
  String get refuse;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @noOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders'**
  String get noOrders;

  /// No description provided for @noPendingOrders.
  ///
  /// In en, this message translates to:
  /// **'You have no pending orders'**
  String get noPendingOrders;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @orderAcceptedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order accepted successfully'**
  String get orderAcceptedSuccess;

  /// No description provided for @orderRefusedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order refused successfully'**
  String get orderRefusedSuccess;

  /// No description provided for @errorInvalidResponseFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid response format'**
  String get errorInvalidResponseFormat;

  /// No description provided for @errorFailedToFetchOrders.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch orders'**
  String get errorFailedToFetchOrders;

  /// No description provided for @errorFailedToAcceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept order'**
  String get errorFailedToAcceptOrder;

  /// No description provided for @errorAcceptingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error accepting order: {error}'**
  String errorAcceptingOrder(String error);

  /// No description provided for @errorFailedToRefuseOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to refuse order'**
  String get errorFailedToRefuseOrder;

  /// No description provided for @errorRefusingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error refusing order: {error}'**
  String errorRefusingOrder(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
