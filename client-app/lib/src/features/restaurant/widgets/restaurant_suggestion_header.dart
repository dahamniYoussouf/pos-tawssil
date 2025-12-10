import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/src/features/auth/pages/phone_number_page.dart';
import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:client_app/src/features/locations/cubit/location_state.dart';
import 'package:client_app/src/features/restaurant/pages/restaurant_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/src/features/auth/cubit/auth_cubit.dart';
import 'package:client_app/src/features/auth/cubit/user_cubit.dart';
import 'package:client_app/src/features/auth/cubit/user_state.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import '../../auth/services/user_service.dart';
import 'restaurant_search_bar.dart';

class RestaurantSuggestionHeader extends StatelessWidget {
  const RestaurantSuggestionHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();
    final userCubit = context.read<UserCubit>();
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
      color: ColorApp.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${userService.getGreetingMessage(AppLocalizations.of(context)!)}, ${userCubit.state is UserLoaded ? (userCubit.state as UserLoaded).profile.firstName : AppLocalizations.of(context)!.user}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ColorApp.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  BlocBuilder<LocationCubit, LocationState>(
                    builder: (context, locationState) {
                      if (locationState is LocationSuccess) {
                        return Row(
                          children: [
                            SvgPicture.asset(
                              MediaRes.locationIcon,
                              height: 20,
                              width: 20,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${locationState.fullAddress}',
                              style: TextStyle(
                                fontSize: 16,
                                color: ColorApp.greyLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: ColorApp.primary,
                              size: 24,
                            ),
                          ],
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ],
              )),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ColorApp.greyBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: IconButton(
                        icon: Icon(Icons.logout_outlined,
                            size: 22, color: ColorApp.black),
                        onPressed: () {
                          context.read<AuthCubit>().logout().then(
                            (value) {
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PhoneNumberPage()),
                                  (route) => false);
                            },
                          );
                        },
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                ],
              ),
            ],
          ),
          SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantSearchPage(),
                ),
              );
            },
            child: RestaurantSearchBar(readOnly: true),
          ),
        ],
      ),
    );
  }
}
