import 'package:client_app/src/core/res/color_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/core/localization/locale_cubit.dart';

class LanguageSelectorWidget extends StatelessWidget {
  const LanguageSelectorWidget({super.key});

  String _getCurrentLanguageName(BuildContext context) {
    final localeCubit = context.read<LocaleCubit>();
    final currentLocale = localeCubit.state.locale;
    final l10n = AppLocalizations.of(context)!;
    switch (currentLocale.languageCode) {
      case 'ar':
        return l10n.arabic;
      case 'fr':
        return l10n.french;
      case 'en':
        return l10n.english;
      default:
        return l10n.english;
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCubit = context.read<LocaleCubit>();
    final currentLocale = localeCubit.state.locale;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              dialogContext,
              locale: const Locale('ar', 'DZ'),
              label: l10n.arabic,
              flag: '🇩🇿',
              isSelected: currentLocale.languageCode == 'ar',
              onTap: () {
                localeCubit.setArabic();
                Navigator.pop(dialogContext);
              },
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              dialogContext,
              locale: const Locale('fr', 'FR'),
              label: l10n.french,
              flag: '🇫🇷',
              isSelected: currentLocale.languageCode == 'fr',
              onTap: () {
                localeCubit.setFrench();
                Navigator.pop(dialogContext);
              },
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              dialogContext,
              locale: const Locale('en', 'US'),
              label: l10n.english,
              flag: '🇬🇧',
              isSelected: currentLocale.languageCode == 'en',
              onTap: () {
                localeCubit.setEnglish();
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required Locale locale,
    required String label,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF006C4A).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? ColorApp.primary : ColorApp.white,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: ColorApp.textBlack,
                  ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? ColorApp.primary : ColorApp.textBlack,
                    ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: ColorApp.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () => _showLanguageDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.language,
                color: ColorApp.textBlack,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.language,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: ColorApp.textBlack,
                      ),
                ),
              ),
              BlocBuilder<LocaleCubit, LocaleState>(
                builder: (context, state) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ColorApp.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ColorApp.greyBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getCurrentLanguageName(context),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: ColorApp.textBlack,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: ColorApp.textBlack,
                          size: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
