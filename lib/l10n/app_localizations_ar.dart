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
  String get addPhoneNumber => 'أضف رقم هاتفك';

  @override
  String get phoneNumberSubtitle => 'لتسجيل الدخول أو التسجيل، أدخل رقم هاتفك.';

  @override
  String get phoneNumberHint => 'رقم الهاتف';

  @override
  String get connect => 'اتصال';

  @override
  String get home => 'الرئيسية';

  @override
  String get favorites => 'المفضلة';

  @override
  String get history => 'السجل';

  @override
  String get cart => 'السلة';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get cartTitle => 'السلة';

  @override
  String get deliveryAddress => 'عنوان التسليم';

  @override
  String products(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منتجات',
      one: 'منتج',
      zero: 'منتجات',
    );
    return '$_temp0';
  }

  @override
  String get deliveryFee => 'رسوم التسليم';

  @override
  String get estimatedTime => 'الوقت المقدر';

  @override
  String get orderDetails => 'تفاصيل الطلب';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get platformFee => 'رسوم المنصة';

  @override
  String get total => 'الإجمالي';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get cash => 'نقد';

  @override
  String get baridiMob => 'بريدي موب';

  @override
  String get bankTransfer => 'تحويل بنكي';

  @override
  String get deliveryOption => 'خيار التسليم';

  @override
  String get pickup => 'الاستلام من المطعم';

  @override
  String get delivery => 'تسليم';

  @override
  String get verifyAndFinalize => 'التحقق والإنهاء';

  @override
  String get emptyCart => 'سلتك فارغة';

  @override
  String get addProductsToContinue => 'أضف منتجات للمتابعة';

  @override
  String get removeProduct => 'إزالة المنتج';

  @override
  String removeProductConfirmation(String productName) {
    return 'هل تريد إزالة \"$productName\" من السلة؟';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get remove => 'إزالة';

  @override
  String get note => 'ملاحظة';

  @override
  String get enterAddress => 'إدخال عنوان';

  @override
  String get addressHint => 'مثال: 123 شارع الجمهورية، الجزائر';

  @override
  String get confirm => 'تأكيد';

  @override
  String get permissionDenied =>
      'لقد رفضت الإذن. قم بتمكين الموقع في الإعدادات.';

  @override
  String get gpsTimeout => 'تعذر الحصول على موقع GPS (انتهت المهلة).';

  @override
  String get gpsError => 'تعذر الحصول على موقع GPS.';

  @override
  String get locationSendError => 'خطأ في إرسال الموقع. تحقق من اتصالك.';

  @override
  String get addressSendError => 'خطأ في إرسال العنوان. تحقق من اتصالك.';

  @override
  String get error => 'خطأ';

  @override
  String get loadingError => 'خطأ في التحميل';

  @override
  String get gpsDisabled => 'خدمات الموقع معطلة';

  @override
  String get gpsDisabledMessage => 'يرجى تفعيل GPS لمشاركة موقعك معنا.';

  @override
  String get enableGPS => 'تفعيل GPS';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get language => 'اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get french => 'الفرنسية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get shareLocationTitle => 'شارك موقعك معنا';

  @override
  String get shareLocationDescription =>
      'توسيل يستخدم موقعك للعثور على المؤسسات القريبة منك وتوصيل الطلبات بدقة إلى عنوانك';

  @override
  String get shareLocationButton => 'شارك موقعك';

  @override
  String get addAddressButton => 'أضف عنوانًا';

  @override
  String get validateOrder => 'التحقق من الطلب';

  @override
  String get pickupPoint => 'نقطة الاستلام';

  @override
  String get restaurant => 'المطعم';

  @override
  String get destination => 'الوجهة';

  @override
  String get deliveryAddressLabel => 'عنوان التسليم';

  @override
  String get deliveryTime => 'وقت التسليم';

  @override
  String get orderNumber => 'رقم الطلب';

  @override
  String get totalLabel => 'الإجمالي';

  @override
  String totalValue(String total) {
    return '$total دج';
  }

  @override
  String get paymentMethodLabel => 'طريقة الدفع';

  @override
  String get orderDetailsLabel => 'تفاصيل الطلب';

  @override
  String get validate => 'التحقق';

  @override
  String get confirmOrder => 'تأكيد الطلب';

  @override
  String get confirmOrderMessage => 'هل تريد تأكيد هذا الطلب؟';

  @override
  String get payment => 'الدفع';

  @override
  String get orderValidatedSuccessfully => 'تم التحقق من الطلب بنجاح!';

  @override
  String get verificationError => 'خطأ:';

  @override
  String get addToCart => 'إضافة إلى السلة';

  @override
  String get noteForKitchen => 'ملاحظة للمطبخ';

  @override
  String get verification => 'التحقق';

  @override
  String get enterVerificationCode => 'أدخل رمز التحقق';

  @override
  String get weSentCode => 'أرسلنا رمزًا إلى';

  @override
  String get codeComplete => 'يرجى إدخال الرمز الكامل (6 أرقام).';

  @override
  String get verificationErrorMsg => 'خطأ أثناء التحقق:';

  @override
  String get devOtp => 'رمز OTP للاختبار:';

  @override
  String get codeRenvoye => 'تم إعادة إرسال الرمز';

  @override
  String get notReceived => 'لم تتلقى الرمز؟';

  @override
  String get resend => 'إعادة الإرسال';

  @override
  String get verify => 'التحقق';

  @override
  String get verificationSuccessful => 'تم التحقق بنجاح!';

  @override
  String get cartEmptyMessage => 'سلتك فارغة';

  @override
  String get viewCart => 'الاطلاع على السلة';

  @override
  String quantityInCart(int count) {
    return '$count في السلة';
  }

  @override
  String get notAvailable => 'غير متوفر';

  @override
  String get deliveryFeeLabel => 'رسوم التسليم';

  @override
  String get deliveryTimeLabel => 'وقت التسليم';

  @override
  String get switchToPremium => 'انتقل إلى وضع';

  @override
  String get premium => 'بريميوم';

  @override
  String get moreServices => 'المزيد من الخدمات والمزايا';

  @override
  String get addToFavorites => 'تمت الإضافة إلى المفضلة';

  @override
  String get premiumLabel => 'بريميوم';

  @override
  String get loadingRestaurants => 'جاري تحميل المطاعم...';

  @override
  String get categories => 'الفئات';

  @override
  String newToDiscover(int count) {
    return 'جديد لاكتشافه ($count)';
  }

  @override
  String get noRestaurantFound => 'لم يتم العثور على مطعم';

  @override
  String get reload => 'إعادة التحميل';

  @override
  String get searchRestaurantPlaceholder => 'البحث عن المطاعم والطعام...';

  @override
  String get navigationToCart => 'التنقل إلى السلة';

  @override
  String get noRestaurantNear => 'لم يتم العثور على مطعم بالقرب منك.';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get retryAction => 'إعادة المحاولة';

  @override
  String get allowLocation => 'السماح لـ « tawsil » باستخدام موقعك؟';

  @override
  String get locationPurpose =>
      'من أجل الكشف عن الشركاء من حولك، نحتاج إلى استخدام موقعك';

  @override
  String get allowOnce => 'السماح مرة واحدة';

  @override
  String get allowWhenActive => 'السماح عندما يكون التطبيق نشطًا';

  @override
  String get doNotAllow => 'عدم السماح';
}
