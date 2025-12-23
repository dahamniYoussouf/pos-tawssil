import 'package:client_app/src/core/res/color_app.dart';
import 'package:client_app/src/core/res/media_res.dart';
import 'package:client_app/src/features/locations/cubit/favorite_address_cubit.dart';
import 'package:client_app/src/features/locations/cubit/location_cubit.dart';
import 'package:client_app/src/features/locations/cubit/location_state.dart';
import 'package:client_app/src/features/restaurant/pages/restaurant_search_page.dart';
import 'package:client_app/src/features/restaurant/widgets/address_selection_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/src/features/auth/cubit/user_cubit.dart';
import 'package:client_app/src/features/auth/cubit/user_state.dart';
import 'package:client_app/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import '../../auth/services/user_service.dart';
import 'restaurant_search_bar.dart';

class RestaurantSuggestionHeader extends StatefulWidget {
  const RestaurantSuggestionHeader({Key? key}) : super(key: key);

  @override
  State<RestaurantSuggestionHeader> createState() =>
      _RestaurantSuggestionHeaderState();
}

class _RestaurantSuggestionHeaderState
    extends State<RestaurantSuggestionHeader> {
  final GlobalKey _locationKey = GlobalKey();

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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ColorApp.textBlack,
                        ),
                  ),
                  SizedBox(height: 4),
                  BlocBuilder<LocationCubit, LocationState>(
                    builder: (context, locationState) {
                      if (locationState is LocationSuccess) {
                        return GestureDetector(
                          onTap: () {
                            context
                                .read<FavoriteAddressCubit>()
                                .loadFavoriteAddresses();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              AddressSelectionOverLay.show(
                                  context, _locationKey);
                            });
                          },
                          child: Row(
                            key: _locationKey,
                            children: [
                              SvgPicture.asset(
                                MediaRes.locationIcon,
                                height: 20,
                                width: 20,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${locationState.fullAddress}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: ColorApp.textGrey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: ColorApp.primary,
                                size: 24,
                              ),
                            ],
                          ),
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
                      child: SvgPicture.asset(MediaRes.notificationIcon,
                          height: 24, width: 24, color: ColorApp.black),
                    ),
                  ),
                  SizedBox(width: 12),
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
                      child: SvgPicture.asset(MediaRes.favoriteIcon,
                          height: 20, width: 20, color: ColorApp.black),
                    ),
                  ),
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
