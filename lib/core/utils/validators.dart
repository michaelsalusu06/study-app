import '../constants/app_strings.dart';

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (!value.contains('@')) return AppStrings.invalidEmail;
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value.length < 6) return AppStrings.passwordTooShort;
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value != original) return AppStrings.passwordNotMatch;
    return null;
  }

  static String? required(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    return null;
  }
}
