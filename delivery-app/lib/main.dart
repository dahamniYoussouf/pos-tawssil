import 'package:delivery_app/src/features/notifications/cubit/notifications_cubit.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_cubit.dart';
import 'package:delivery_app/src/features/home/cubit/navigation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:delivery_app/src/core/res/app_theme.dart';
import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/features/auth/cubit/auth_cubit.dart';
import 'package:delivery_app/src/features/auth/cubit/auth_state.dart';
import 'package:delivery_app/src/features/auth/services/auth_service.dart';
import 'package:delivery_app/src/features/auth/pages/login_page.dart';
import 'package:delivery_app/src/features/auth/pages/signup_page.dart';
import 'package:delivery_app/src/features/home/pages/home_page.dart';
import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/localization/locale_cubit.dart';

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
          create: (context) => locator<NotificationsCubit>(),
        ),
        BlocProvider<OrdersCubit>(
          create: (context) => locator<OrdersCubit>(),
        ),
        BlocProvider<DriverCubit>(
          create: (context) => locator<DriverCubit>(),
        ),
        BlocProvider<NavigationCubit>(
          create: (context) => NavigationCubit(),
        ),
        BlocProvider<LocaleCubit>(
          create: (context) => LocaleCubit(),
        ),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Tawsil Delivery',
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
      }
    }
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
              if (state is AuthSuccess) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<NotificationsCubit>().connect();
                });
              }
            },
            child: const HomePage(),
          );
        } else if (authState is AuthChecking) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
