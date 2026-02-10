import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:restaurant_app/src/core/res/app_theme.dart';
import 'package:restaurant_app/src/core/utils/dependency_injection.dart';
import 'package:restaurant_app/src/features/auth/cubit/auth_cubit.dart';
import 'package:restaurant_app/src/features/auth/cubit/auth_state.dart';
import 'package:restaurant_app/src/features/auth/services/auth_service.dart';
import 'package:restaurant_app/src/features/auth/pages/login_page.dart';
import 'package:restaurant_app/src/features/auth/pages/signup_page.dart';
import 'package:restaurant_app/src/features/categories/cubit/category_cubit.dart';
import 'package:restaurant_app/src/features/home/pages/home_page.dart';
import 'package:restaurant_app/src/features/menu_items/cubit/menu_item_cubit.dart';
import 'package:restaurant_app/src/features/orders/cubit/order_history_cubit.dart';
import 'package:restaurant_app/src/features/orders/cubit/orders_cubit.dart';
import 'package:restaurant_app/src/features/notifications/cubit/notifications_cubit.dart';
import 'package:restaurant_app/src/features/statistics/cubit/statistics_cubit.dart';
import 'package:restaurant_app/src/features/restaurant/cubit/restaurant_cubit.dart';
import 'package:restaurant_app/src/features/home/cubit/navigation_cubit.dart';
import 'package:restaurant_app/src/features/orders/pages/order_details_page.dart';
import 'package:restaurant_app/l10n/app_localizations.dart';

import 'package:restaurant_app/src/core/localization/locale_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _init();
  final storageDirectory = await getApplicationDocumentsDirectory();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(storageDirectory.path),
  );
  runApp(const MyApp());
}

Future<void> _init() async {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  setupLocator();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(authService: AuthService()),
        ),
        BlocProvider<NotificationsCubit>(
          create: (context) => NotificationsCubit(),
        ),
        BlocProvider<LocaleCubit>(
          create: (context) => LocaleCubit(),
        ),
        BlocProvider<OrdersCubit>(
          create: (context) {
            final notificationsCubit = context.read<NotificationsCubit>();
            return OrdersCubit(notificationsCubit: notificationsCubit);
          },
        ),
        BlocProvider<StatisticsCubit>(
          create: (context) => StatisticsCubit(),
        ),
        BlocProvider<CategoryCubit>(
          create: (context) => locator<CategoryCubit>(),
        ),
        BlocProvider<RestaurantCubit>(
          create: (context) => locator<RestaurantCubit>(),
        ),
        BlocProvider<OrderHistoryCubit>(
          create: (context) => OrderHistoryCubit(),
        ),
        BlocProvider<NavigationCubit>(
          create: (context) => NavigationCubit(),
        ),
        BlocProvider<MenuItemCubit>(
          create: (context) => locator<MenuItemCubit>(),
        ),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Tawsil Restaurant',
            debugShowCheckedModeBanner: false,
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
            locale: state.locale,
            theme: AppTheme.lightTheme,
            initialRoute: '/home',
            routes: {
              '/login': (context) => const LoginPage(),
              '/signup': (context) => const SignupPage(),
              '/home': (context) => const AuthWrapper(),
              '/order-details': (context) => const OrderDetailsPage(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasCheckedAuth = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!_hasCheckedAuth) {
      _hasCheckedAuth = true;
      if (mounted) {
        await context.read<AuthCubit>().checkAuthenticationStatus();
        final authState = context.read<AuthCubit>().state;
        if (authState is AuthSuccess) {
          context.read<NotificationsCubit>().connect();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        final notificationsCubit = context.read<NotificationsCubit>();
        if (state is AuthSuccess) {
          notificationsCubit.connect();
        } else {
          notificationsCubit.disconnect();
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
