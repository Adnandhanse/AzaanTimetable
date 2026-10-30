import 'package:cloud_functions/cloud_functions.dart';
import 'app_strings.dart';

/// Keep backend details and stack traces out of the OTP screen.
String registrationOperationError(Object error) {
  if (error is FirebaseFunctionsException) {
    switch (error.code) {
      case 'not-found':
        return S.tr('Phone verified. Registration is temporarily unavailable. Please contact the platform admin. [REG-SERVICE]',
            'فون کی تصدیق ہو گئی۔ رجسٹریشن ابھی دستیاب نہیں۔ پلیٹ فارم ایڈمن سے رابطہ کریں۔ [REG-SERVICE]');
      case 'already-exists':
        return S.tr('This masjid is already registered. Sign in or request an admin transfer.',
            'یہ مسجد پہلے سے رجسٹر ہے۔ لاگ اِن کریں یا ایڈمن کی منتقلی کی درخواست دیں۔');
      case 'unauthenticated':
        return S.tr('Please verify your mobile number again to continue.', 'جاری رکھنے کے لیے موبائل نمبر کی دوبارہ تصدیق کریں۔');
      case 'unavailable':
      case 'deadline-exceeded':
        return S.tr('Phone verified. Registration could not finish. Check your connection and try again.',
            'فون کی تصدیق ہو گئی۔ رجسٹریشن مکمل نہیں ہو سکی۔ انٹرنیٹ دیکھیں اور دوبارہ کوشش کریں۔');
      case 'permission-denied':
        return S.tr('Phone verified, but registration is not permitted. Contact the platform admin. [REG-ACCESS]',
            'فون کی تصدیق ہو گئی مگر رجسٹریشن کی اجازت نہیں ملی۔ پلیٹ فارم ایڈمن سے رابطہ کریں۔ [REG-ACCESS]');
    }
  }
  return S.tr('Phone verified, but registration could not finish. Please try again or contact the platform admin.',
      'فون کی تصدیق ہو گئی مگر رجسٹریشن مکمل نہیں ہو سکی۔ دوبارہ کوشش کریں یا پلیٹ فارم ایڈمن سے رابطہ کریں۔');
}
