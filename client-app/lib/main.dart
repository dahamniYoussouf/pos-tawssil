import 'package:client_app/src/features/locations/cubit/address_cubit/create_address_ui_cubit.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/location_selection_cubit.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/map_location_cubit.dart';
import 'package:client_app/src/features/locations/cubit/favorite_address_cubit.dart';
import 'package:client_app/src/features/restaurant/cubit/restaurant_details_cubit.dart';
import 'package:client_app/src/features/locations/cubit/address_cubit/address_search_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:client_app/src/core/utils/dependency_injection.dart';
import 'package:client_app/src/core/res/app_theme.dart';
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
import 'src/features/restaurant/cubit/search_history_cubit.dart';
import 'src/features/restaurant/cubit/homepage_cubit.dart';
import 'src/features/order/cubit/order_cubit.dart';
import 'src/core/localization/locale_cubit.dart';
import 'src/core/notifications/cubit/notifications_cubit.dart';

// Screen Imports
import 'src/features/auth/pages/phone_number_page.dart';
import 'src/features/auth/pages/user_info_page.dart';
import 'src/features/home/pages/home_page.dart';

// Service Imports
import 'src/features/auth/services/auth_service.dart';

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
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  setupLocator();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
        BlocProvider<NotificationsCubit>(
          create: (context) => locator<NotificationsCubit>(),
        ),
        BlocProvider<LocationCubit>(
          create: (context) => LocationCubit(),
        ),
        BlocProvider<CartCubit>(
          create: (context) => CartCubit(),
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
        BlocProvider<SearchHistoryCubit>(
          create: (context) => locator<SearchHistoryCubit>(),
        ),
        BlocProvider<HomepageCubit>(
          create: (context) => locator<HomepageCubit>(),
        ),
        BlocProvider<OrderCubit>(
          create: (context) => locator<OrderCubit>(),
        ),
        BlocProvider<RestaurantDetailsCubit>(
          create: (context) => locator<RestaurantDetailsCubit>(),
        ),
        BlocProvider<AddressSearchCubit>(
            create: (context) => AddressSearchCubit()),
        BlocProvider<MapLocationCubit>(create: (context) => MapLocationCubit()),
        BlocProvider<CreateAddressUiCubit>(
            create: (context) => CreateAddressUiCubit()),
        BlocProvider<FavoriteAddressCubit>(
            create: (context) => FavoriteAddressCubit()),
        BlocProvider<LocationSelectionCubit>(
            create: (context) => LocationSelectionCubit()),
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
            theme: AppTheme.lightTheme,
            home: AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasCheckedAuth = false;
  bool _hasRequestedNotificationsConnection = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
    _connectNotificationsIfNeeded(
      authState: context.read<AuthCubit>().state,
    );
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!_hasCheckedAuth) {
      _hasCheckedAuth = true;
      if (mounted) {
        await context.read<AuthCubit>().checkAuthenticationStatus();
      }
    }
  }

  void _connectNotificationsIfNeeded({required AuthState authState}) {
    if (_hasRequestedNotificationsConnection) return;
    if (authState is! AuthSuccess) return;
    _hasRequestedNotificationsConnection = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsCubit>().connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthSuccess) {
          return BlocListener<AuthCubit, AuthState>(
            listenWhen: (previous, current) =>
                current is AuthSuccess && previous is! AuthSuccess,
            listener: (context, state) {
              _connectNotificationsIfNeeded(authState: state);
            },
            child: authState.isNewUser
                ? UserInfoPage(userId: authState.userId)
                : const HomePage(),
          );
        // } else if (authState is AuthLoading) {
        //   return const Scaffold(
        //     body: Center(
        //       child: CircularProgressIndicator(),
        //     ),
        //   );
        } else {
          return const PhoneNumberPage();
        }
      },
    );
  }
}
