import 'package:client_app/src/features/auth/pages/phone_number_page.dart';
import 'package:client_app/src/features/restaurant/pages/restaurant_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_app/src/features/auth/cubit/auth_cubit.dart';
import 'package:client_app/src/features/auth/cubit/user_cubit.dart';
import 'package:client_app/src/features/auth/cubit/user_state.dart';
import 'package:client_app/l10n/app_localizations.dart';
import '../../auth/services/user_service.dart';
import 'restaurant_search_bar.dart';

class RestaurantSuggestionHeader extends StatelessWidget {
  final UserLocation? userLocation;

  const RestaurantSuggestionHeader({Key? key, this.userLocation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();
    final userCubit = context.read<UserCubit>();
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
      color: Colors.white,
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  if (userLocation != null)
                    Text(
                      '${userLocation!.area}, ${userLocation!.city}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
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
                        color: Colors.black,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: IconButton(
                        icon: Icon(Icons.logout_outlined, size: 22, color: Colors.black),
                        onPressed: () {
                          context.read<AuthCubit>().logout().then(
                            (value) {
                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => PhoneNumberPage()), (route) => false);
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
