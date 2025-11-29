import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:client_app/src/core/utils/dependency_injection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:client_app/l10n/app_localizations.dart';

// BLoC Imports
import 'src/features/auth/cubit/auth_cubit.dart';
import 'src/features/auth/cubit/auth_state.dart';
import 'src/features/auth/cubit/user_cubit.dart';
import 'src/features/locations/cubit/location_cubit.dart';
import 'src/features/cart/cubit/cart_cubit.dart';
import 'src/features/restaurant/cubit/restaurant_cubit.dart';
import 'src/features/restaurant/cubit/category_cubit.dart';
import 'src/features/restaurant/cubit/restaurant_search_cubit.dart';
import 'src/features/order/cubit/order_cubit.dart';
import 'src/core/localization/locale_cubit.dart';

// Screen Imports
import 'src/features/auth/pages/phone_number_page.dart';
import 'src/features/auth/pages/user_info_page.dart';
import 'src/features/home/pages/home_page.dart';

// Service Imports
import 'src/features/auth/services/auth_service.dart';
import 'src/features/cart/services/cart_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _init();
  final storageDirectory = await getApplicationDocumentsDirectory();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(storageDirectory.path),
  );
  runApp(MyApp());
}

Future<void> _init() async {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  setupLocator();
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
        BlocProvider<UserCubit>(
          create: (context) => UserCubit(authService: AuthService()),
        ),
        BlocProvider<LocationCubit>(
          create: (context) => LocationCubit(),
        ),
        BlocProvider<CartCubit>(
          create: (context) => CartCubit(cartService: locator<CartService>()),
        ),
        BlocProvider<UserCubit>(
          create: (context) => locator<UserCubit>(),
        ),
        BlocProvider<RestaurantCubit>(
          create: (context) => locator<RestaurantCubit>(),
        ),
        BlocProvider<CategoryCubit>(
          create: (context) => locator<CategoryCubit>(),
        ),
        BlocProvider<RestaurantSearchCubit>(
          create: (context) => locator<RestaurantSearchCubit>(),
        ),
        BlocProvider<OrderCubit>(
          create: (context) => locator<OrderCubit>(),
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
              fontFamily: GoogleFonts.poppins().fontFamily,
              textTheme: ThemeData.light().textTheme.apply(
                    fontFamily: GoogleFonts.poppins().fontFamily,
                  ),
            ),
            home: AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthSuccess) {
          if (state.isNewUser) {
            return UserInfoPage(userId: state.userId);
          } else {
            return const HomePage();
          }
        } else {
          return const PhoneNumberPage();
        }
      },
    );
  }
}
