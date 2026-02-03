// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'توسيل';

  @override
  String get welcome => 'مرحبا';

  @override
  String get loginSubtitle =>
      'قم بتسجيل الدخول إلى حساب Rider الخاص بك باستخدام بيانات اعتمادك.';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get usernameHint => 'أدخل معرفك';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get termsAndConditions => 'بتسجيل الدخول، فإنك تقبل شروط الاستخدام';

  @override
  String get becomePartner => 'كن شريك توصيل →';

  @override
  String get signUpTitle => 'كن شريك توصيل';

  @override
  String get signUpSubtitle =>
      'التوصيل مع توسيلة، هو إدارة نشاطك بشكل مستقل وزيادة دخلك بفضل التطبيق الرائد في السوق.';

  @override
  String get firstName => 'الاسم الأول';

  @override
  String get firstNameHint => 'أدخل اسمك الأول';

  @override
  String get lastName => 'الاسم';

  @override
  String get lastNameHint => 'أدخل اسمك';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get phoneNumberHint => 'رقم الهاتف';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailHint => 'أدخل بريدك الإلكتروني';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get confirmPasswordHint => 'أكد كلمة المرور';

  @override
  String get willaya => 'الولاية';

  @override
  String get zone => 'المنطقة';

  @override
  String get signUp => 'التسجيل';

  @override
  String get signUpTerms => 'بالتسجيل في توسيلة تقبل شروط الاستخدام';

  @override
  String get errorUsernameRequired => 'اسم المستخدم مطلوب';

  @override
  String get errorPasswordRequired => 'كلمة المرور مطلوبة';

  @override
  String get errorFirstNameRequired => 'الاسم الأول مطلوب';

  @override
  String get errorLastNameRequired => 'الاسم مطلوب';

  @override
  String get errorPhoneNumberRequired => 'رقم الهاتف مطلوب';

  @override
  String get errorEmailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get errorConfirmPasswordRequired => 'يرجى تأكيد كلمة المرور';

  @override
  String get errorPasswordMismatch => 'كلمات المرور غير متطابقة';

  @override
  String get errorWillayaRequired => 'الولاية مطلوبة';

  @override
  String get errorZoneRequired => 'المنطقة مطلوبة';

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

  @override
  String get delivery => 'التوصيل';

  @override
  String get restaurant => 'المطعم';

  @override
  String get minutesShort => 'د';

  @override
  String get taskDetails => 'تفاصيل المهمة';

  @override
  String get arrive => 'وصل';

  @override
  String get delivered => 'تم التوصيل';

  @override
  String get cancel => 'إلغاء';

  @override
  String get cancelOrderQuestion => 'لماذا تريد إلغاء هذا الطلب؟';

  @override
  String get cancelReasonDriverLate => 'استغرق السائق وقتًا طويلاً للوصول';

  @override
  String get cancelReasonClientCanceled => 'ألغى العميل طلبه';

  @override
  String get cancelReasonTechnicalIssue => 'مشكلة تقنية مع الطلب';

  @override
  String get cancelReasonOther => 'سبب آخر';

  @override
  String get confirm => 'تأكيد';

  @override
  String get orderNotFound => 'الطلب غير موجود';

  @override
  String get clientOrderTitle => 'طلب العميل';

  @override
  String get total => 'الإجمالي';

  @override
  String get clientLabel => 'العميل';

  @override
  String get startDelivery => 'بدء التوصيل';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get myPromotions => 'عروضي';

  @override
  String get paymentMethods => 'طرق الدفع';

  @override
  String get messages => 'الرسائل';

  @override
  String get inviteFriends => 'دعوة أصدقاء';

  @override
  String get security => 'الحماية';

  @override
  String get manageAccount => 'إدارة حسابك';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get rating => 'التقييم';

  @override
  String get deliveries => 'التوصيلات';

  @override
  String get yearsJoined => 'سنوات الانضمام';

  @override
  String get logoutConfirmation => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get ok => 'موافق';

  @override
  String get orderHistory => 'سجل الطلبات';

  @override
  String get all => 'الكل';

  @override
  String get statusOngoing => 'جارية';

  @override
  String get statusDelivered => 'تم التسليم';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get noOrdersYet => 'لا توجد طلبات حتى الآن';

  @override
  String get startOrderingNow => 'ابدأ الطلب الآن';

  @override
  String get todayLabel => 'اليوم';

  @override
  String get yesterdayLabel => 'أمس';

  @override
  String get details => 'التفاصيل';

  @override
  String get trackOrder => 'تتبع الطلب';

  @override
  String get from => 'من:';

  @override
  String get to => 'إلى:';

  @override
  String get viewDetails => 'عرض التفاصيل';
}
