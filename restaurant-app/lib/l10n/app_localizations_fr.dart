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
  String get termsPrefix => 'En vous connectant, vous acceptez nos\n';

  @override
  String get termsLabel => 'Conditions D’utilisation';

  @override
  String get termsAnd => ' et ';

  @override
  String get privacyPolicyLabel => 'Politique De Confidentialité';

  @override
  String get rememberMe => 'Rester connecté(e)';

  @override
  String get forgotPassword => 'Mot de passe oublié?';

  @override
  String get dontHaveAccount => 'Vous n’avez pas encore de compte? ';

  @override
  String get signUpAction => 'Inscrivez-vous';

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
  String get descriptionHint => 'Entrez la description';

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

  @override
  String get statisticsTitle => 'Statistiques';

  @override
  String get statistics => 'Statistiques';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get thisMonth => 'Ce mois';

  @override
  String get custom => 'Personnalisé';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get apply => 'Appliquer';

  @override
  String get statusLabel => 'Statut:';

  @override
  String get all => 'Tous';

  @override
  String get accepted => 'Accepté';

  @override
  String get preparing => 'En préparation';

  @override
  String get delivering => 'En livraison';

  @override
  String get delivered => 'Livré';

  @override
  String get pickedUp => 'Récupéré';

  @override
  String get priceRangeLabel => 'Plage de prix:';

  @override
  String get minPrice => 'Min (DA)';

  @override
  String get maxPrice => 'Max (DA)';

  @override
  String get totalOrders => 'Total Commandes';

  @override
  String get totalRevenue => 'Revenu Total';

  @override
  String get averageValue => 'Valeur Moyenne';

  @override
  String get deliveredOrders => 'Commandes Livrées';

  @override
  String get ordersByStatus => 'Commandes par Statut';

  @override
  String get revenueByStatus => 'Revenu par Statut';

  @override
  String get noDataAvailable => 'Aucune donnée disponible';

  @override
  String get errorDateRangeRequired =>
      'Veuillez sélectionner une plage de dates';

  @override
  String get logout => 'Déconnexion';

  @override
  String get restaurantDetails => 'Détails du Restaurant';

  @override
  String get restaurantInformation => 'Informations du Restaurant';

  @override
  String get restaurantInfoPlaceholder =>
      'Les informations de votre restaurant seront affichées ici';

  @override
  String get categories => 'Catégories';

  @override
  String get createCategory => 'Créer une Catégorie';

  @override
  String get editCategory => 'Modifier la Catégorie';

  @override
  String get createMenuItem => 'Créer un Article du Menu';

  @override
  String get categoryName => 'Nom de la Catégorie';

  @override
  String get categoryNameHint => 'Entrez le nom de la catégorie';

  @override
  String get categoryNameRequired => 'Le nom de la catégorie est requis';

  @override
  String get descriptionRequired => 'La description est requise';

  @override
  String get iconUrl => 'URL de l\'Icône';

  @override
  String get iconUrlHint => 'Entrez l\'URL de l\'icône';

  @override
  String get iconUrlRequired => 'L\'URL de l\'icône est requise';

  @override
  String get invalidUrl => 'Format d\'URL invalide';

  @override
  String get displayOrder => 'Ordre d\'Affichage';

  @override
  String get displayOrderHint => 'Entrez l\'ordre d\'affichage';

  @override
  String get displayOrderRequired => 'L\'ordre d\'affichage est requis';

  @override
  String get invalidDisplayOrder =>
      'L\'ordre d\'affichage doit être un nombre positif';

  @override
  String get create => 'Créer';

  @override
  String get update => 'Mettre à jour';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get deleteCategory => 'Supprimer la Catégorie';

  @override
  String get deleteCategoryConfirmation =>
      'Êtes-vous sûr de vouloir supprimer cette catégorie?';

  @override
  String get noCategories => 'Aucune catégorie disponible';

  @override
  String get searchHint => 'Rechercher ici...';

  @override
  String get menuItems => 'Articles du Menu';

  @override
  String get noMenuItems => 'Aucun article du menu disponible';

  @override
  String get editMenuItem => 'Modifier l\'Article du Menu';

  @override
  String get itemName => 'Nom de l\'Article';

  @override
  String get itemNameHint => 'Entrez le nom de l\'article';

  @override
  String get itemNameRequired => 'Le nom de l\'article est requis';

  @override
  String get price => 'Prix';

  @override
  String get priceHint => 'Entrez le prix';

  @override
  String get priceRequired => 'Le prix est requis';

  @override
  String get invalidPrice => 'Le prix doit être un nombre positif';

  @override
  String get preparationTime => 'Temps de Préparation (minutes)';

  @override
  String get preparationTimeHint => 'Entrez le temps de préparation en minutes';

  @override
  String get preparationTimeRequired => 'Le temps de préparation est requis';

  @override
  String get invalidPreparationTime =>
      'Le temps de préparation doit être un nombre positif';

  @override
  String get ingredients => 'Ingrédients';

  @override
  String get ingredientsHint => 'Entrez les ingrédients (optionnel)';

  @override
  String get allergens => 'Allergènes';

  @override
  String get allergensHint => 'Entrez les allergènes (optionnel)';

  @override
  String get category => 'Catégorie';

  @override
  String get categoryHint => 'Sélectionnez la catégorie';

  @override
  String get categoryRequired => 'La catégorie est requise';

  @override
  String get selectImage => 'Sélectionner une Image';

  @override
  String get uploadImage => 'Télécharger l\'Image';

  @override
  String get imageUploading => 'Téléchargement de l\'image...';

  @override
  String get imageUploadSuccess => 'Image téléchargée avec succès';

  @override
  String get imageUploadError => 'Échec du téléchargement de l\'image';

  @override
  String get available => 'Disponible';

  @override
  String get deleteMenuItem => 'Supprimer l\'Article du Menu';

  @override
  String get deleteMenuItemConfirmation =>
      'Êtes-vous sûr de vouloir supprimer cet article du menu?';

  @override
  String get orderHistory => 'Historique des commandes';

  @override
  String get noOrdersFound => 'Aucune commande trouvée';

  @override
  String get noOrdersFoundWithFilters =>
      'Aucune commande trouvée correspondant à vos filtres';

  @override
  String get filters => 'Filtres';

  @override
  String get orderTypeLabel => 'Type de commande';

  @override
  String get dateRangeLabel => 'Période';

  @override
  String get dateFromLabel => 'De';

  @override
  String get dateToLabel => 'À';

  @override
  String get priceLabel => 'Prix';

  @override
  String get deliveryOrderType => 'Livraison';

  @override
  String get pickupOrderType => 'À emporter';

  @override
  String get unknownClient => 'Client inconnu';

  @override
  String get details => 'Détails';

  @override
  String get contact => 'Contacter';

  @override
  String get settings => 'Paramètre';

  @override
  String get manageProfile => 'Gérez Votre Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get printerSettings => 'Configuration Imprimante';

  @override
  String get aboutUs => 'A Propos De Nous';

  @override
  String get openStatus => 'Ouvert';

  @override
  String get closedStatus => 'Fermé';

  @override
  String restaurantIdLabel(String id) {
    return 'Restaurant ID : $id';
  }

  @override
  String get selectLanguage => 'Choisir la langue';

  @override
  String get arabic => 'Arabe';

  @override
  String get french => 'Français';

  @override
  String get english => 'Anglais';

  @override
  String get language => 'Langue';

  @override
  String get menu => 'Menu';

  @override
  String get createCategoryFirst => 'Veuillez d\'abord créer une catégorie';

  @override
  String get uploadImageFirst => 'Veuillez d\'abord télécharger l\'image';

  @override
  String get errorPickingImage => 'Erreur lors de la sélection de l\'image';
}
