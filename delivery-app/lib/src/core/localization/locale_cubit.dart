import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:equatable/equatable.dart';

class LocaleState extends Equatable {
  final Locale locale;

  const LocaleState(this.locale);

  @override
  List<Object> get props => [locale];

  Map<String, dynamic> toJson() {
    return {
      'languageCode': locale.languageCode,
      'countryCode': locale.countryCode,
    };
  }

  factory LocaleState.fromJson(Map<String, dynamic> json) {
    return LocaleState(
      Locale(json['languageCode'] as String, json['countryCode'] as String?),
    );
  }
}

class LocaleCubit extends HydratedCubit<LocaleState> {
  LocaleCubit() : super(const LocaleState(Locale('fr', 'FR')));

  @override
  LocaleState? fromJson(Map<String, dynamic> json) {
    try {
      return LocaleState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(LocaleState state) {
    return state.toJson();
  }

  void setLocale(Locale locale) {
    emit(LocaleState(locale));
  }

  void setArabic() => setLocale(const Locale('ar', 'DZ'));
  void setFrench() => setLocale(const Locale('fr', 'FR'));
  void setEnglish() => setLocale(const Locale('en', 'US'));
}
