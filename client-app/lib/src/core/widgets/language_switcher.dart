import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import '../localization/locale_cubit.dart';
import 'package:client_app/src/core/res/color_app.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({Key? key}) : super(key: key);

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
              ? ColorApp.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? ColorApp.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? ColorApp.primary : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
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
    return IconButton(
      icon: const Icon(Icons.language),
      onPressed: () => _showLanguageDialog(context),
      tooltip: AppLocalizations.of(context)!.language,
    );
  }
}
