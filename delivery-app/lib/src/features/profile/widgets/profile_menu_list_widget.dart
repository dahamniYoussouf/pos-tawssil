import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/res/color_app.dart';
import 'package:delivery_app/src/core/res/media_res.dart';
import 'package:delivery_app/src/core/widgets/confirmation_dialog.dart';
import 'package:delivery_app/src/features/auth/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          // ProfileMenuItemWidget(
          //   icon: MediaRes.promotionIcon,
          //   title: l10n.myPromotions,
          //   onTap: () {},
          // ),
          ProfileMenuItemWidget(
            icon: MediaRes.walletIcon,
            title: l10n.paymentMethods,
            onTap: () {},
          ),
          // ProfileMenuItemWidget(
          //   icon: MediaRes.messageIcon,
          //   title: l10n.messages,
          //   onTap: () {},
          // ),
          ProfileMenuItemWidget(
            icon: MediaRes.usersIcon,
            title: l10n.inviteFriends,
            onTap: () {},
          ),
          ProfileMenuItemWidget(
            icon: MediaRes.ShieldUserIcon,
            title: l10n.security,
            onTap: () {},
          ),
          ProfileMenuItemWidget(
            icon: MediaRes.manageIcon,
            title: l10n.manageAccount,
            onTap: () {},
          ),
          ProfileMenuItemWidget(
            icon: MediaRes.logoutIcon,
            title: l10n.logout,
            isDestructive: true,
            onTap: () => _showLogoutDialog(context, l10n),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations l10n) {
    ConfirmationDialog.show(
      context,
      ConfirmationDialogData(
        title: l10n.logout,
        content: l10n.logoutConfirmation,
        confirmText: l10n.ok,
        cancelText: l10n.cancel,
        confirmButtonColor: AppColors.redColor,
        onConfirm: () {
          context.read<AuthCubit>().logout();
        },
      ),
    );
  }
}
