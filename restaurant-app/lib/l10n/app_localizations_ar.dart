// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'توصيل';

  @override
  String get welcome => 'مرحبا';

  @override
  String get loginSubtitle =>
      'قم بتسجيل الدخول باستخدام عنوان بريدك الإلكتروني وكلمة مرور متجرك';

  @override
  String get emailAddress => 'عنوان البريد الإلكتروني';

  @override
  String get emailAddressHint => 'أدخل عنوان بريدك الإلكتروني';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailHint => 'أدخل بريدك الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get termsAndConditions =>
      'بتسجيل الدخول، أنت تقبل شروط الاستخدام الخاصة بنا';

  @override
  String get becomePartner => 'كن شريكًا →';

  @override
  String get signUpTitle => 'كن سائق توصيل - شريك';

  @override
  String get signUpSubtitle =>
      'كن شريكًا وأدر مطعمك بشكل مستقل. زد من ظهورك ودخلك بفضل توصيل';

  @override
  String get restaurantName => 'اسم المطعم';

  @override
  String get restaurantNameHint => 'أدخل اسم مطعمك';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get phoneNumberHint => 'رقم الهاتف';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get confirmPasswordHint => 'أكد كلمة المرور';

  @override
  String get restaurantType => 'اختر نوع المطعم';

  @override
  String get restaurantTypeHint => 'اختر النوع';

  @override
  String get willaya => 'الولاية';

  @override
  String get willayaHint => 'اختر الولاية';

  @override
  String get zone => 'المنطقة';

  @override
  String get zoneHint => 'اختر المنطقة';

  @override
  String get description => 'الوصف';

  @override
  String get descriptionHint => 'صف مطعمك';

  @override
  String get address => 'العنوان';

  @override
  String get addressHint => 'أدخل العنوان الكامل';

  @override
  String get locationSearchLabel => 'موقع المطعم';

  @override
  String get locationSearchHint => 'ابحث بالعنوان أو المنطقة';

  @override
  String get locationSearchButton => 'ابحث';

  @override
  String get locationLatitudeLabel => 'خط العرض';

  @override
  String get locationLongitudeLabel => 'خط الطول';

  @override
  String get signUp => 'التسجيل';

  @override
  String get signUpTerms => 'بالتسجيل في توصيل، أنت تقبل شروط الاستخدام';

  @override
  String get errorEmailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get errorPasswordRequired => 'كلمة المرور مطلوبة';

  @override
  String get errorRestaurantNameRequired => 'اسم المطعم مطلوب';

  @override
  String get errorPhoneNumberRequired => 'رقم الهاتف مطلوب';

  @override
  String get errorConfirmPasswordRequired => 'يرجى تأكيد كلمة المرور';

  @override
  String get errorPasswordMismatch => 'كلمات المرور غير متطابقة';

  @override
  String get errorRestaurantTypeRequired => 'نوع المطعم مطلوب';

  @override
  String get errorWillayaRequired => 'الولاية مطلوبة';

  @override
  String get errorZoneRequired => 'المنطقة مطلوبة';

  @override
  String get errorDescriptionRequired => 'الوصف مطلوب';

  @override
  String get errorLocationRequired => 'يرجى البحث عن موقع المطعم';

  @override
  String get errorLocationNotFound => 'لم يتم العثور على موقع مطابق';

  @override
  String get errorLocationLookupFailed => 'تعذر جلب الموقع، أعد المحاولة';

  @override
  String get errorLoginFailed => 'فشل تسجيل الدخول';

  @override
  String get errorRegistrationFailed => 'فشل التسجيل';

  @override
  String get errorLogoutFailed => 'فشل تسجيل الخروج';

  @override
  String get home => 'الرئيسية';

  @override
  String get homeTitle => 'تبدأ توصيلاتك من هنا!';

  @override
  String get homeSubtitle =>
      'استقبل طلباتك، اتبع العناوين وقدم خدمة استثنائية في وقت قياسي.';

  @override
  String get getOrders => 'الحصول على الطلبات';

  @override
  String get orders => 'الطلبات';

  @override
  String orderTitle(String id) {
    return 'طلب #$id';
  }

  @override
  String get orderNumberLabel => 'رقم الطلب';

  @override
  String get deliveryTime => 'وقت التوصيل';

  @override
  String get minutes => 'دقيقة';

  @override
  String get distance => 'المسافة';

  @override
  String get kilometers => 'كم';

  @override
  String get deliveryPrice => 'سعر التوصيل';

  @override
  String get totalPrice => 'السعر الإجمالي';

  @override
  String get refuse => 'رفض';

  @override
  String get accept => 'قبول';

  @override
  String get noOrders => 'لا توجد طلبات';

  @override
  String get noPendingOrders => 'ليس لديك أي طلبات قيد الانتظار';

  @override
  String get error => 'خطأ';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get orderAcceptedSuccess => 'تم قبول الطلب بنجاح';

  @override
  String get orderRefusedSuccess => 'تم رفض الطلب بنجاح';

  @override
  String get errorInvalidResponseFormat => 'تنسيق الاستجابة غير صالح';

  @override
  String get errorFailedToFetchOrders => 'فشل في جلب الطلبات';

  @override
  String get errorFailedToAcceptOrder => 'فشل في قبول الطلب';

  @override
  String errorAcceptingOrder(String error) {
    return 'خطأ في قبول الطلب: $error';
  }

  @override
  String get errorFailedToRefuseOrder => 'فشل في رفض الطلب';

  @override
  String errorRefusingOrder(String error) {
    return 'خطأ في رفض الطلب: $error';
  }
}
