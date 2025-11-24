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
      'Log in to your Rider account with your credentials.';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'Enter your identifier';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get login => 'Connect';

  @override
  String get termsAndConditions => 'By logging in, you accept our Terms of Use';

  @override
  String get becomePartner => 'Become a delivery partner →';

  @override
  String get signUpTitle => 'Become a delivery partner';

  @override
  String get signUpSubtitle =>
      'Deliver with Tawsila, it\'s managing your activity autonomously and increasing your income thanks to the market-leading application.';

  @override
  String get firstName => 'First Name';

  @override
  String get firstNameHint => 'Enter your first name';

  @override
  String get lastName => 'Name';

  @override
  String get lastNameHint => 'Enter your name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneNumberHint => 'Phone number';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Enter your Email';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmPasswordHint => 'Confirm your password';

  @override
  String get willaya => 'Willaya';

  @override
  String get zone => 'Zone';

  @override
  String get signUp => 'Sign up';

  @override
  String get signUpTerms => 'By signing up for tawsila you accept Terms of Use';

  @override
  String get errorUsernameRequired => 'Username is required';

  @override
  String get errorPasswordRequired => 'Password is required';

  @override
  String get errorFirstNameRequired => 'First name is required';

  @override
  String get errorLastNameRequired => 'Last name is required';

  @override
  String get errorPhoneNumberRequired => 'Phone number is required';

  @override
  String get errorEmailRequired => 'Email is required';

  @override
  String get errorConfirmPasswordRequired => 'Please confirm your password';

  @override
  String get errorPasswordMismatch => 'Passwords do not match';

  @override
  String get errorWillayaRequired => 'Willaya is required';

  @override
  String get errorZoneRequired => 'Zone is required';

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

  @override
  String get delivery => 'Delivery';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get minutesShort => 'min';

  @override
  String get taskDetails => 'Task Details';

  @override
  String get arrive => 'Arrive';

  @override
  String get delivered => 'Delivered';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelOrderQuestion => 'Why do you wish to cancel this order?';

  @override
  String get cancelReasonDriverLate =>
      'The delivery person took too long to arrive';

  @override
  String get cancelReasonClientCanceled => 'The client canceled their order';

  @override
  String get cancelReasonTechnicalIssue => 'Technical problem with the order';

  @override
  String get cancelReasonOther => 'Other reason';

  @override
  String get confirm => 'Confirm';

  @override
  String get orderNotFound => 'Order not found';

  @override
  String get clientOrderTitle => 'Client order';

  @override
  String get total => 'Total';

  @override
  String get clientLabel => 'Client';

  @override
  String get startDelivery => 'Start delivery';
}
