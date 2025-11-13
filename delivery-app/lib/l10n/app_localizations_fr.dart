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
}
