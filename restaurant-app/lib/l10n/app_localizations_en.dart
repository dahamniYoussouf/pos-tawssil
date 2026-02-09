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
  String get termsPrefix => 'By logging in, you accept our\n';

  @override
  String get termsLabel => 'Terms Of Use';

  @override
  String get termsAnd => ' and ';

  @override
  String get privacyPolicyLabel => 'Privacy Policy';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get signUpAction => 'Sign up';

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
  String get descriptionHint => 'Enter description';

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

  @override
  String get statisticsTitle => 'Statistics';

  @override
  String get statistics => 'Statistics';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get custom => 'Custom';

  @override
  String get reset => 'Reset';

  @override
  String get apply => 'Apply';

  @override
  String get statusLabel => 'Status:';

  @override
  String get all => 'All';

  @override
  String get accepted => 'Accepted';

  @override
  String get preparing => 'Preparing';

  @override
  String get delivering => 'Delivering';

  @override
  String get delivered => 'Delivered';

  @override
  String get pickedUp => 'Picked-up';

  @override
  String get priceRangeLabel => 'Price range:';

  @override
  String get minPrice => 'Min (DA)';

  @override
  String get maxPrice => 'Max (DA)';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get averageValue => 'Average Value';

  @override
  String get deliveredOrders => 'Delivered Orders';

  @override
  String get ordersByStatus => 'Orders by Status';

  @override
  String get revenueByStatus => 'Revenue by Status';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get errorDateRangeRequired => 'Please select a date range';

  @override
  String get logout => 'Logout';

  @override
  String get restaurantDetails => 'Restaurant Details';

  @override
  String get restaurantInformation => 'Restaurant Information';

  @override
  String get restaurantInfoPlaceholder =>
      'Your restaurant information will be displayed here';

  @override
  String get categories => 'Categories';

  @override
  String get createCategory => 'Create Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get createMenuItem => 'Create Menu Item';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryNameHint => 'Enter category name';

  @override
  String get categoryNameRequired => 'Category name is required';

  @override
  String get descriptionRequired => 'Description is required';

  @override
  String get iconUrl => 'Icon URL';

  @override
  String get iconUrlHint => 'Enter icon URL';

  @override
  String get iconUrlRequired => 'Icon URL is required';

  @override
  String get invalidUrl => 'Invalid URL format';

  @override
  String get displayOrder => 'Display Order';

  @override
  String get displayOrderHint => 'Enter display order';

  @override
  String get displayOrderRequired => 'Display order is required';

  @override
  String get invalidDisplayOrder => 'Display order must be a positive number';

  @override
  String get create => 'Create';

  @override
  String get update => 'Update';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get deleteCategoryConfirmation =>
      'Are you sure you want to delete this category?';

  @override
  String get noCategories => 'No categories available';

  @override
  String get searchHint => 'Search here...';

  @override
  String get menuItems => 'Menu Items';

  @override
  String get noMenuItems => 'No menu items available';

  @override
  String get editMenuItem => 'Edit Menu Item';

  @override
  String get itemName => 'Item Name';

  @override
  String get itemNameHint => 'Enter item name';

  @override
  String get itemNameRequired => 'Item name is required';

  @override
  String get price => 'Price';

  @override
  String get priceHint => 'Enter price';

  @override
  String get priceRequired => 'Price is required';

  @override
  String get invalidPrice => 'Price must be a positive number';

  @override
  String get preparationTime => 'Preparation Time (minutes)';

  @override
  String get preparationTimeHint => 'Enter preparation time in minutes';

  @override
  String get preparationTimeRequired => 'Preparation time is required';

  @override
  String get invalidPreparationTime =>
      'Preparation time must be a positive number';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get ingredientsHint => 'Enter ingredients (optional)';

  @override
  String get allergens => 'Allergens';

  @override
  String get allergensHint => 'Enter allergens (optional)';

  @override
  String get category => 'Category';

  @override
  String get categoryHint => 'Select category';

  @override
  String get categoryRequired => 'Category is required';

  @override
  String get selectImage => 'Select Image';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get imageUploading => 'Uploading image...';

  @override
  String get imageUploadSuccess => 'Image uploaded successfully';

  @override
  String get imageUploadError => 'Failed to upload image';

  @override
  String get available => 'Available';

  @override
  String get deleteMenuItem => 'Delete Menu Item';

  @override
  String get deleteMenuItemConfirmation =>
      'Are you sure you want to delete this menu item?';

  @override
  String get orderHistory => 'Order History';

  @override
  String get noOrdersFound => 'No orders found';

  @override
  String get noOrdersFoundWithFilters =>
      'No orders found matching your filters';

  @override
  String get filters => 'Filters';

  @override
  String get orderTypeLabel => 'Order Type';

  @override
  String get dateRangeLabel => 'Date Range';

  @override
  String get dateFromLabel => 'From';

  @override
  String get dateToLabel => 'To';

  @override
  String get priceLabel => 'Price';

  @override
  String get deliveryOrderType => 'Delivery';

  @override
  String get pickupOrderType => 'Pickup';

  @override
  String get unknownClient => 'Unknown client';

  @override
  String get details => 'Details';

  @override
  String get contact => 'Contact';
}
