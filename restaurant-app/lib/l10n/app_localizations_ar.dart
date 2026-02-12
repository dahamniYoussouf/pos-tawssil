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
  String get termsPrefix => 'بتسجيل الدخول، أنت تقبل\n';

  @override
  String get termsLabel => 'شروط الاستخدام';

  @override
  String get termsAnd => ' و ';

  @override
  String get privacyPolicyLabel => 'سياسة الخصوصية';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟ ';

  @override
  String get signUpAction => 'سجل الآن';

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
  String get pendingStatus => 'قيد الانتظار';

  @override
  String get ongoingStatus => 'جارية';

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
  String get statisticsTitle => 'الإحصائيات';

  @override
  String get statistics => 'الإحصائيات';

  @override
  String get today => 'اليوم';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get custom => 'مخصص';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get apply => 'تطبيق';

  @override
  String get statusLabel => 'الحالة:';

  @override
  String get all => 'الكل';

  @override
  String get accepted => 'مقبول';

  @override
  String get preparing => 'قيد التحضير';

  @override
  String get delivering => 'قيد التوصيل';

  @override
  String get delivered => 'تم التوصيل';

  @override
  String get pickedUp => 'تم الاستلام';

  @override
  String get priceRangeLabel => 'نطاق السعر:';

  @override
  String get minPrice => 'الحد الأدنى (دج)';

  @override
  String get maxPrice => 'الحد الأقصى (دج)';

  @override
  String get totalOrders => 'إجمالي الطلبات';

  @override
  String get totalRevenue => 'إجمالي الإيرادات';

  @override
  String get averageValue => 'القيمة المتوسطة';

  @override
  String get deliveredOrders => 'الطلبات المسلمة';

  @override
  String get ordersByStatus => 'الطلبات حسب الحالة';

  @override
  String get revenueByStatus => 'الإيرادات حسب الحالة';

  @override
  String get noDataAvailable => 'لا توجد بيانات متاحة';

  @override
  String get errorDateRangeRequired => 'يرجى تحديد نطاق تاريخ';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get restaurantDetails => 'تفاصيل المطعم';

  @override
  String get restaurantInformation => 'معلومات المطعم';

  @override
  String get restaurantInfoPlaceholder => 'ستظهر معلومات مطعمك هنا';

  @override
  String get categories => 'الفئات';

  @override
  String get createCategory => 'إنشاء فئة';

  @override
  String get editCategory => 'تعديل الفئة';

  @override
  String get createMenuItem => 'إنشاء عنصر قائمة';

  @override
  String get categoryName => 'اسم الفئة';

  @override
  String get categoryNameHint => 'أدخل اسم الفئة';

  @override
  String get categoryNameRequired => 'اسم الفئة مطلوب';

  @override
  String get descriptionRequired => 'الوصف مطلوب';

  @override
  String get iconUrl => 'رابط الأيقونة';

  @override
  String get iconUrlHint => 'أدخل رابط الأيقونة';

  @override
  String get iconUrlRequired => 'رابط الأيقونة مطلوب';

  @override
  String get invalidUrl => 'تنسيق رابط غير صالح';

  @override
  String get displayOrder => 'ترتيب العرض';

  @override
  String get displayOrderHint => 'أدخل ترتيب العرض';

  @override
  String get displayOrderRequired => 'ترتيب العرض مطلوب';

  @override
  String get invalidDisplayOrder => 'يجب أن يكون ترتيب العرض رقماً موجباً';

  @override
  String get create => 'إنشاء';

  @override
  String get update => 'تحديث';

  @override
  String get delete => 'حذف';

  @override
  String get cancel => 'إلغاء';

  @override
  String get deleteCategory => 'حذف الفئة';

  @override
  String get deleteCategoryConfirmation => 'هل أنت متأكد من حذف هذه الفئة؟';

  @override
  String get noCategories => 'لا توجد فئات متاحة';

  @override
  String get searchHint => 'ابحث هنا...';

  @override
  String get menuItems => 'عناصر القائمة';

  @override
  String get noMenuItems => 'لا توجد عناصر قائمة متاحة';

  @override
  String get editMenuItem => 'تعديل عنصر القائمة';

  @override
  String get itemName => 'اسم العنصر';

  @override
  String get itemNameHint => 'أدخل اسم العنصر';

  @override
  String get itemNameRequired => 'اسم العنصر مطلوب';

  @override
  String get price => 'السعر';

  @override
  String get priceHint => 'أدخل السعر';

  @override
  String get priceRequired => 'السعر مطلوب';

  @override
  String get invalidPrice => 'يجب أن يكون السعر رقماً موجباً';

  @override
  String get preparationTime => 'وقت التحضير (دقيقة)';

  @override
  String get preparationTimeHint => 'أدخل وقت التحضير بالدقائق';

  @override
  String get preparationTimeRequired => 'وقت التحضير مطلوب';

  @override
  String get invalidPreparationTime => 'يجب أن يكون وقت التحضير رقماً موجباً';

  @override
  String get ingredients => 'المكونات';

  @override
  String get ingredientsHint => 'أدخل المكونات (اختياري)';

  @override
  String get allergens => 'مسببات الحساسية';

  @override
  String get allergensHint => 'أدخل مسببات الحساسية (اختياري)';

  @override
  String get category => 'الفئة';

  @override
  String get categoryHint => 'اختر الفئة';

  @override
  String get categoryRequired => 'الفئة مطلوبة';

  @override
  String get selectImage => 'اختر الصورة';

  @override
  String get uploadImage => 'رفع الصورة';

  @override
  String get imageUploading => 'جاري رفع الصورة...';

  @override
  String get imageUploadSuccess => 'تم رفع الصورة بنجاح';

  @override
  String get imageUploadError => 'فشل رفع الصورة';

  @override
  String get available => 'متاح';

  @override
  String get deleteMenuItem => 'حذف عنصر القائمة';

  @override
  String get deleteMenuItemConfirmation =>
      'هل أنت متأكد من حذف عنصر القائمة هذا?';

  @override
  String get orderHistory => 'سجل الطلبات';

  @override
  String get noOrdersFound => 'لم يتم العثور على طلبات';

  @override
  String get noOrdersFoundWithFilters =>
      'لم يتم العثور على طلبات تطابق المرشحات المحددة';

  @override
  String get filters => 'المرشحات';

  @override
  String get orderTypeLabel => 'نوع الطلب';

  @override
  String get dateRangeLabel => 'الفترة';

  @override
  String get dateFromLabel => 'من';

  @override
  String get dateToLabel => 'إلى';

  @override
  String get priceLabel => 'السعر';

  @override
  String get deliveryOrderType => 'توصيل';

  @override
  String get pickupOrderType => 'استلام';

  @override
  String get unknownClient => 'عميل غير معروف';

  @override
  String get details => 'التفاصيل';

  @override
  String get contact => 'اتصال';

  @override
  String get settings => 'الإعدادات';

  @override
  String get manageProfile => 'إدارة ملفك الشخصي';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get printerSettings => 'إعدادات الطابعة';

  @override
  String get aboutUs => 'من نحن';

  @override
  String get openStatus => 'مفتوح';

  @override
  String get closedStatus => 'مغلق';

  @override
  String restaurantIdLabel(String id) {
    return 'معرف المطعم : $id';
  }

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get french => 'الفرنسية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get language => 'اللغة';

  @override
  String get menu => 'القائمة';

  @override
  String get createCategoryFirst => 'يرجى إنشاء فئة أولاً';

  @override
  String get uploadImageFirst => 'يرجى رفع الصورة أولاً';

  @override
  String get errorPickingImage => 'خطأ أثناء اختيار الصورة';

  @override
  String get deliveryApp => 'تطبيق التوصيل';

  @override
  String get pos => 'نقاط البيع';

  @override
  String get success => 'ناجح';

  @override
  String get cancelled => 'ملغي';

  @override
  String get listOfCategories => 'قائمة الفئات';

  @override
  String get listOfProducts => 'قائمة المنتجات';

  @override
  String get searchForStoreOrProducts => 'البحث عن متجر أو منتجات';

  @override
  String articlesCount(int count) {
    return '$count عناصر';
  }

  @override
  String get products => 'المنتجات';

  @override
  String get payment => 'الدفع';

  @override
  String get orderDetails => 'تفاصيل الطلب';

  @override
  String get orderContent => 'محتوى الطلب';

  @override
  String get paymentType => 'نوع الدفع';

  @override
  String get initialPrice => 'السعر الأولي';

  @override
  String get deliveryManMustPay => 'يجب على السائق دفعه';

  @override
  String get receivedOrder => 'تم استلام الطلب';

  @override
  String get acceptedByDelivery => 'تم القبول من طرف السائق';

  @override
  String get printReceipt => 'طبع التذكرة';

  @override
  String get statusOpen => 'مفتوح';

  @override
  String get statusBusy => 'مشغول';

  @override
  String get statusClosed => 'مغلق';

  @override
  String get statusOpenSubtitle => 'قبول الطلبات';

  @override
  String get statusBusySubtitle => 'مغلق لمدة ساعة';

  @override
  String get statusClosedSubtitle => 'مغلق طوال اليوم';

  @override
  String get closeRestaurantTitle => 'إغلاق متجرك لمدة';

  @override
  String get restaurantProfileTitle => 'الملف الشخصي للمطعم';

  @override
  String get establishmentInformation => 'معلومات المنشأة';

  @override
  String get openingHours => 'ساعات العمل';

  @override
  String get categoriesYouOffer => 'الفئات التي تقدمها';

  @override
  String get vitrinePhoto => 'صورة الواجهة';

  @override
  String get updatePhoto => 'تحديث الصورة';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get approvedStatus => 'معتمد';

  @override
  String get addressMini => 'العنوان';

  @override
  String get phoneMini => 'الهاتف';

  @override
  String get emailMini => 'البريد الإلكتروني';

  @override
  String get change => 'تغيير';

  @override
  String get modifier => 'تعديل';

  @override
  String get gerer => 'إدارة';

  @override
  String get monday => 'الاثنين';

  @override
  String get tuesday => 'الثلاثاء';

  @override
  String get wednesday => 'الأربعاء';

  @override
  String get thursday => 'الخميس';

  @override
  String get friday => 'الجمعة';

  @override
  String get saturday => 'السبت';

  @override
  String get sunday => 'الأحد';

  @override
  String get optionGroupTitleEdit => 'تعديل المجموعة';

  @override
  String get optionGroupTitleAdd => 'إضافة مجموعة';

  @override
  String get optionGroupNameLabel => 'اسم المجموعة *';

  @override
  String get optionGroupNameHint => 'أدخل اسم المجموعة';

  @override
  String get optionGroupNameRequired => 'اسم المجموعة مطلوب';

  @override
  String get optionGroupRequired => 'إلزامي';

  @override
  String get optionGroupOptional => 'اختياري';

  @override
  String get optionGroupMultipleChoice => 'اختيار متعدد';

  @override
  String get multipleChoice => 'متعدد';

  @override
  String get optionGroupOptions => 'الخيارات';

  @override
  String get optionOptionNameLabel => 'اسم الخيار';

  @override
  String get optionAdd => '+ إضافة خيار';

  @override
  String get optionGroupButtonSave => 'حفظ';

  @override
  String get optionGroupButtonAdd => 'إضافة';

  @override
  String get optionGroupDeleteGroup => 'حذف المجموعة';

  @override
  String get optionGroupDeleteConfirmation =>
      'هل أنت متأكد أنك تريد حذف مجموعة الخيارات هذه؟';

  @override
  String get optionGroupDeleteOptionTooltip => 'إزالة الخيار';

  @override
  String get errorOptionGroupAddOne => 'أضف خيارًا واحدًا على الأقل';

  @override
  String get option => 'خيار';

  @override
  String get options => 'خيارات';

  @override
  String get singleChoice => 'واحد';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get fromGalleryOrCamera => 'من المعرض أو الكاميرا';

  @override
  String get select => 'اختر';

  @override
  String get itemActive => 'عنصر نشط';

  @override
  String get add => 'إضافة';

  @override
  String get addMenuItem => 'إضافة عنصر';

  @override
  String get itemNameLabel => 'اسم العنصر';

  @override
  String get optionGroups => 'مجموعات الخيارات';

  @override
  String get addOptionGroup => '+ إضافة مجموعة خيار';
}
