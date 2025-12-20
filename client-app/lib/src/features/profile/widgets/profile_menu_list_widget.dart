import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:client_app/src/features/auth/cubit/auth_cubit.dart';
import 'profile_menu_item_widget.dart';

class ProfileMenuListWidget extends StatelessWidget {
  const ProfileMenuListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ProfileMenuItemWidget(
            icon: MediaRes.locationProfileIcon,
            title: l10n.myLocations,
            onTap: () {
              // TODO: Navigate to my locations page
            },
          ),
          Divider(color: ColorApp.greyDivider),
          ProfileMenuItemWidget(
            icon: MediaRes.usersIcon,
            title: l10n.inviteFriends,
            onTap: () {
              // TODO: Navigate to invite friends page
            },
          ),
          Divider(color: ColorApp.greyDivider),
          ProfileMenuItemWidget(
            icon: MediaRes.helpIcon,
            title: l10n.helpCenter,
            onTap: () {
              // TODO: Navigate to help center page
            },
          ),
          Divider(color: ColorApp.greyDivider),
          ProfileMenuItemWidget(
            icon: MediaRes.logoutIcon,
            title: l10n.logout,
            isDestructive: true,
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ColorApp.white,
        title: Text(
          l10n.logout,
          style: const TextStyle(color: ColorApp.black),
          textAlign: TextAlign.center,
        ),
        content: Text(l10n.logoutConfirmation,
            style: const TextStyle(color: ColorApp.grey)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        actions: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorApp.white,
                  foregroundColor: ColorApp.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: ColorApp.greyLight,
                ),
                child: Text(
                  l10n.cancel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorApp.grey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<AuthCubit>().logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorApp.redColorLight,
                  foregroundColor: ColorApp.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  disabledBackgroundColor: ColorApp.greyLight,
                ),
                child: Text(
                  l10n.logout,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
