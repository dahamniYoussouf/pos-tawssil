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

  /// No description provided for @termsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By logging in, you accept our\n'**
  String get termsPrefix;

  /// No description provided for @termsLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms Of Use'**
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

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @signUpAction.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpAction;

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

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @ongoingStatus.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoingStatus;

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

  /// No description provided for @statisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTitle;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @appMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile App'**
  String get appMobile;

  /// No description provided for @pos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get pos;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @days7.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get days7;

  /// No description provided for @days30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get days30;

  /// No description provided for @commands.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get commands;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @totalRevenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenueLabel;

  /// No description provided for @seeDetails.
  ///
  /// In en, this message translates to:
  /// **'See Details'**
  String get seeDetails;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @seeAllReviews.
  ///
  /// In en, this message translates to:
  /// **'See All Reviews'**
  String get seeAllReviews;

  /// No description provided for @totalReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'Total {count} Reviews'**
  String totalReviewsCount(Object count);

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get statusLabel;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @delivering.
  ///
  /// In en, this message translates to:
  /// **'Delivering'**
  String get delivering;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @pickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked-up'**
  String get pickedUp;

  /// No description provided for @priceRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Price range:'**
  String get priceRangeLabel;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min (DA)'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max (DA)'**
  String get maxPrice;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @averageValue.
  ///
  /// In en, this message translates to:
  /// **'Average Value'**
  String get averageValue;

  /// No description provided for @deliveredOrders.
  ///
  /// In en, this message translates to:
  /// **'Delivered Orders'**
  String get deliveredOrders;

  /// No description provided for @ordersByStatus.
  ///
  /// In en, this message translates to:
  /// **'Orders by Status'**
  String get ordersByStatus;

  /// No description provided for @revenueByStatus.
  ///
  /// In en, this message translates to:
  /// **'Revenue by Status'**
  String get revenueByStatus;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @errorDateRangeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a date range'**
  String get errorDateRangeRequired;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @restaurantDetails.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Details'**
  String get restaurantDetails;

  /// No description provided for @restaurantInformation.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Information'**
  String get restaurantInformation;

  /// No description provided for @restaurantInfoPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your restaurant information will be displayed here'**
  String get restaurantInfoPlaceholder;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @createCategory.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get createCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @createMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Create Menu Item'**
  String get createMenuItem;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter category name'**
  String get categoryNameHint;

  /// No description provided for @categoryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Category name is required'**
  String get categoryNameRequired;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequired;

  /// No description provided for @iconUrl.
  ///
  /// In en, this message translates to:
  /// **'Icon URL'**
  String get iconUrl;

  /// No description provided for @iconUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Enter icon URL'**
  String get iconUrlHint;

  /// No description provided for @iconUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Icon URL is required'**
  String get iconUrlRequired;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL format'**
  String get invalidUrl;

  /// No description provided for @displayOrder.
  ///
  /// In en, this message translates to:
  /// **'Display Order'**
  String get displayOrder;

  /// No description provided for @displayOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Enter display order'**
  String get displayOrderHint;

  /// No description provided for @displayOrderRequired.
  ///
  /// In en, this message translates to:
  /// **'Display order is required'**
  String get displayOrderRequired;

  /// No description provided for @invalidDisplayOrder.
  ///
  /// In en, this message translates to:
  /// **'Display order must be a positive number'**
  String get invalidDisplayOrder;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this category?'**
  String get deleteCategoryConfirmation;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategories;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search here...'**
  String get searchHint;

  /// No description provided for @menuItems.
  ///
  /// In en, this message translates to:
  /// **'Menu Items'**
  String get menuItems;

  /// No description provided for @noMenuItems.
  ///
  /// In en, this message translates to:
  /// **'No menu items available'**
  String get noMenuItems;

  /// No description provided for @editMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Menu Item'**
  String get editMenuItem;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @itemNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter item name'**
  String get itemNameHint;

  /// No description provided for @itemNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Item name is required'**
  String get itemNameRequired;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @priceHint.
  ///
  /// In en, this message translates to:
  /// **'Enter price'**
  String get priceHint;

  /// No description provided for @priceRequired.
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get priceRequired;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Price must be a positive number'**
  String get invalidPrice;

  /// No description provided for @preparationTime.
  ///
  /// In en, this message translates to:
  /// **'Preparation Time (minutes)'**
  String get preparationTime;

  /// No description provided for @preparationTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter preparation time in minutes'**
  String get preparationTimeHint;

  /// No description provided for @preparationTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'Preparation time is required'**
  String get preparationTimeRequired;

  /// No description provided for @invalidPreparationTime.
  ///
  /// In en, this message translates to:
  /// **'Preparation time must be a positive number'**
  String get invalidPreparationTime;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @ingredientsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter ingredients (optional)'**
  String get ingredientsHint;

  /// No description provided for @allergens.
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get allergens;

  /// No description provided for @allergensHint.
  ///
  /// In en, this message translates to:
  /// **'Enter allergens (optional)'**
  String get allergensHint;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get categoryHint;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Category is required'**
  String get categoryRequired;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @imageUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get imageUploading;

  /// No description provided for @imageUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully'**
  String get imageUploadSuccess;

  /// No description provided for @imageUploadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get imageUploadError;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @deleteMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Menu Item'**
  String get deleteMenuItem;

  /// No description provided for @deleteMenuItemConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this menu item?'**
  String get deleteMenuItemConfirmation;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get noOrdersFound;

  /// No description provided for @noOrdersFoundWithFilters.
  ///
  /// In en, this message translates to:
  /// **'No orders found matching your filters'**
  String get noOrdersFoundWithFilters;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @orderTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Type'**
  String get orderTypeLabel;

  /// No description provided for @dateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRangeLabel;

  /// No description provided for @dateFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get dateFromLabel;

  /// No description provided for @dateToLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get dateToLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @deliveryOrderType.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliveryOrderType;

  /// No description provided for @pickupOrderType.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickupOrderType;

  /// No description provided for @unknownClient.
  ///
  /// In en, this message translates to:
  /// **'Unknown client'**
  String get unknownClient;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @manageProfile.
  ///
  /// In en, this message translates to:
  /// **'Manage Your Profile'**
  String get manageProfile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @printerSettings.
  ///
  /// In en, this message translates to:
  /// **'Printer Configuration'**
  String get printerSettings;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @openStatus.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openStatus;

  /// No description provided for @closedStatus.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedStatus;

  /// No description provided for @restaurantIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Restaurant ID : {id}'**
  String restaurantIdLabel(String id);

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @createCategoryFirst.
  ///
  /// In en, this message translates to:
  /// **'Please create a category first'**
  String get createCategoryFirst;

  /// No description provided for @uploadImageFirst.
  ///
  /// In en, this message translates to:
  /// **'Please upload the image first'**
  String get uploadImageFirst;

  /// No description provided for @errorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'Error picking image'**
  String get errorPickingImage;

  /// No description provided for @deliveryApp.
  ///
  /// In en, this message translates to:
  /// **'Delivery App'**
  String get deliveryApp;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @listOfCategories.
  ///
  /// In en, this message translates to:
  /// **'List of Categories'**
  String get listOfCategories;

  /// No description provided for @listOfProducts.
  ///
  /// In en, this message translates to:
  /// **'List of products'**
  String get listOfProducts;

  /// No description provided for @searchForStoreOrProducts.
  ///
  /// In en, this message translates to:
  /// **'Search for store or products'**
  String get searchForStoreOrProducts;

  /// No description provided for @articlesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} articles'**
  String articlesCount(int count);

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @orderContent.
  ///
  /// In en, this message translates to:
  /// **'Order Content'**
  String get orderContent;

  /// No description provided for @paymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment Type'**
  String get paymentType;

  /// No description provided for @initialPrice.
  ///
  /// In en, this message translates to:
  /// **'Initial Price'**
  String get initialPrice;

  /// No description provided for @deliveryManMustPay.
  ///
  /// In en, this message translates to:
  /// **'Delivery Man Must Pay'**
  String get deliveryManMustPay;

  /// No description provided for @receivedOrder.
  ///
  /// In en, this message translates to:
  /// **'Order Received'**
  String get receivedOrder;

  /// No description provided for @acceptedByDelivery.
  ///
  /// In en, this message translates to:
  /// **'Accepted by Delivery Driver'**
  String get acceptedByDelivery;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Ticket'**
  String get printReceipt;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @statusOpenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accepting orders'**
  String get statusOpenSubtitle;

  /// No description provided for @statusClosedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Closed all day'**
  String get statusClosedSubtitle;

  /// No description provided for @statusVacation.
  ///
  /// In en, this message translates to:
  /// **'On Vacation'**
  String get statusVacation;

  /// No description provided for @statusSaturated.
  ///
  /// In en, this message translates to:
  /// **'Saturated'**
  String get statusSaturated;

  /// No description provided for @statusOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get statusOther;

  /// No description provided for @statusVacationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Closed for vacation'**
  String get statusVacationSubtitle;

  /// No description provided for @statusSaturatedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Too many orders'**
  String get statusSaturatedSubtitle;

  /// No description provided for @statusOtherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Specify a reason'**
  String get statusOtherSubtitle;

  /// No description provided for @availabilityNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the reason...'**
  String get availabilityNoteHint;

  /// No description provided for @closeRestaurantTitle.
  ///
  /// In en, this message translates to:
  /// **'Close your store for'**
  String get closeRestaurantTitle;

  /// No description provided for @restaurantProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Profile'**
  String get restaurantProfileTitle;

  /// No description provided for @establishmentInformation.
  ///
  /// In en, this message translates to:
  /// **'Establishment Information'**
  String get establishmentInformation;

  /// No description provided for @openingHours.
  ///
  /// In en, this message translates to:
  /// **'Opening Hours'**
  String get openingHours;

  /// No description provided for @categoriesYouOffer.
  ///
  /// In en, this message translates to:
  /// **'Categories You Offer'**
  String get categoriesYouOffer;

  /// No description provided for @vitrinePhoto.
  ///
  /// In en, this message translates to:
  /// **'Storefront Photo'**
  String get vitrinePhoto;

  /// No description provided for @updatePhoto.
  ///
  /// In en, this message translates to:
  /// **'Update Photo'**
  String get updatePhoto;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @approvedStatus.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvedStatus;

  /// No description provided for @addressMini.
  ///
  /// In en, this message translates to:
  /// **'ADDRESS'**
  String get addressMini;

  /// No description provided for @phoneMini.
  ///
  /// In en, this message translates to:
  /// **'PHONE'**
  String get phoneMini;

  /// No description provided for @emailMini.
  ///
  /// In en, this message translates to:
  /// **'EMAIL'**
  String get emailMini;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @modifier.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get modifier;

  /// No description provided for @gerer.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get gerer;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @optionGroupTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get optionGroupTitleEdit;

  /// No description provided for @optionGroupTitleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Group'**
  String get optionGroupTitleAdd;

  /// No description provided for @optionGroupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name *'**
  String get optionGroupNameLabel;

  /// No description provided for @optionGroupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter group name'**
  String get optionGroupNameHint;

  /// No description provided for @optionGroupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get optionGroupNameRequired;

  /// No description provided for @optionGroupRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get optionGroupRequired;

  /// No description provided for @optionGroupOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionGroupOptional;

  /// No description provided for @optionGroupMultipleChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple choice'**
  String get optionGroupMultipleChoice;

  /// No description provided for @multipleChoice.
  ///
  /// In en, this message translates to:
  /// **'Multiple'**
  String get multipleChoice;

  /// No description provided for @optionGroupOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionGroupOptions;

  /// No description provided for @optionOptionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Option name'**
  String get optionOptionNameLabel;

  /// No description provided for @optionAdd.
  ///
  /// In en, this message translates to:
  /// **'+ Add option'**
  String get optionAdd;

  /// No description provided for @optionGroupButtonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get optionGroupButtonSave;

  /// No description provided for @optionGroupButtonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get optionGroupButtonAdd;

  /// No description provided for @optionGroupDeleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get optionGroupDeleteGroup;

  /// No description provided for @optionGroupDeleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this option group?'**
  String get optionGroupDeleteConfirmation;

  /// No description provided for @optionGroupDeleteOptionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove option'**
  String get optionGroupDeleteOptionTooltip;

  /// No description provided for @errorOptionGroupAddOne.
  ///
  /// In en, this message translates to:
  /// **'Add at least one option'**
  String get errorOptionGroupAddOne;

  /// No description provided for @option.
  ///
  /// In en, this message translates to:
  /// **'option'**
  String get option;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'options'**
  String get options;

  /// No description provided for @singleChoice.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get singleChoice;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @fromGalleryOrCamera.
  ///
  /// In en, this message translates to:
  /// **'From gallery or camera'**
  String get fromGalleryOrCamera;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @itemActive.
  ///
  /// In en, this message translates to:
  /// **'Item Active'**
  String get itemActive;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addMenuItem;

  /// No description provided for @itemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemNameLabel;

  /// No description provided for @optionGroups.
  ///
  /// In en, this message translates to:
  /// **'Option Groups'**
  String get optionGroups;

  /// No description provided for @addOptionGroup.
  ///
  /// In en, this message translates to:
  /// **'+ Add option group'**
  String get addOptionGroup;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;
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
