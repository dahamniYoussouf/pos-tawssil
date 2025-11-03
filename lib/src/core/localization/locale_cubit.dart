import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equatable/equatable.dart';

class LocaleState extends Equatable {
  final Locale locale;

  const LocaleState(this.locale);

  @override
  List<Object> get props => [locale];
}

class LocaleCubit extends Cubit<LocaleState> {
  static const String _localeKey = 'app_locale';

  LocaleCubit() : super(const LocaleState(Locale('fr', 'FR'))) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);
      if (localeCode != null) {
        final locale = _parseLocale(localeCode);
        emit(LocaleState(locale));
      }
    } catch (e) {
      // Error loading locale
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, '${locale.languageCode}_${locale.countryCode}');
      emit(LocaleState(locale));
    } catch (e) {
      // Error saving locale
    }
  }

  Locale _parseLocale(String localeCode) {
    final parts = localeCode.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }

  void setArabic() => setLocale(const Locale('ar', 'DZ'));
  void setFrench() => setLocale(const Locale('fr', 'FR'));
  void setEnglish() => setLocale(const Locale('en', 'US'));
}
