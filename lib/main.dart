import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/l10n/app_localizations.dart';

// BLoC Imports
import 'src/features/auth/cubit/auth_cubit.dart';
import 'src/features/locations/cubit/location_cubit.dart';
import 'src/features/cart/cubit/cart_cubit.dart';
import 'src/features/restaurant/cubit/restaurant_cubit.dart';
import 'src/core/localization/locale_cubit.dart';

// Screen Imports
import 'src/features/auth/pages/phone_number_page.dart';

// Service Imports
import 'src/features/auth/services/auth_service.dart';
import 'src/features/cart/services/cart_service.dart';
import 'src/features/restaurant/services/restaurant_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocaleCubit>(
          create: (context) => LocaleCubit(),
        ),
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(authService: AuthService()),
        ),
        BlocProvider<LocationCubit>(
          create: (context) => LocationCubit(),
        ),
        BlocProvider<CartCubit>(
          create: (context) => CartCubit(cartService: CartService()),
        ),
        BlocProvider<RestaurantCubit>(
          create: (context) => RestaurantCubit(restaurantService: RestaurantService()),
        ),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return MaterialApp(
            title: 'Tawsil',
            debugShowCheckedModeBanner: false,
            locale: localeState.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('fr', 'FR'),
              Locale('ar', 'DZ'),
            ],
            theme: ThemeData(
              primarySwatch: Colors.green,
              textTheme: GoogleFonts.poppinsTextTheme(
                Theme.of(context).textTheme,
              ),
            ),
            home: PhoneNumberPage(),
          );
        },
      ),
    );
  }
}
