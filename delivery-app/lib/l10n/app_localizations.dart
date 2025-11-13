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

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'tawsil'**
  String get appTitle;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Login page subtitle
  ///
  /// In en, this message translates to:
  /// **'Log in to your Rider account with your credentials.'**
  String get loginSubtitle;

  /// Username label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Username input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your identifier'**
  String get usernameHint;

  /// Password label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get login;

  /// Terms and conditions text
  ///
  /// In en, this message translates to:
  /// **'By logging in, you accept our Terms of Use'**
  String get termsAndConditions;

  /// Become partner link
  ///
  /// In en, this message translates to:
  /// **'Become a delivery partner →'**
  String get becomePartner;

  /// Sign up page title
  ///
  /// In en, this message translates to:
  /// **'Become a delivery partner'**
  String get signUpTitle;

  /// Sign up page subtitle
  ///
  /// In en, this message translates to:
  /// **'Deliver with Tawsila, it\'s managing your activity autonomously and increasing your income thanks to the market-leading application.'**
  String get signUpSubtitle;

  /// First name label
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// First name input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get firstNameHint;

  /// Last name label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get lastName;

  /// Last name input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get lastNameHint;

  /// Phone number label
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// Phone number input hint
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberHint;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Email input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your Email'**
  String get emailHint;

  /// Confirm password label
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// Confirm password input hint
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmPasswordHint;

  /// Willaya label
  ///
  /// In en, this message translates to:
  /// **'Willaya'**
  String get willaya;

  /// Zone label
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zone;

  /// Sign up button text
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// Sign up terms text
  ///
  /// In en, this message translates to:
  /// **'By signing up for tawsila you accept Terms of Use'**
  String get signUpTerms;

  /// Username required error
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get errorUsernameRequired;

  /// Password required error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get errorPasswordRequired;

  /// First name required error
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get errorFirstNameRequired;

  /// Last name required error
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get errorLastNameRequired;

  /// Phone number required error
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get errorPhoneNumberRequired;

  /// Email required error
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get errorEmailRequired;

  /// Confirm password required error
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get errorConfirmPasswordRequired;

  /// Password mismatch error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get errorPasswordMismatch;

  /// Willaya required error
  ///
  /// In en, this message translates to:
  /// **'Willaya is required'**
  String get errorWillayaRequired;

  /// Zone required error
  ///
  /// In en, this message translates to:
  /// **'Zone is required'**
  String get errorZoneRequired;

  /// Login failed error
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get errorLoginFailed;

  /// Registration failed error
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get errorRegistrationFailed;

  /// Logout failed error
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get errorLogoutFailed;

  /// Home page title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;
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
