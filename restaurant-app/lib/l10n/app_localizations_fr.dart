// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'tawsil';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get loginSubtitle =>
      'Connectez-vous à votre adresse e-mail et le mot de passe de votre boutique';

  @override
  String get emailAddress => 'Adresse mail';

  @override
  String get emailAddressHint => 'Entrez votre adresse mail';

  @override
  String get email => 'E-mail';

  @override
  String get emailHint => 'Saisissez votre mail';

  @override
  String get password => 'Mode passe';

  @override
  String get passwordHint => 'Entrez votre mot de passe';

  @override
  String get login => 'Se connecter';

  @override
  String get termsAndConditions =>
      'En vous connectant, vous acceptez nos Condition d\'utulisation';

  @override
  String get becomePartner => 'Devenez partenaire →';

  @override
  String get signUpTitle => 'Devenez livreur -partenaire';

  @override
  String get signUpSubtitle =>
      'devenez partenaire et gérez votre restaurant en toute autonomie. Augmentez votre visibilité et vos revenus grâce à tawsil';

  @override
  String get restaurantName => 'Nom du restaurant';

  @override
  String get restaurantNameHint => 'Saisissez le nom de votre restaurant';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get phoneNumberHint => 'Numéro de téléphone';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get confirmPasswordHint => 'Confirmer votre mot de passe';

  @override
  String get restaurantType => 'Choix du type de restaurant';

  @override
  String get restaurantTypeHint => 'Sélectionnez le type';

  @override
  String get willaya => 'Willaya';

  @override
  String get willayaHint => 'Sélectionnez la willaya';

  @override
  String get zone => 'Zone';

  @override
  String get zoneHint => 'Sélectionnez la zone';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'Décrivez votre restaurant';

  @override
  String get address => 'Adresse';

  @override
  String get addressHint => 'Saisissez l\'adresse complète';

  @override
  String get locationSearchLabel => 'Localisation du restaurant';

  @override
  String get locationSearchHint => 'Recherchez par adresse ou zone';

  @override
  String get locationSearchButton => 'Rechercher';

  @override
  String get locationLatitudeLabel => 'Latitude';

  @override
  String get locationLongitudeLabel => 'Longitude';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get signUpTerms =>
      'En vous inscrivant à tawsila vous acceptez Condition d\'utulisation';

  @override
  String get errorEmailRequired => 'L\'email est requis';

  @override
  String get errorPasswordRequired => 'Le mot de passe est requis';

  @override
  String get errorRestaurantNameRequired => 'Le nom du restaurant est requis';

  @override
  String get errorPhoneNumberRequired => 'Le numéro de téléphone est requis';

  @override
  String get errorConfirmPasswordRequired =>
      'Veuillez confirmer votre mot de passe';

  @override
  String get errorPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get errorRestaurantTypeRequired => 'Le type de restaurant est requis';

  @override
  String get errorWillayaRequired => 'La willaya est requise';

  @override
  String get errorZoneRequired => 'La zone est requise';

  @override
  String get errorDescriptionRequired => 'La description est obligatoire';

  @override
  String get errorLocationRequired =>
      'Veuillez rechercher la localisation du restaurant';

  @override
  String get errorLocationNotFound => 'Aucune localisation correspondante';

  @override
  String get errorLocationLookupFailed =>
      'Impossible de récupérer la localisation, réessayez';

  @override
  String get errorLoginFailed => 'Échec de la connexion';

  @override
  String get errorRegistrationFailed => 'Échec de l\'inscription';

  @override
  String get errorLogoutFailed => 'Échec de la déconnexion';

  @override
  String get home => 'Accueil';

  @override
  String get homeTitle => 'Votre livraison commence ici!';

  @override
  String get homeSubtitle =>
      'Recevez vos commandes, suivez les adresses et offrez un service exceptionnel en un temps record.';

  @override
  String get getOrders => 'Obtenir des commandes';

  @override
  String get orders => 'Commandes';

  @override
  String orderTitle(String id) {
    return 'Commande #$id';
  }

  @override
  String get orderNumberLabel => 'Numéro de commande';

  @override
  String get deliveryTime => 'Délai de livraison';

  @override
  String get minutes => 'MIN';

  @override
  String get distance => 'Distance';

  @override
  String get kilometers => 'KM';

  @override
  String get deliveryPrice => 'Prix de livraison';

  @override
  String get totalPrice => 'Prix totale';

  @override
  String get refuse => 'Refuser';

  @override
  String get accept => 'Accepter';

  @override
  String get noOrders => 'Aucune commande';

  @override
  String get noPendingOrders => 'Vous n\'avez aucune commande en attente';

  @override
  String get error => 'Erreur';

  @override
  String get retry => 'Réessayer';

  @override
  String get orderAcceptedSuccess => 'Commande acceptée avec succès';

  @override
  String get orderRefusedSuccess => 'Commande refusée avec succès';

  @override
  String get errorInvalidResponseFormat => 'Format de réponse invalide';

  @override
  String get errorFailedToFetchOrders =>
      'Échec de la récupération des commandes';

  @override
  String get errorFailedToAcceptOrder =>
      'Échec de l\'acceptation de la commande';

  @override
  String errorAcceptingOrder(String error) {
    return 'Erreur lors de l\'acceptation de la commande : $error';
  }

  @override
  String get errorFailedToRefuseOrder => 'Échec du refus de la commande';

  @override
  String errorRefusingOrder(String error) {
    return 'Erreur lors du refus de la commande : $error';
  }
}
