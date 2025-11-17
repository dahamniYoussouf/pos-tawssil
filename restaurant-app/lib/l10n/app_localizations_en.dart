// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'tawsil';

  @override
  String get welcome => 'Welcome';

  @override
  String get loginSubtitle =>
      'Log in with your email address and your store\'s password';

  @override
  String get emailAddress => 'Email address';

  @override
  String get emailAddressHint => 'Enter your email address';

  @override
  String get email => 'E-mail';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get login => 'Log in';

  @override
  String get termsAndConditions => 'By logging in, you accept our Terms of Use';

  @override
  String get becomePartner => 'Become a partner →';

  @override
  String get signUpTitle => 'Become a delivery driver -partner';

  @override
  String get signUpSubtitle =>
      'become a partner and manage your restaurant independently. Increase your visibility and your income thanks to tawsil';

  @override
  String get restaurantName => 'Restaurant name';

  @override
  String get restaurantNameHint => 'Enter your restaurant name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneNumberHint => 'Phone number';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmPasswordHint => 'Confirm your password';

  @override
  String get restaurantType => 'Choose restaurant type';

  @override
  String get restaurantTypeHint => 'Select type';

  @override
  String get willaya => 'Willaya';

  @override
  String get willayaHint => 'Select willaya';

  @override
  String get zone => 'Zone';

  @override
  String get zoneHint => 'Select zone';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'Tell customers about your restaurant';

  @override
  String get address => 'Address';

  @override
  String get addressHint => 'Enter the full address';

  @override
  String get locationSearchLabel => 'Restaurant location';

  @override
  String get locationSearchHint => 'Search by address or area';

  @override
  String get locationSearchButton => 'Search';

  @override
  String get locationLatitudeLabel => 'Latitude';

  @override
  String get locationLongitudeLabel => 'Longitude';

  @override
  String get signUp => 'Register';

  @override
  String get signUpTerms =>
      'By registering with tawsila you accept Terms of Use';

  @override
  String get errorEmailRequired => 'Email is required';

  @override
  String get errorPasswordRequired => 'Password is required';

  @override
  String get errorRestaurantNameRequired => 'Restaurant name is required';

  @override
  String get errorPhoneNumberRequired => 'Phone number is required';

  @override
  String get errorConfirmPasswordRequired => 'Please confirm your password';

  @override
  String get errorPasswordMismatch => 'Passwords do not match';

  @override
  String get errorRestaurantTypeRequired => 'Restaurant type is required';

  @override
  String get errorWillayaRequired => 'Willaya is required';

  @override
  String get errorZoneRequired => 'Zone is required';

  @override
  String get errorDescriptionRequired => 'Description is required';

  @override
  String get errorLocationRequired =>
      'Please search for the restaurant location';

  @override
  String get errorLocationNotFound => 'No matching location found';

  @override
  String get errorLocationLookupFailed => 'Unable to fetch location, try again';

  @override
  String get errorLoginFailed => 'Login failed';

  @override
  String get errorRegistrationFailed => 'Registration failed';

  @override
  String get errorLogoutFailed => 'Logout failed';

  @override
  String get home => 'Home';

  @override
  String get homeTitle => 'Your delivery starts here!';

  @override
  String get homeSubtitle =>
      'Receive your orders, follow addresses and offer exceptional service in record time.';

  @override
  String get getOrders => 'Get orders';

  @override
  String get orders => 'Orders';

  @override
  String orderTitle(String id) {
    return 'Order #$id';
  }

  @override
  String get orderNumberLabel => 'Order number';

  @override
  String get deliveryTime => 'Delivery time';

  @override
  String get minutes => 'MIN';

  @override
  String get distance => 'Distance';

  @override
  String get kilometers => 'KM';

  @override
  String get deliveryPrice => 'Delivery price';

  @override
  String get totalPrice => 'Total price';

  @override
  String get refuse => 'Refuse';

  @override
  String get accept => 'Accept';

  @override
  String get noOrders => 'No orders';

  @override
  String get noPendingOrders => 'You have no pending orders';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get orderAcceptedSuccess => 'Order accepted successfully';

  @override
  String get orderRefusedSuccess => 'Order refused successfully';

  @override
  String get errorInvalidResponseFormat => 'Invalid response format';

  @override
  String get errorFailedToFetchOrders => 'Failed to fetch orders';

  @override
  String get errorFailedToAcceptOrder => 'Failed to accept order';

  @override
  String errorAcceptingOrder(String error) {
    return 'Error accepting order: $error';
  }

  @override
  String get errorFailedToRefuseOrder => 'Failed to refuse order';

  @override
  String errorRefusingOrder(String error) {
    return 'Error refusing order: $error';
  }
}
