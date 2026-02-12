import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';
import 'package:restaurant_app/src/core/res/media_res.dart';
import 'package:restaurant_app/src/features/auth/cubit/auth_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_state.dart';
import 'package:restaurant_app/src/features/profile/widgets/profile_card_widget.dart';
import 'package:restaurant_app/src/features/profile/widgets/profile_menu_item_widget.dart';
import 'package:restaurant_app/src/features/profile/widgets/language_selector_widget.dart';

import 'package:restaurant_app/src/features/restaurant/pages/manage_profile_page.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    locator<RestaurantCubit>().fetchRestaurantProfile();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          localizations.settings,
          style: const TextStyle(
            color: Color(0xFF059669),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            BlocBuilder<RestaurantCubit, RestaurantState>(
              bloc: locator<RestaurantCubit>(),
              builder: (context, state) {
                if (state is RestaurantLoaded) {
                  return ProfileCardWidget(restaurant: state.restaurant);
                }
                if (state is RestaurantLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const SizedBox(height: 112); // Placeholder height
              },
            ),
            const SizedBox(height: 24),
            ProfileMenuItemWidget(
              icon: MediaRes.editIcon,
              title: localizations.manageProfile,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ManageProfilePage()),
                );
              },
            ),
            ProfileMenuItemWidget(
              icon: MediaRes.messageIcon,
              title: localizations.notifications,
              onTap: () {},
            ),
            ProfileMenuItemWidget(
              icon: MediaRes.manageIcon,
              title: localizations.printerSettings,
              onTap: () {},
            ),
            ProfileMenuItemWidget(
              icon: MediaRes.shieldUserIcon,
              title: localizations.aboutUs,
              onTap: () {},
            ),
            ProfileMenuItemWidget(
              icon: MediaRes.logoutIcon,
              title: localizations.logout,
              isDestructive: true,
              onTap: () {
                context.read<AuthCubit>().logout();
              },
            ),
            const LanguageSelectorWidget(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
