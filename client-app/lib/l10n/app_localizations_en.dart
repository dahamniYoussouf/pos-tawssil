// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tawsil';

  @override
  String get addPhoneNumber => 'Add your phone number';

  @override
  String get phoneNumberSubtitle =>
      'To log in or sign up, enter your phone number.';

  @override
  String get phoneNumberHint => 'Phone number';

  @override
  String get connect => 'Connect';

  @override
  String get home => 'Home';

  @override
  String get favorites => 'Favorites';

  @override
  String get history => 'History';

  @override
  String get cart => 'Cart';

  @override
  String get profile => 'Profile';

  @override
  String get cartTitle => 'Cart';

  @override
  String get orderSummary => 'Order summary';

  @override
  String get addItem => 'Add item';

  @override
  String get deliveryAddress => 'Delivery address';

  @override
  String products(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Products',
      one: 'Product',
      zero: 'Products',
    );
    return '$_temp0';
  }

  @override
  String get deliveryFee => 'Delivery fee';

  @override
  String get estimatedTime => 'Estimated time';

  @override
  String get estimatedDeliveryTime => 'Estimated delivery time';

  @override
  String get orderDetails => 'Order details';

  @override
  String get orderOverview => 'Order Overview';

  @override
  String get orderValidationTitle => 'Your order is almost ready to be sent';

  @override
  String get orderValidationDescription =>
      'Please verify the information below before confirming. Once validated, preparation will start immediately.';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get platformFee => 'Platform fee';

  @override
  String get total => 'Total';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get cash => 'Cash';

  @override
  String get baridiMob => 'Baridi Mob';

  @override
  String get bankTransfer => 'Bank transfer';

  @override
  String get deliveryOption => 'Delivery option';

  @override
  String get pickup => 'Pickup';

  @override
  String get delivery => 'Delivery';

  @override
  String get verifyAndFinalize => 'Verify and Finalize';

  @override
  String get emptyCart => 'Your cart is empty';

  @override
  String get addProductsToContinue => 'Add products to continue';

  @override
  String get removeProduct => 'Remove product';

  @override
  String removeProductConfirmation(String productName) {
    return 'Do you want to remove \"$productName\" from the cart?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get note => 'Note';

  @override
  String get enterAddress => 'Enter an address';

  @override
  String get addressHint => 'Ex: 123 Republic Street, Algiers';

  @override
  String get confirm => 'Confirm';

  @override
  String get permissionDenied =>
      'You have denied permission. Enable location in settings.';

  @override
  String get gpsTimeout => 'Unable to retrieve GPS location (timeout).';

  @override
  String get gpsError => 'Unable to retrieve GPS location.';

  @override
  String get locationSendError =>
      'Error sending location. Check your connection.';

  @override
  String get addressSendError =>
      'Error sending address. Check your connection.';

  @override
  String get error => 'Error';

  @override
  String get loadingError => 'Loading error';

  @override
  String get gpsDisabled => 'Location services disabled';

  @override
  String get gpsDisabledMessage =>
      'Please enable GPS to share your location with us.';

  @override
  String get enableGPS => 'Enable GPS';

  @override
  String get retry => 'Retry';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get arabic => 'Arabic';

  @override
  String get french => 'French';

  @override
  String get english => 'English';

  @override
  String get shareLocationTitle => 'Share your location with us';

  @override
  String get shareLocationDescription =>
      'Tawsil uses your location to find establishments near you and deliver precisely to your address';

  @override
  String get shareLocationButton => 'Access to location';

  @override
  String get addAddressButton => 'Add an address manually';

  @override
  String get validateOrder => 'Valider la commande';

  @override
  String get pickupPoint => 'Point de récupération';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get destination => 'Destination';

  @override
  String get deliveryAddressLabel => 'Adresse de livraison';

  @override
  String get deliveryTime => 'Temps de livraison';

  @override
  String get orderNumber => 'Numéro de commande';

  @override
  String get totalLabel => 'Total';

  @override
  String totalValue(String total) {
    return '$total DA';
  }

  @override
  String get paymentMethodLabel => 'Méthode de paiement';

  @override
  String get orderDetailsLabel => 'Détails de la commande';

  @override
  String get validate => 'Valider';

  @override
  String get confirmOrder => 'Confirmer la commande';

  @override
  String get confirmOrderMessage => 'Voulez-vous confirmer cette commande ?';

  @override
  String get payment => 'Paiement';

  @override
  String get orderValidatedSuccessfully => 'Commande validée avec succès!';

  @override
  String get verificationError => 'Erreur:';

  @override
  String get addToCart => 'Ajouter au panier';

  @override
  String get removeFromCart => 'Retirer du panier';

  @override
  String get noteForKitchen => 'Note pour la cuisine';

  @override
  String get verification => 'Verification';

  @override
  String get enterVerificationCode => 'Enter the verification code';

  @override
  String get weSentCode => 'We sent a code to';

  @override
  String get codeSentTo => 'A verification code has been sent to';

  @override
  String resendCodeIn(int seconds) {
    return 'You can resend the code in $seconds seconds';
  }

  @override
  String get modifyNumber => 'Modify the number';

  @override
  String get codeComplete => 'Veuillez entrer le code complet (6 chiffres).';

  @override
  String get verificationErrorMsg => 'Erreur lors de la vérification:';

  @override
  String get devOtp => 'Test OTP:';

  @override
  String get codeRenvoye => 'Code renvoyé';

  @override
  String get notReceived => 'Vous n\'avez pas reçu le code ?';

  @override
  String get resend => 'Renvoyer';

  @override
  String get verify => 'Vérifier';

  @override
  String get verificationSuccessful => 'Vérification réussie!';

  @override
  String get cartEmptyMessage => 'Votre panier est vide';

  @override
  String get viewCart => 'Consulter le panier';

  @override
  String quantityInCart(int count) {
    return '$count dans le panier';
  }

  @override
  String get notAvailable => 'Non disponible';

  @override
  String get deliveryFeeLabel => 'Frais de livraison';

  @override
  String get deliveryTimeLabel => 'Temps de livraison';

  @override
  String get switchToPremium => 'Passez en mode';

  @override
  String get premium => 'Premium';

  @override
  String get moreServices => 'plus de services, plus d\'avantages';

  @override
  String get addToFavorites => 'Ajouté aux favoris';

  @override
  String get premiumLabel => 'PREMIUM';

  @override
  String get loadingRestaurants => 'Chargement des restaurants...';

  @override
  String get categories => 'Catégories';

  @override
  String get showAll => 'Show All';

  @override
  String get all => 'All';

  @override
  String get recommendations => 'Recommendations';

  @override
  String newToDiscover(int count) {
    return 'Nouveautés à découvrir ($count)';
  }

  @override
  String get noRestaurantFound => 'Aucun restaurant trouvé';

  @override
  String get reload => 'Recharger';

  @override
  String get searchRestaurantPlaceholder => 'Rechercher des restaurants';

  @override
  String get navigationToCart => 'Navigation vers le panier';

  @override
  String get noRestaurantNear => 'Aucun restaurant trouvé près de vous.';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get retryAction => 'Retry';

  @override
  String get allowLocation =>
      'Autoriser « tawsil » à utiliser votre position ?';

  @override
  String get locationPurpose =>
      'Afin de détecter les partenaires autour de vous, nous devons utiliser votre localisation';

  @override
  String get allowOnce => 'Autoriser une fois';

  @override
  String get allowWhenActive => 'Autoriser lorsque l\'app est active';

  @override
  String get doNotAllow => 'Ne pas autoriser';

  @override
  String get addUserInfo => 'Complete your profile';

  @override
  String get userInfoSubtitle =>
      'Please enter your first and last name to complete your profile.';

  @override
  String get firstName => 'First Name';

  @override
  String get firstNameHint => 'Enter your first name';

  @override
  String get lastName => 'Last Name';

  @override
  String get lastNameHint => 'Enter your last name';

  @override
  String get save => 'Save';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully!';

  @override
  String get errorPhoneNumberRequired => 'Please enter your phone number';

  @override
  String get errorPhoneNumberInvalid => 'Invalid phone number';

  @override
  String get errorPhoneNumberMinLength =>
      'Phone number must contain at least 8 digits';

  @override
  String get errorCodeSendFailed => 'Error sending verification code';

  @override
  String errorConnection(String error) {
    return 'Connection error: $error';
  }

  @override
  String get errorCodeLength => 'Code must contain 6 digits';

  @override
  String get errorCodeInvalid => 'Invalid verification code';

  @override
  String errorVerification(String error) {
    return 'Verification error: $error';
  }

  @override
  String get errorFirstNameRequired => 'Please enter your first name';

  @override
  String get errorLastNameRequired => 'Please enter your last name';

  @override
  String get errorProfileUpdateFailed => 'Error updating profile';

  @override
  String errorProfileUpdate(String error) {
    return 'Error updating profile: $error';
  }

  @override
  String get errorProfileFetchFailed => 'Error fetching profile';

  @override
  String errorProfileFetch(String error) {
    return 'Error fetching profile: $error';
  }

  @override
  String errorCategoriesLoading(String error) {
    return 'Error loading categories: $error';
  }

  @override
  String get errorCategoriesLoadingFailed => 'Error loading categories';

  @override
  String errorRestaurantsLoading(String error) {
    return 'Error loading restaurants: $error';
  }

  @override
  String get errorRestaurantsLoadingFailed => 'Error loading restaurants';

  @override
  String errorRestaurantsSearch(String error) {
    return 'Error searching restaurants: $error';
  }

  @override
  String get errorRestaurantsSearchFailed => 'Error searching restaurants';

  @override
  String errorRestaurantDetailsLoading(String error) {
    return 'Error loading restaurant details: $error';
  }

  @override
  String get errorRestaurantDetailsLoadingFailed =>
      'Error loading restaurant details';

  @override
  String errorRestaurantsFilterByCategory(String error) {
    return 'Error filtering restaurants by category: $error';
  }

  @override
  String get errorRestaurantsFilterByCategoryFailed =>
      'Error filtering restaurants by category';

  @override
  String get user => 'User';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get orderedProducts => 'Ordered products';

  @override
  String get orderTracking => 'Order tracking';

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusPendingDescription =>
      'The restaurant is reviewing your order';

  @override
  String get orderStatusAccepted => 'Order accepted';

  @override
  String get orderStatusAcceptedDescription => 'Your order has been accepted';

  @override
  String get orderStatusPreparing => 'Order preparation';

  @override
  String get orderStatusPreparingDescription =>
      'The restaurant is preparing your order';

  @override
  String get orderStatusAssigned => 'Order assigned';

  @override
  String get orderStatusAssignedDescription =>
      'A delivery person has been assigned to your order';

  @override
  String get orderStatusDelivering => 'Order is on the way';

  @override
  String get orderStatusDeliveringDescription =>
      'Your order is being delivered';

  @override
  String get orderStatusDelivered => 'Order delivered';

  @override
  String get orderStatusDeliveredDescription => 'Your order has been delivered';

  @override
  String get orderStatusPretRecuperer => 'Ready for pickup';

  @override
  String get orderStatusPretRecupererDescription =>
      'Your order is ready to be picked up';

  @override
  String get orderStatusRecuperer => 'Picked up';

  @override
  String get orderStatusRecupererDescription => 'Your order has been picked up';

  @override
  String get deliveryPerson => 'Delivery person';

  @override
  String get searchingForDeliveryPerson => 'Delivery person in progress';

  @override
  String get orderRefused => 'Order refused';

  @override
  String get orderDelayed => 'Order delayed';

  @override
  String get orderPending => 'Order Pending';

  @override
  String get orderAccepted => 'Order Accepted';

  @override
  String get orderPreparing => 'Preparing';

  @override
  String get orderAssigned => 'Delivery Assigned';

  @override
  String get orderDelivering => 'On the Way';

  @override
  String get orderDelivered => 'Delivered';

  @override
  String get orderCollected => 'Collected';

  @override
  String get orderDeclined => 'Order Declined';

  @override
  String get orderReadyToCollect => 'Ready to Collect';

  @override
  String get trackOrder => 'Track Order';

  @override
  String get track => 'Track';

  @override
  String get items => 'items';

  @override
  String get order => 'Order';

  @override
  String get orderDeclinedByRestaurant => 'Order Declined';

  @override
  String get orderDeclinedMessage =>
      'We\'re sorry, but the restaurant has declined your order. You can try ordering from another restaurant.';

  @override
  String get close => 'Close';

  @override
  String get errorOrderNotFound => 'Order not found';

  @override
  String get errorOrderLoadFailed => 'Error loading order';

  @override
  String errorOrderLoad(String error) {
    return 'Error loading order: $error';
  }

  @override
  String get search => 'Search';

  @override
  String get searching => 'Searching...';

  @override
  String get searchingFor => 'Searching for';

  @override
  String get searchError => 'Search error';

  @override
  String get noResults => 'No results';

  @override
  String get noRestaurantFoundFor => 'No restaurant found for';

  @override
  String get tryDifferentSearchTerm => 'Try a different search term';

  @override
  String get searchRestaurants => 'Search restaurants';

  @override
  String get searchRestaurantsHint =>
      'Type the name of a restaurant or dish to start your search';

  @override
  String get promoBannerTitle => 'Free Delivery on Your 3rd Order!';

  @override
  String get promoBannerDescription =>
      'After two orders, the delivery of your third order is free.';

  @override
  String get noMenuItemsAvailable => 'No menu items available';

  @override
  String get failedToLoadMenuItems =>
      'Failed to load menu items. Please try again.';

  @override
  String get or => 'Or';

  @override
  String get apple => 'Apple';

  @override
  String get google => 'Google';

  @override
  String get acceptTerms => 'You Accept The Terms of Use Of Tawsil.';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get myLocations => 'My Locations';

  @override
  String get myPromotions => 'My Promotions';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get messages => 'Messages';

  @override
  String get inviteFriends => 'Invite Friends';

  @override
  String get security => 'Security';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String orderedAt(String date) {
    return 'Ordered at $date';
  }

  @override
  String get deliverySuccessful => 'Delivery Successful';

  @override
  String get enjoyYourMeal => 'Enjoy Your Meal!';

  @override
  String get seeYouNextOrder => 'See You In The Next Order!';

  @override
  String get ok => 'Ok';

  @override
  String get orderRating => 'Order Rating';

  @override
  String get deliveryEvaluation => 'Delivery Evaluation';

  @override
  String get restaurantEvaluation => 'Restaurant Evaluation';

  @override
  String get typeYourReview => 'Type your review...';

  @override
  String get skip => 'Skip';

  @override
  String get submit => 'Submit';

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get clearHistory => 'Clear';

  @override
  String get changeLocation => 'Change your location';

  @override
  String get currentAddress => 'Current address';

  @override
  String get savedAddresses => 'Saved addresses';

  @override
  String get addNewAddress => 'Add a new address';

  @override
  String get useCurrentLocation => 'Use Current Location';

  @override
  String get searchForLocation => 'Search for location';

  @override
  String get addNewAddressTitle => 'Add New Address';

  @override
  String get editAddressTitle => 'Edit Address';

  @override
  String get addressNameHint => 'Name (e.g., Home, Work)';

  @override
  String get setAsDefaultAddress => 'Set as default address';

  @override
  String get saveAddress => 'Save Address';

  @override
  String get loadingAddress => 'Loading address...';

  @override
  String get pleaseEnterAddressName => 'Please enter a name for this address';

  @override
  String get pleaseSelectLocation => 'Please select a location on the map';

  @override
  String get location => 'Location';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAddressConfirmation =>
      'Are you sure you want to delete this address?';

  @override
  String get errorMaxFavoriteAddressesReached =>
      'Maximum 5 favorite addresses allowed';

  @override
  String get loadingHomepage => 'Loading homepage...';

  @override
  String get dailyDeals => 'Daily Deals';

  @override
  String get dailyDealsSubtitle => 'Enjoy the best deals';

  @override
  String get featuredRestaurants => 'Featured Restaurants';

  @override
  String get premiumRestaurants => 'Premium Restaurants';

  @override
  String get recommendedDishes => 'Recommended Dishes';

  @override
  String get promotions => 'Promotions';

  @override
  String get nearbyRestaurants => 'Nearby Restaurants';

  @override
  String get allRestaurants => 'All Restaurants';

  @override
  String get additionalOptions => 'Additional Options :';

  @override
  String get optionRequiredHint => 'Choose 1 option';

  @override
  String get optionOptionalHint => '0 to many choices possible';

  @override
  String optionSelectionRequired(int count) {
    return '$count/1 selected';
  }

  @override
  String optionSelectionOptional(int count) {
    return '$count selected';
  }

  @override
  String get optionRequiredBadge => 'Required';

  @override
  String get optionOptionalBadge => 'Optional';

  @override
  String optionAdditionalPrice(String price) {
    return '+ $price DA';
  }

  @override
  String get ourDishes => 'Our Dishes';

  @override
  String get store => 'Store';

  @override
  String get free => 'Free';

  @override
  String get minutes => 'minutes';

  @override
  String get statusCardPendingTitle => 'Order pending';

  @override
  String get statusCardPendingDescription =>
      'Your order has been successfully transmitted to the restaurant and is awaiting confirmation.';

  @override
  String get statusCardAcceptedTitle => 'Order accepted';

  @override
  String get statusCardAcceptedDescription =>
      'The restaurant has accepted your order and will start preparation.';

  @override
  String get statusCardPreparingTitle => 'Order in preparation';

  @override
  String get statusCardPreparingDescription =>
      'Your order is currently being prepared at the restaurant.';

  @override
  String get statusCardAssignedTitle => 'Delivery person assigned';

  @override
  String get statusCardAssignedDescription =>
      'A delivery person has been assigned to your order.';

  @override
  String get statusCardDeliveringTitle => 'Delivery person on the way';

  @override
  String get statusCardDeliveringDescription =>
      'The delivery person is on the way to your address and will arrive shortly.';

  @override
  String get statusCardDeliveredTitle => 'Order delivered';

  @override
  String get statusCardDeliveredDescription =>
      'Your order has been successfully delivered.';

  @override
  String get statusCardReadyToCollectTitle => 'Ready for pickup';

  @override
  String get statusCardReadyToCollectDescription =>
      'Your order is ready to be picked up.';

  @override
  String get statusCardCollectedTitle => 'Order collected';

  @override
  String get statusCardCollectedDescription =>
      'Your order has been successfully collected.';

  @override
  String get statusCardDefaultTitle => 'In progress';

  @override
  String get statusCardDefaultDescription => 'Your order is being processed.';

  @override
  String get orderHistory => 'Order History';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get ordersCompleted => 'Orders Completed';

  @override
  String get noOrdersYet => 'No Orders Yet';

  @override
  String get startOrderingNow => 'Start ordering now to see your history';

  @override
  String get details => 'Details';

  @override
  String get statusOngoing => 'Ongoing';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get todayLabel => 'Today';

  @override
  String get yesterdayLabel => 'Yesterday';
}
