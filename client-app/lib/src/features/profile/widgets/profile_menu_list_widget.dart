import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/src/core/widgets/confirmation_dialog.dart';
import 'package:client_app/src/features/auth/pages/phone_number_page.dart';
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
            icon: MediaRes.editIcon,
            title: l10n.editProfile,
            onTap: () {
              // TODO: Navigate to my locations page
            },
          ),
          Divider(color: ColorApp.greyDivider),
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
    ConfirmationDialog.show(
      context,
      ConfirmationDialogData(
        title: l10n.logout,
        content: l10n.logoutConfirmation,
        confirmText: l10n.ok,
        cancelText: l10n.cancel,
        confirmButtonColor: ColorApp.redColorLight,
        onConfirm: () {
          context.read<AuthCubit>().logout().then((success) {
            if (success) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => PhoneNumberPage()),
                (route) => false,
              );
            }
          });
        },
      ),
    );
  }
}
