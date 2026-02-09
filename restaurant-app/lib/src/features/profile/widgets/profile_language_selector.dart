import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/localization/locale_cubit.dart';

class ProfileLanguageSelector extends StatelessWidget {
  const ProfileLanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            localizations.language,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, state) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Locale>(
                    value: state.locale,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        context.read<LocaleCubit>().setLocale(newLocale);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: const Locale('fr', 'FR'),
                        child: Text(localizations.french),
                      ),
                      DropdownMenuItem(
                        value: const Locale('ar', 'DZ'),
                        child: Text(localizations.arabic),
                      ),
                      DropdownMenuItem(
                        value: const Locale('en', 'US'),
                        child: Text(localizations.english),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
