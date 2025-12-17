// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Tawsil';

  @override
  String get addPhoneNumber => 'Ajoutez votre numéro de téléphone';

  @override
  String get phoneNumberSubtitle =>
      'Pour vous connecter ou vous inscrire,introduisez votre numéro de téléphone .';

  @override
  String get phoneNumberHint => 'Numéro de téléphone';

  @override
  String get connect => 'Connexion';

  @override
  String get home => 'Accueil';

  @override
  String get favorites => 'Favoris';

  @override
  String get history => 'Historique';

  @override
  String get cart => 'Panier';

  @override
  String get profile => 'Profil';

  @override
  String get cartTitle => 'Panier';

  @override
  String get orderSummary => 'Récapitulatif de commande';

  @override
  String get addItem => 'Ajouter article';

  @override
  String get deliveryAddress => 'Adresse de livraison';

  @override
  String products(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Produits',
      one: 'Produit',
      zero: 'Produits',
    );
    return '$_temp0';
  }

  @override
  String get deliveryFee => 'Frais de livraison';

  @override
  String get estimatedTime => 'Temps estimé';

  @override
  String get estimatedDeliveryTime => 'Temps de livraison estimé';

  @override
  String get orderDetails => 'Détails de la commande';

  @override
  String get subtotal => 'Sous-total';

  @override
  String get platformFee => 'Frais de plateforme';

  @override
  String get total => 'Total';

  @override
  String get paymentMethod => 'Méthode de paiement';

  @override
  String get cash => 'Espèces';

  @override
  String get baridiMob => 'Baridi Mob';

  @override
  String get bankTransfer => 'Virement bancaire';

  @override
  String get deliveryOption => 'Option de livraison';

  @override
  String get pickup => 'Sur place';

  @override
  String get delivery => 'Livraison';

  @override
  String get verifyAndFinalize => 'Vérifier et Finaliser';

  @override
  String get emptyCart => 'Votre panier est vide';

  @override
  String get addProductsToContinue => 'Ajoutez des produits pour continuer';

  @override
  String get removeProduct => 'Retirer le produit';

  @override
  String removeProductConfirmation(String productName) {
    return 'Voulez-vous retirer \"$productName\" du panier?';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get remove => 'Retirer';

  @override
  String get note => 'Note';

  @override
  String get enterAddress => 'Entrer une adresse';

  @override
  String get addressHint => 'Ex: 123 Rue de la République, Alger';

  @override
  String get confirm => 'Confirmer';

  @override
  String get permissionDenied =>
      'Vous avez refusé l\'autorisation. Activez la localisation dans les paramètres.';

  @override
  String get gpsTimeout =>
      'Impossible de récupérer la localisation GPS (temps écoulé).';

  @override
  String get gpsError => 'Impossible de récupérer la localisation GPS.';

  @override
  String get locationSendError =>
      'Erreur lors de l\'envoi de la localisation. Vérifiez votre connexion.';

  @override
  String get addressSendError =>
      'Erreur lors de l\'envoi de l\'adresse. Vérifiez votre connexion.';

  @override
  String get error => 'Erreur';

  @override
  String get loadingError => 'Erreur de chargement';

  @override
  String get gpsDisabled => 'Services de localisation désactivés';

  @override
  String get gpsDisabledMessage =>
      'Veuillez activer le GPS pour partager votre localisation avec nous.';

  @override
  String get enableGPS => 'Activer le GPS';

  @override
  String get retry => 'Réessayer';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get arabic => 'Arabe';

  @override
  String get french => 'Français';

  @override
  String get english => 'Anglais';

  @override
  String get shareLocationTitle => 'Partagez votre localisation avec nous';

  @override
  String get shareLocationDescription =>
      'Tawsil utilise votre localisation pour trouver des établissements près de chez vous et livrer précisément à votre adresse';

  @override
  String get shareLocationButton => 'Accès à la localisation';

  @override
  String get addAddressButton => 'Ajoutez une adresse manuellement';

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
  String get noteForKitchen => 'Note pour la cuisine';

  @override
  String get verification => 'Vérification';

  @override
  String get enterVerificationCode => 'Entrez le code de vérification';

  @override
  String get weSentCode => 'Nous avons envoyé un code à';

  @override
  String get codeSentTo => 'Un code de vérification a été envoyé à';

  @override
  String resendCodeIn(int seconds) {
    return 'Vous pourrez renvoyer le code dans $seconds secondes';
  }

  @override
  String get modifyNumber => 'Modifier le numéro';

  @override
  String get codeComplete => 'Veuillez entrer le code complet (6 chiffres).';

  @override
  String get verificationErrorMsg => 'Erreur lors de la vérification:';

  @override
  String get devOtp => 'OTP de test:';

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
  String get showAll => 'Afficher tout';

  @override
  String get recommendations => 'Recommandations';

  @override
  String newToDiscover(int count) {
    return 'Nouveautés à découvrir ($count)';
  }

  @override
  String get noRestaurantFound => 'Aucun restaurant trouvé';

  @override
  String get reload => 'Recharger';

  @override
  String get searchRestaurantPlaceholder =>
      'Rechercher des restaurants, des aliments...';

  @override
  String get navigationToCart => 'Navigation vers le panier';

  @override
  String get noRestaurantNear => 'Aucun restaurant trouvé près de vous.';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get retryAction => 'Réessayer';

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
  String get addUserInfo => 'Complétez votre profil';

  @override
  String get userInfoSubtitle =>
      'Veuillez entrer votre prénom et votre nom de famille pour compléter votre profil.';

  @override
  String get firstName => 'Prénom';

  @override
  String get firstNameHint => 'Entrez votre prénom';

  @override
  String get lastName => 'Nom de famille';

  @override
  String get lastNameHint => 'Entrez votre nom de famille';

  @override
  String get save => 'Enregistrer';

  @override
  String get profileUpdatedSuccessfully => 'Profil mis à jour avec succès!';

  @override
  String get errorPhoneNumberRequired =>
      'Veuillez entrer votre numéro de téléphone';

  @override
  String get errorPhoneNumberInvalid => 'Numéro de téléphone invalide';

  @override
  String get errorPhoneNumberMinLength =>
      'Le numéro de téléphone doit contenir au moins 8 chiffres';

  @override
  String get errorCodeSendFailed => 'Erreur lors de l\'envoi du code';

  @override
  String errorConnection(String error) {
    return 'Erreur de connexion: $error';
  }

  @override
  String get errorCodeLength => 'Le code doit contenir 6 chiffres';

  @override
  String get errorCodeInvalid => 'Code de vérification invalide';

  @override
  String errorVerification(String error) {
    return 'Erreur de vérification: $error';
  }

  @override
  String get errorFirstNameRequired => 'Veuillez entrer votre prénom';

  @override
  String get errorLastNameRequired => 'Veuillez entrer votre nom de famille';

  @override
  String get errorProfileUpdateFailed =>
      'Erreur lors de la mise à jour du profil';

  @override
  String errorProfileUpdate(String error) {
    return 'Erreur lors de la mise à jour du profil: $error';
  }

  @override
  String get errorProfileFetchFailed =>
      'Erreur lors de la récupération du profil';

  @override
  String errorProfileFetch(String error) {
    return 'Erreur lors de la récupération du profil: $error';
  }

  @override
  String errorCategoriesLoading(String error) {
    return 'Erreur lors du chargement des catégories: $error';
  }

  @override
  String get errorCategoriesLoadingFailed =>
      'Erreur lors du chargement des catégories';

  @override
  String errorRestaurantsLoading(String error) {
    return 'Erreur lors du chargement des restaurants: $error';
  }

  @override
  String get errorRestaurantsLoadingFailed =>
      'Erreur lors du chargement des restaurants';

  @override
  String errorRestaurantsSearch(String error) {
    return 'Erreur lors de la recherche: $error';
  }

  @override
  String get errorRestaurantsSearchFailed => 'Erreur lors de la recherche';

  @override
  String errorRestaurantDetailsLoading(String error) {
    return 'Erreur lors du chargement des détails: $error';
  }

  @override
  String get errorRestaurantDetailsLoadingFailed =>
      'Erreur lors du chargement des détails';

  @override
  String errorRestaurantsFilterByCategory(String error) {
    return 'Erreur lors du filtrage par catégorie: $error';
  }

  @override
  String get errorRestaurantsFilterByCategoryFailed =>
      'Erreur lors du filtrage par catégorie';

  @override
  String get user => 'utilisateur';

  @override
  String get greetingMorning => 'Bonjour';

  @override
  String get greetingAfternoon => 'Bon après-midi';

  @override
  String get greetingEvening => 'Bonsoir';

  @override
  String get orderedProducts => 'Produit commandés';

  @override
  String get orderTracking => 'Suivi la commande';

  @override
  String get orderStatusPending => 'En attente';

  @override
  String get orderStatusPendingDescription =>
      'Le restaurant examine votre commande';

  @override
  String get orderStatusAccepted => 'Commande acceptée';

  @override
  String get orderStatusAcceptedDescription => 'Votre commande a été acceptée';

  @override
  String get orderStatusPreparing => 'Preparation de la comande';

  @override
  String get orderStatusPreparingDescription =>
      'Le restaurant prépare votre commande';

  @override
  String get orderStatusAssigned => 'Commande assignée';

  @override
  String get orderStatusAssignedDescription =>
      'Un livreur a été assigné à votre commande';

  @override
  String get orderStatusDelivering => 'La commande est en route';

  @override
  String get orderStatusDeliveringDescription =>
      'Votre commande est en cours de livraison';

  @override
  String get orderStatusDelivered => 'Commande livrée';

  @override
  String get orderStatusDeliveredDescription => 'Votre commande a été livrée';

  @override
  String get orderStatusPretRecuperer => 'Prêt à récupérer';

  @override
  String get orderStatusPretRecupererDescription =>
      'Votre commande est prête à être récupérée';

  @override
  String get orderStatusRecuperer => 'Récupéré';

  @override
  String get orderStatusRecupererDescription =>
      'Votre commande a été récupérée';

  @override
  String get deliveryPerson => 'Livreur';

  @override
  String get orderRefused => 'Commande refusée';

  @override
  String get orderDelayed => 'Commande retardée';

  @override
  String get orderDeclinedByRestaurant => 'Commande Refusée';

  @override
  String get orderDeclinedMessage =>
      'Nous sommes désolés, mais le restaurant a refusé votre commande. Vous pouvez essayer de commander dans un autre restaurant.';

  @override
  String get close => 'Fermer';

  @override
  String get errorOrderNotFound => 'Commande non trouvée';

  @override
  String get errorOrderLoadFailed => 'Erreur lors du chargement de la commande';

  @override
  String errorOrderLoad(String error) {
    return 'Erreur lors du chargement de la commande: $error';
  }

  @override
  String get searching => 'Recherche en cours...';

  @override
  String get searchingFor => 'Recherche de';

  @override
  String get searchError => 'Erreur de recherche';

  @override
  String get noResults => 'Aucun résultat';

  @override
  String get noRestaurantFoundFor => 'Aucun restaurant trouvé pour';

  @override
  String get tryDifferentSearchTerm =>
      'Essayez un terme de recherche différent';

  @override
  String get searchRestaurants => 'Rechercher des restaurants';

  @override
  String get searchRestaurantsHint =>
      'Tapez le nom d\'un restaurant ou d\'un plat pour commencer votre recherche';

  @override
  String get promoBannerTitle => 'Livraison Gratuite à votre 3ème Commande !';

  @override
  String get promoBannerDescription =>
      'après deux commandes, la livraison de votre troisième commande est offerte.';

  @override
  String get noMenuItemsAvailable => 'No menu items available';

  @override
  String get failedToLoadMenuItems =>
      'Failed to load menu items. Please try again.';

  @override
  String get or => 'Ou';

  @override
  String get apple => 'Apple';

  @override
  String get google => 'Google';

  @override
  String get acceptTerms =>
      'Vous Acceptez Les Conditions D\'utilisation De Tawsil.';

  @override
  String get termsOfUse => 'Conditions d\'utilisation';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get myLocations => 'Mes Adresses';

  @override
  String get myPromotions => 'Mes Promotions';

  @override
  String get paymentMethods => 'Méthodes de Paiement';

  @override
  String get messages => 'Messages';

  @override
  String get inviteFriends => 'Inviter des Amis';

  @override
  String get security => 'Sécurité';

  @override
  String get helpCenter => 'Centre d\'Aide';

  @override
  String get logout => 'Déconnexion';

  @override
  String get logoutConfirmation =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String orderedAt(String date) {
    return 'Commandé le $date';
  }

  @override
  String get deliverySuccessful => 'Livraison réussie';

  @override
  String get enjoyYourMeal => 'Bon appétit !';

  @override
  String get seeYouNextOrder => 'À bientôt pour votre prochaine commande !';

  @override
  String get ok => 'Ok';

  @override
  String get orderRating => 'Évaluation de la commande';

  @override
  String get deliveryEvaluation => 'Évaluation de la livraison';

  @override
  String get restaurantEvaluation => 'Évaluation du restaurant';

  @override
  String get typeYourReview => 'Tapez votre avis...';

  @override
  String get skip => 'Passer';

  @override
  String get submit => 'Soumettre';
}
