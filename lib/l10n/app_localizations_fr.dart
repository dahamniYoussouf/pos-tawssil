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
  String get pickup => 'Sur place (sans livraison)';

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
  String get shareLocationButton => 'Partagez votre localisation';

  @override
  String get addAddressButton => 'Ajoutez une adresse';

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
}
