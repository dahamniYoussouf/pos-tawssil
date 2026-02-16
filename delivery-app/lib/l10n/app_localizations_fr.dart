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
      'Connectez-vous à votre compte Rider avec vos identitifants.';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get usernameHint => 'Entrez votre identifiant';

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
  String get termsPrefix => 'En vous connectant, vous acceptez nos\n';

  @override
  String get termsLabel => 'Conditions D’utilisation';

  @override
  String get termsAnd => ' et ';

  @override
  String get privacyPolicyLabel => 'Politique De Confidentialité';

  @override
  String get becomePartner => 'Devenez livreur-partenaire →';

  @override
  String get signUpTitle => 'Devenez livreur -partenaire';

  @override
  String get signUpSubtitle =>
      'Livrer avec Tawsila, c\'est gérer son activité de façon autonome et augmenter ses revenus grâce à l\'application leader du marché.';

  @override
  String get firstName => 'Prenom';

  @override
  String get firstNameHint => 'Saisissez votre prenom';

  @override
  String get lastName => 'Nom';

  @override
  String get lastNameHint => 'Saisissez votre nom';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get phoneNumberHint => 'Numéro de téléphone';

  @override
  String get email => 'Email';

  @override
  String get emailHint => 'Saisissez votre Email';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get confirmPasswordHint => 'Confirmer votre mot de passe';

  @override
  String get willaya => 'Willaya';

  @override
  String get cancelReasonTechnicalIssue =>
      'Probleme technique avec la commande';

  @override
  String get confirmDelivery => 'Confirmer la livraison';

  @override
  String get confirmDeliveryMessage =>
      'Êtes-vous sûr de vouloir confirmer la livraison et terminer cette commande ?';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get zone => 'Zone';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get signUpTerms =>
      'En vous inscrivant à tawsila vous acceptez Condition d\'utulisation';

  @override
  String get errorUsernameRequired => 'Le nom d\'utilisateur est requis';

  @override
  String get errorPasswordRequired => 'Le mot de passe est requis';

  @override
  String get errorFirstNameRequired => 'Le prénom est requis';

  @override
  String get errorLastNameRequired => 'Le nom est requis';

  @override
  String get errorPhoneNumberRequired => 'Le numéro de téléphone est requis';

  @override
  String get errorEmailRequired => 'L\'email est requis';

  @override
  String get errorConfirmPasswordRequired =>
      'Veuillez confirmer votre mot de passe';

  @override
  String get errorPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get errorWillayaRequired => 'La willaya est requise';

  @override
  String get errorZoneRequired => 'La zone est requise';

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

  @override
  String get delivery => 'Livraison';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get minutesShort => 'min';

  @override
  String get taskDetails => 'Détails de la tâche';

  @override
  String get arrive => 'Arriver';

  @override
  String get delivered => 'Livré';

  @override
  String get cancel => 'Annuler';

  @override
  String get cancelOrderQuestion =>
      'Pourquoi shouaitez-vous annuler cette commande?';

  @override
  String get cancelReasonDriverLate =>
      'Le livreur a mise trop de temps a arriver';

  @override
  String get cancelReasonClientCanceled => 'Le client a annule sa commande';

  @override
  String get cancelReasonOther => 'Autre raison';

  @override
  String get confirm => 'Confirmer';

  @override
  String get orderNotFound => 'Commande introuvable';

  @override
  String get clientOrderTitle => 'Commande client';

  @override
  String get total => 'Total';

  @override
  String get clientLabel => 'Client';

  @override
  String get startDelivery => 'Démarrer la livraison';

  @override
  String get profile => 'Profil';

  @override
  String get myPromotions => 'Mes Promotions';

  @override
  String get paymentMethods => 'Moyens de paiement';

  @override
  String get messages => 'Messages';

  @override
  String get inviteFriends => 'Inviter des amis';

  @override
  String get security => 'Sécurité';

  @override
  String get manageAccount => 'Gérer votre compte';

  @override
  String get logout => 'Déconnexion';

  @override
  String get rating => 'Évaluation';

  @override
  String get deliveries => 'Livraisons';

  @override
  String get yearsJoined => 'Années d\'ancienneté';

  @override
  String get logoutConfirmation =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get ok => 'OK';

  @override
  String get orderHistory => 'Historique des commandes';

  @override
  String get all => 'Tout';

  @override
  String get statusOngoing => 'En cours';

  @override
  String get statusDelivered => 'Livré';

  @override
  String get statusCancelled => 'Annulé';

  @override
  String get noOrdersYet => 'Aucune commande pour le moment';

  @override
  String get startOrderingNow => 'Commencez à commander maintenant';

  @override
  String get todayLabel => 'Aujourd\'hui';

  @override
  String get yesterdayLabel => 'Hier';

  @override
  String get details => 'Détails';

  @override
  String get trackOrder => 'Suivre la commande';

  @override
  String get from => 'de:';

  @override
  String get to => 'à:';

  @override
  String get viewDetails => 'Voir les détails';

  @override
  String get newOrderAvailable => 'NOUVELLE COMMANDE DISPONIBLE';

  @override
  String get view => 'Voir';

  @override
  String get orderDetailsHeader => 'Détails De La Commande';

  @override
  String get rememberMe => 'Rester connecté(e)';

  @override
  String get forgotPassword => 'Mot de passe oublié?';

  @override
  String get deliveryAddressHeader => 'Adresse De Livraison';

  @override
  String get deliveryTimeHeader => 'Temps De Livraison';

  @override
  String get orderNumberHeader => 'Numero De Commande';

  @override
  String get paymentMethodHeader => 'Méthode De Paiement';

  @override
  String get cashPayment => 'Cash';

  @override
  String get radarButton => 'Radar des trajets';

  @override
  String get dontHaveAccount => 'Vous n’avez pas encore de compte? ';

  @override
  String get signUpAction => 'Inscrivez-vous';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Choisir la langue';

  @override
  String get arabic => 'Arabe';

  @override
  String get french => 'Français';

  @override
  String get english => 'Anglais';

  @override
  String get cancelModalTitle =>
      'Pourquoi souhaitez-vous annuler cette commande ?';

  @override
  String get cancelModalSubtitle => 'Aidez-nous à améliorer votre expérience.';

  @override
  String get otherReasonHint => 'Saisissez votre raison ici...';

  @override
  String get confirmCancellation => 'Confirmer L\'annulation';

  @override
  String get back => 'Retour';

  @override
  String get acceptDelivery => 'Accepter la livraison';

  @override
  String get currency => 'DA';

  @override
  String get deliveryCompleted => 'Livraison Terminee !';

  @override
  String get greatJobToday => 'Excellent Travail Aujourd\'hui !';

  @override
  String get tripEarnings => 'Gains De Cette Course';

  @override
  String get sessionTotal => 'Total De La Session';

  @override
  String get routeCompleted => 'Itinéraire terminé';

  @override
  String get backToRadar => 'Retour au Radar';

  @override
  String get waitingForOrders => 'En attente de commandes';

  @override
  String get generatedRevenue => 'Revenus générés';

  @override
  String get deliveredOrders => 'Commandes livrées';

  @override
  String get auto => 'AUTO';

  @override
  String get urgence => 'URGENCE';

  @override
  String get online => 'En ligne';

  @override
  String get offline => 'Hors ligne';
}
