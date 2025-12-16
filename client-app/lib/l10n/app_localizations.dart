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
  /// **'Tawsil'**
  String get appTitle;

  /// Phone number page title
  ///
  /// In en, this message translates to:
  /// **'Add your phone number'**
  String get addPhoneNumber;

  /// Phone number page subtitle
  ///
  /// In en, this message translates to:
  /// **'To log in or sign up, enter your phone number.'**
  String get phoneNumberSubtitle;

  /// Phone number input hint
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberHint;

  /// Connect button text
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// Home navigation label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Favorites navigation label
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// History navigation label
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Cart navigation label
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// Profile navigation label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Cart page title
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTitle;

  /// Order summary title
  ///
  /// In en, this message translates to:
  /// **'Order summary'**
  String get orderSummary;

  /// Add item button text
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// Delivery address label
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get deliveryAddress;

  /// Products label
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Products} =1{Product} other{Products}}'**
  String products(int count);

  /// Delivery fee label
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get deliveryFee;

  /// Estimated time label
  ///
  /// In en, this message translates to:
  /// **'Estimated time'**
  String get estimatedTime;

  /// Order details section title
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get orderDetails;

  /// Subtotal label
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// Platform fee label
  ///
  /// In en, this message translates to:
  /// **'Platform fee'**
  String get platformFee;

  /// Total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Payment method section title
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// Cash payment method
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// Baridi Mob payment method
  ///
  /// In en, this message translates to:
  /// **'Baridi Mob'**
  String get baridiMob;

  /// Bank transfer payment method
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get bankTransfer;

  /// Delivery option section title
  ///
  /// In en, this message translates to:
  /// **'Delivery option'**
  String get deliveryOption;

  /// Pickup option
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// Delivery option
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// Verify order button
  ///
  /// In en, this message translates to:
  /// **'Verify and Finalize'**
  String get verifyAndFinalize;

  /// Empty cart message
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get emptyCart;

  /// Empty cart subtitle
  ///
  /// In en, this message translates to:
  /// **'Add products to continue'**
  String get addProductsToContinue;

  /// Remove product dialog title
  ///
  /// In en, this message translates to:
  /// **'Remove product'**
  String get removeProduct;

  /// Remove product confirmation message
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove \"{productName}\" from the cart?'**
  String removeProductConfirmation(String productName);

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Remove button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Note label
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// Enter address dialog title
  ///
  /// In en, this message translates to:
  /// **'Enter an address'**
  String get enterAddress;

  /// Address input hint
  ///
  /// In en, this message translates to:
  /// **'Ex: 123 Republic Street, Algiers'**
  String get addressHint;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Permission denied message
  ///
  /// In en, this message translates to:
  /// **'You have denied permission. Enable location in settings.'**
  String get permissionDenied;

  /// GPS timeout error
  ///
  /// In en, this message translates to:
  /// **'Unable to retrieve GPS location (timeout).'**
  String get gpsTimeout;

  /// GPS error message
  ///
  /// In en, this message translates to:
  /// **'Unable to retrieve GPS location.'**
  String get gpsError;

  /// Location send error
  ///
  /// In en, this message translates to:
  /// **'Error sending location. Check your connection.'**
  String get locationSendError;

  /// Address send error
  ///
  /// In en, this message translates to:
  /// **'Error sending address. Check your connection.'**
  String get addressSendError;

  /// Generic error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Loading error message
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get loadingError;

  /// GPS disabled popup title
  ///
  /// In en, this message translates to:
  /// **'Location services disabled'**
  String get gpsDisabled;

  /// GPS disabled popup message
  ///
  /// In en, this message translates to:
  /// **'Please enable GPS to share your location with us.'**
  String get gpsDisabledMessage;

  /// Enable GPS button
  ///
  /// In en, this message translates to:
  /// **'Enable GPS'**
  String get enableGPS;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

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

  /// Arabic language name
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// French language name
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Share location screen title
  ///
  /// In en, this message translates to:
  /// **'Share your location with us'**
  String get shareLocationTitle;

  /// Share location screen description
  ///
  /// In en, this message translates to:
  /// **'Tawsil uses your location to find establishments near you and deliver precisely to your address'**
  String get shareLocationDescription;

  /// Share location button text
  ///
  /// In en, this message translates to:
  /// **'Access to location'**
  String get shareLocationButton;

  /// Add address button text
  ///
  /// In en, this message translates to:
  /// **'Add an address manually'**
  String get addAddressButton;

  /// Validate order page title
  ///
  /// In en, this message translates to:
  /// **'Valider la commande'**
  String get validateOrder;

  /// Pickup point label
  ///
  /// In en, this message translates to:
  /// **'Point de récupération'**
  String get pickupPoint;

  /// Restaurant label
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// Destination label
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// Delivery address label
  ///
  /// In en, this message translates to:
  /// **'Adresse de livraison'**
  String get deliveryAddressLabel;

  /// Delivery time label
  ///
  /// In en, this message translates to:
  /// **'Temps de livraison'**
  String get deliveryTime;

  /// Order number label
  ///
  /// In en, this message translates to:
  /// **'Numéro de commande'**
  String get orderNumber;

  /// Total label
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// Total value with currency
  ///
  /// In en, this message translates to:
  /// **'{total} DA'**
  String totalValue(String total);

  /// Payment method label
  ///
  /// In en, this message translates to:
  /// **'Méthode de paiement'**
  String get paymentMethodLabel;

  /// Order details label
  ///
  /// In en, this message translates to:
  /// **'Détails de la commande'**
  String get orderDetailsLabel;

  /// Validate button text
  ///
  /// In en, this message translates to:
  /// **'Valider'**
  String get validate;

  /// Confirm order dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirmer la commande'**
  String get confirmOrder;

  /// Confirm order message
  ///
  /// In en, this message translates to:
  /// **'Voulez-vous confirmer cette commande ?'**
  String get confirmOrderMessage;

  /// Payment label
  ///
  /// In en, this message translates to:
  /// **'Paiement'**
  String get payment;

  /// Order validated successfully message
  ///
  /// In en, this message translates to:
  /// **'Commande validée avec succès!'**
  String get orderValidatedSuccessfully;

  /// Verification error prefix
  ///
  /// In en, this message translates to:
  /// **'Erreur:'**
  String get verificationError;

  /// Add to cart button
  ///
  /// In en, this message translates to:
  /// **'Ajouter au panier'**
  String get addToCart;

  /// Note for kitchen label
  ///
  /// In en, this message translates to:
  /// **'Note pour la cuisine'**
  String get noteForKitchen;

  /// Verification page title
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// Enter verification code title
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code'**
  String get enterVerificationCode;

  /// We sent a code message
  ///
  /// In en, this message translates to:
  /// **'We sent a code to'**
  String get weSentCode;

  /// A verification code has been sent to message
  ///
  /// In en, this message translates to:
  /// **'A verification code has been sent to'**
  String get codeSentTo;

  /// Resend code countdown message
  ///
  /// In en, this message translates to:
  /// **'You can resend the code in {seconds} seconds'**
  String resendCodeIn(int seconds);

  /// Modify phone number button text
  ///
  /// In en, this message translates to:
  /// **'Modify the number'**
  String get modifyNumber;

  /// Complete code message
  ///
  /// In en, this message translates to:
  /// **'Veuillez entrer le code complet (6 chiffres).'**
  String get codeComplete;

  /// Verification error message
  ///
  /// In en, this message translates to:
  /// **'Erreur lors de la vérification:'**
  String get verificationErrorMsg;

  /// Dev OTP label
  ///
  /// In en, this message translates to:
  /// **'Test OTP:'**
  String get devOtp;

  /// Code resent message
  ///
  /// In en, this message translates to:
  /// **'Code renvoyé'**
  String get codeRenvoye;

  /// Not received code message
  ///
  /// In en, this message translates to:
  /// **'Vous n\'avez pas reçu le code ?'**
  String get notReceived;

  /// Resend button text
  ///
  /// In en, this message translates to:
  /// **'Renvoyer'**
  String get resend;

  /// Verify button text
  ///
  /// In en, this message translates to:
  /// **'Vérifier'**
  String get verify;

  /// Verification successful message
  ///
  /// In en, this message translates to:
  /// **'Vérification réussie!'**
  String get verificationSuccessful;

  /// Cart empty message
  ///
  /// In en, this message translates to:
  /// **'Votre panier est vide'**
  String get cartEmptyMessage;

  /// View cart button text
  ///
  /// In en, this message translates to:
  /// **'Consulter le panier'**
  String get viewCart;

  /// Quantity in cart message
  ///
  /// In en, this message translates to:
  /// **'{count} dans le panier'**
  String quantityInCart(int count);

  /// Not available label
  ///
  /// In en, this message translates to:
  /// **'Non disponible'**
  String get notAvailable;

  /// Delivery fee label
  ///
  /// In en, this message translates to:
  /// **'Frais de livraison'**
  String get deliveryFeeLabel;

  /// Delivery time label
  ///
  /// In en, this message translates to:
  /// **'Temps de livraison'**
  String get deliveryTimeLabel;

  /// Switch to premium label
  ///
  /// In en, this message translates to:
  /// **'Passez en mode'**
  String get switchToPremium;

  /// Premium label
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// More services advantages
  ///
  /// In en, this message translates to:
  /// **'plus de services, plus d\'avantages'**
  String get moreServices;

  /// Added to favorites message
  ///
  /// In en, this message translates to:
  /// **'Ajouté aux favoris'**
  String get addToFavorites;

  /// Premium badge
  ///
  /// In en, this message translates to:
  /// **'PREMIUM'**
  String get premiumLabel;

  /// Loading restaurants message
  ///
  /// In en, this message translates to:
  /// **'Chargement des restaurants...'**
  String get loadingRestaurants;

  /// Categories title
  ///
  /// In en, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// Show all button text
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// Recommendations section title
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// New to discover title
  ///
  /// In en, this message translates to:
  /// **'Nouveautés à découvrir ({count})'**
  String newToDiscover(int count);

  /// No restaurant found message
  ///
  /// In en, this message translates to:
  /// **'Aucun restaurant trouvé'**
  String get noRestaurantFound;

  /// Reload button text
  ///
  /// In en, this message translates to:
  /// **'Recharger'**
  String get reload;

  /// Search restaurant placeholder
  ///
  /// In en, this message translates to:
  /// **'Rechercher des restaurants, des aliments...'**
  String get searchRestaurantPlaceholder;

  /// Navigation to cart message
  ///
  /// In en, this message translates to:
  /// **'Navigation vers le panier'**
  String get navigationToCart;

  /// No restaurant near message
  ///
  /// In en, this message translates to:
  /// **'Aucun restaurant trouvé près de vous.'**
  String get noRestaurantNear;

  /// Try again button
  ///
  /// In en, this message translates to:
  /// **'Réessayer'**
  String get tryAgain;

  /// Retry action button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// Allow location question
  ///
  /// In en, this message translates to:
  /// **'Autoriser « tawsil » à utiliser votre position ?'**
  String get allowLocation;

  /// Location purpose explanation
  ///
  /// In en, this message translates to:
  /// **'Afin de détecter les partenaires autour de vous, nous devons utiliser votre localisation'**
  String get locationPurpose;

  /// Allow once option
  ///
  /// In en, this message translates to:
  /// **'Autoriser une fois'**
  String get allowOnce;

  /// Allow when app is active
  ///
  /// In en, this message translates to:
  /// **'Autoriser lorsque l\'app est active'**
  String get allowWhenActive;

  /// Do not allow option
  ///
  /// In en, this message translates to:
  /// **'Ne pas autoriser'**
  String get doNotAllow;

  /// User info page title
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get addUserInfo;

  /// User info page subtitle
  ///
  /// In en, this message translates to:
  /// **'Please enter your first and last name to complete your profile.'**
  String get userInfoSubtitle;

  /// First name field label
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// First name input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get firstNameHint;

  /// Last name field label
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// Last name input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your last name'**
  String get lastNameHint;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Profile updated success message
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// Phone number required error
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get errorPhoneNumberRequired;

  /// Invalid phone number error
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get errorPhoneNumberInvalid;

  /// Phone number minimum length error
  ///
  /// In en, this message translates to:
  /// **'Phone number must contain at least 8 digits'**
  String get errorPhoneNumberMinLength;

  /// Code send error
  ///
  /// In en, this message translates to:
  /// **'Error sending verification code'**
  String get errorCodeSendFailed;

  /// Connection error with details
  ///
  /// In en, this message translates to:
  /// **'Connection error: {error}'**
  String errorConnection(String error);

  /// Verification code length error
  ///
  /// In en, this message translates to:
  /// **'Code must contain 6 digits'**
  String get errorCodeLength;

  /// Invalid verification code error
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get errorCodeInvalid;

  /// Verification error with details
  ///
  /// In en, this message translates to:
  /// **'Verification error: {error}'**
  String errorVerification(String error);

  /// First name required error
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get errorFirstNameRequired;

  /// Last name required error
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get errorLastNameRequired;

  /// Profile update error
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get errorProfileUpdateFailed;

  /// Profile update error with details
  ///
  /// In en, this message translates to:
  /// **'Error updating profile: {error}'**
  String errorProfileUpdate(String error);

  /// Profile fetch error
  ///
  /// In en, this message translates to:
  /// **'Error fetching profile'**
  String get errorProfileFetchFailed;

  /// Profile fetch error with details
  ///
  /// In en, this message translates to:
  /// **'Error fetching profile: {error}'**
  String errorProfileFetch(String error);

  /// Categories loading error with details
  ///
  /// In en, this message translates to:
  /// **'Error loading categories: {error}'**
  String errorCategoriesLoading(String error);

  /// Categories loading error
  ///
  /// In en, this message translates to:
  /// **'Error loading categories'**
  String get errorCategoriesLoadingFailed;

  /// Restaurants loading error with details
  ///
  /// In en, this message translates to:
  /// **'Error loading restaurants: {error}'**
  String errorRestaurantsLoading(String error);

  /// Restaurants loading error
  ///
  /// In en, this message translates to:
  /// **'Error loading restaurants'**
  String get errorRestaurantsLoadingFailed;

  /// Restaurants search error with details
  ///
  /// In en, this message translates to:
  /// **'Error searching restaurants: {error}'**
  String errorRestaurantsSearch(String error);

  /// Restaurants search error
  ///
  /// In en, this message translates to:
  /// **'Error searching restaurants'**
  String get errorRestaurantsSearchFailed;

  /// Restaurant details loading error with details
  ///
  /// In en, this message translates to:
  /// **'Error loading restaurant details: {error}'**
  String errorRestaurantDetailsLoading(String error);

  /// Restaurant details loading error
  ///
  /// In en, this message translates to:
  /// **'Error loading restaurant details'**
  String get errorRestaurantDetailsLoadingFailed;

  /// Restaurants filter by category error with details
  ///
  /// In en, this message translates to:
  /// **'Error filtering restaurants by category: {error}'**
  String errorRestaurantsFilterByCategory(String error);

  /// Restaurants filter by category error
  ///
  /// In en, this message translates to:
  /// **'Error filtering restaurants by category'**
  String get errorRestaurantsFilterByCategoryFailed;

  /// User label
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Morning greeting (before 12)
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// Afternoon greeting (12-17)
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// Evening greeting (after 17)
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// Ordered products label
  ///
  /// In en, this message translates to:
  /// **'Ordered products'**
  String get orderedProducts;

  /// Order tracking title
  ///
  /// In en, this message translates to:
  /// **'Order tracking'**
  String get orderTracking;

  /// Order status pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orderStatusPending;

  /// Order status pending description
  ///
  /// In en, this message translates to:
  /// **'The restaurant is reviewing your order'**
  String get orderStatusPendingDescription;

  /// Order status accepted
  ///
  /// In en, this message translates to:
  /// **'Order accepted'**
  String get orderStatusAccepted;

  /// Order status accepted description
  ///
  /// In en, this message translates to:
  /// **'Your order has been accepted'**
  String get orderStatusAcceptedDescription;

  /// Order status preparing
  ///
  /// In en, this message translates to:
  /// **'Order preparation'**
  String get orderStatusPreparing;

  /// Order status preparing description
  ///
  /// In en, this message translates to:
  /// **'The restaurant is preparing your order'**
  String get orderStatusPreparingDescription;

  /// Order status assigned
  ///
  /// In en, this message translates to:
  /// **'Order assigned'**
  String get orderStatusAssigned;

  /// Order status assigned description
  ///
  /// In en, this message translates to:
  /// **'A delivery person has been assigned to your order'**
  String get orderStatusAssignedDescription;

  /// Order status delivering
  ///
  /// In en, this message translates to:
  /// **'Order is on the way'**
  String get orderStatusDelivering;

  /// Order status delivering description
  ///
  /// In en, this message translates to:
  /// **'Your order is being delivered'**
  String get orderStatusDeliveringDescription;

  /// Order status delivered
  ///
  /// In en, this message translates to:
  /// **'Order delivered'**
  String get orderStatusDelivered;

  /// Order status delivered description
  ///
  /// In en, this message translates to:
  /// **'Your order has been delivered'**
  String get orderStatusDeliveredDescription;

  /// Order status ready for pickup
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get orderStatusPretRecuperer;

  /// Order status ready for pickup description
  ///
  /// In en, this message translates to:
  /// **'Your order is ready to be picked up'**
  String get orderStatusPretRecupererDescription;

  /// Order status picked up
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get orderStatusRecuperer;

  /// Order status picked up description
  ///
  /// In en, this message translates to:
  /// **'Your order has been picked up'**
  String get orderStatusRecupererDescription;

  /// Delivery person label
  ///
  /// In en, this message translates to:
  /// **'Delivery person'**
  String get deliveryPerson;

  /// Order refused message
  ///
  /// In en, this message translates to:
  /// **'Order refused'**
  String get orderRefused;

  /// Order delayed message
  ///
  /// In en, this message translates to:
  /// **'Order delayed'**
  String get orderDelayed;

  /// Order declined by restaurant title
  ///
  /// In en, this message translates to:
  /// **'Order Declined'**
  String get orderDeclinedByRestaurant;

  /// Order declined message
  ///
  /// In en, this message translates to:
  /// **'We\'re sorry, but the restaurant has declined your order. You can try ordering from another restaurant.'**
  String get orderDeclinedMessage;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Order not found error
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get errorOrderNotFound;

  /// Order load error
  ///
  /// In en, this message translates to:
  /// **'Error loading order'**
  String get errorOrderLoadFailed;

  /// Order load error with details
  ///
  /// In en, this message translates to:
  /// **'Error loading order: {error}'**
  String errorOrderLoad(String error);

  /// Search in progress message
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// Searching for prefix
  ///
  /// In en, this message translates to:
  /// **'Searching for'**
  String get searchingFor;

  /// Search error title
  ///
  /// In en, this message translates to:
  /// **'Search error'**
  String get searchError;

  /// No search results message
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No restaurant found for query message
  ///
  /// In en, this message translates to:
  /// **'No restaurant found for'**
  String get noRestaurantFoundFor;

  /// Try different search term suggestion
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearchTerm;

  /// Search restaurants title
  ///
  /// In en, this message translates to:
  /// **'Search restaurants'**
  String get searchRestaurants;

  /// Search restaurants hint text
  ///
  /// In en, this message translates to:
  /// **'Type the name of a restaurant or dish to start your search'**
  String get searchRestaurantsHint;

  /// Promo banner title
  ///
  /// In en, this message translates to:
  /// **'Free Delivery on Your 3rd Order!'**
  String get promoBannerTitle;

  /// Promo banner description
  ///
  /// In en, this message translates to:
  /// **'After two orders, the delivery of your third order is free.'**
  String get promoBannerDescription;

  /// No menu items available message
  ///
  /// In en, this message translates to:
  /// **'No menu items available'**
  String get noMenuItemsAvailable;

  /// Failed to load menu items error message
  ///
  /// In en, this message translates to:
  /// **'Failed to load menu items. Please try again.'**
  String get failedToLoadMenuItems;

  /// Or separator text
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get or;

  /// Apple login button text
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get apple;

  /// Google login button text
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// Terms acceptance text
  ///
  /// In en, this message translates to:
  /// **'You Accept The Terms of Use Of Tawsil.'**
  String get acceptTerms;

  /// Terms of use link text
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// Privacy policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// My locations menu item
  ///
  /// In en, this message translates to:
  /// **'My Locations'**
  String get myLocations;

  /// My promotions menu item
  ///
  /// In en, this message translates to:
  /// **'My Promotions'**
  String get myPromotions;

  /// Payment methods menu item
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// Messages menu item
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Invite friends menu item
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// Security menu item
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Help center menu item
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// Logout menu item
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;
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
