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

  /// No description provided for @termsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By logging in, you accept our\n'**
  String get termsPrefix;

  /// No description provided for @termsLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsLabel;

  /// No description provided for @termsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get termsAnd;

  /// No description provided for @privacyPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyLabel;

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

  /// Cancel reason: technical issue
  ///
  /// In en, this message translates to:
  /// **'Technical problem with the order'**
  String get cancelReasonTechnicalIssue;

  /// No description provided for @confirmDelivery.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delivery'**
  String get confirmDelivery;

  /// No description provided for @confirmDeliveryMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to confirm the delivery and finish this order?'**
  String get confirmDeliveryMessage;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

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

  /// Delivery label
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// Restaurant label
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// Minutes abbreviation
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// Task details label
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get taskDetails;

  /// Arrive button text
  ///
  /// In en, this message translates to:
  /// **'Arrive'**
  String get arrive;

  /// Delivered button text
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Cancel order question
  ///
  /// In en, this message translates to:
  /// **'Why do you wish to cancel this order?'**
  String get cancelOrderQuestion;

  /// Cancel reason: driver late
  ///
  /// In en, this message translates to:
  /// **'The delivery person took too long to arrive'**
  String get cancelReasonDriverLate;

  /// Cancel reason: client canceled
  ///
  /// In en, this message translates to:
  /// **'The client canceled their order'**
  String get cancelReasonClientCanceled;

  /// Cancel reason: other
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get cancelReasonOther;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Order not found message
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// Client order page title
  ///
  /// In en, this message translates to:
  /// **'Client order'**
  String get clientOrderTitle;

  /// Total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Client label
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get clientLabel;

  /// Start delivery button text
  ///
  /// In en, this message translates to:
  /// **'Start delivery'**
  String get startDelivery;

  /// Profile page title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// My Promotions menu item
  ///
  /// In en, this message translates to:
  /// **'My Promotions'**
  String get myPromotions;

  /// Payment Methods menu item
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// Messages menu item
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Invite Friends menu item
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// Security menu item
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Manage Account menu item
  ///
  /// In en, this message translates to:
  /// **'Manage Your Account'**
  String get manageAccount;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Rating label
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// Deliveries label
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @yearsJoined.
  ///
  /// In en, this message translates to:
  /// **'Years Joined'**
  String get yearsJoined;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmation;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Order history page title
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// All filter label
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Ongoing status label
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get statusOngoing;

  /// Delivered status label
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// Cancelled status label
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No orders yet message
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// Start ordering now message
  ///
  /// In en, this message translates to:
  /// **'Start ordering now'**
  String get startOrderingNow;

  /// Today label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// Yesterday label
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayLabel;

  /// Details label
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Track order button text
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackOrder;

  /// From label
  ///
  /// In en, this message translates to:
  /// **'from:'**
  String get from;

  /// To label
  ///
  /// In en, this message translates to:
  /// **'to:'**
  String get to;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @newOrderAvailable.
  ///
  /// In en, this message translates to:
  /// **'NEW ORDER AVAILABLE'**
  String get newOrderAvailable;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @orderDetailsHeader.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetailsHeader;

  /// Remember me checkbox label
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// Forgot password button label
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Delivery address section header
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddressHeader;

  /// Delivery time section header
  ///
  /// In en, this message translates to:
  /// **'Delivery Time'**
  String get deliveryTimeHeader;

  /// Order number section header
  ///
  /// In en, this message translates to:
  /// **'Order Number'**
  String get orderNumberHeader;

  /// Payment method section header
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethodHeader;

  /// Cash payment method
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashPayment;

  /// Radar button text
  ///
  /// In en, this message translates to:
  /// **'Traffic Radar'**
  String get radarButton;

  /// Don't have account text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account yet? '**
  String get dontHaveAccount;

  /// Sign up action link
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpAction;

  /// Language label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Select language dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Arabic language
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// French language
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// English language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Cancellation modal title
  ///
  /// In en, this message translates to:
  /// **'Why do you want to cancel this order?'**
  String get cancelModalTitle;

  /// Cancellation modal subtitle
  ///
  /// In en, this message translates to:
  /// **'Help us improve your experience.'**
  String get cancelModalSubtitle;

  /// Hint for other reason text field
  ///
  /// In en, this message translates to:
  /// **'Enter your reason here...'**
  String get otherReasonHint;

  /// Confirm cancellation button
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancellation'**
  String get confirmCancellation;

  /// Back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @acceptDelivery.
  ///
  /// In en, this message translates to:
  /// **'Accept delivery'**
  String get acceptDelivery;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'DA'**
  String get currency;

  /// No description provided for @deliveryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Delivery Completed!'**
  String get deliveryCompleted;

  /// No description provided for @greatJobToday.
  ///
  /// In en, this message translates to:
  /// **'Great Job Today!'**
  String get greatJobToday;

  /// No description provided for @tripEarnings.
  ///
  /// In en, this message translates to:
  /// **'Trip Earnings'**
  String get tripEarnings;

  /// No description provided for @sessionTotal.
  ///
  /// In en, this message translates to:
  /// **'Session Total'**
  String get sessionTotal;

  /// No description provided for @routeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Route completed'**
  String get routeCompleted;

  /// No description provided for @backToRadar.
  ///
  /// In en, this message translates to:
  /// **'Back to Radar'**
  String get backToRadar;
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
