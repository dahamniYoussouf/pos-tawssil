import 'package:delivery_app/src/features/notifications/cubit/notifications_cubit.dart';
import 'package:delivery_app/src/features/orders/cubit/orders_cubit.dart';
import 'package:delivery_app/src/features/driver/cubit/driver_cubit.dart';
import 'package:delivery_app/src/features/home/cubit/navigation_cubit.dart';
import 'package:delivery_app/src/features/locations/cubit/location_cubit.dart';
import 'package:delivery_app/src/features/locations/cubit/location_state.dart';
import 'package:delivery_app/src/features/locations/pages/location_page.dart';
import 'package:delivery_app/src/features/orders/cubit/order_active_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:delivery_app/src/features/onboarding/pages/onboarding_page.dart';
import 'package:delivery_app/src/core/res/app_theme.dart';
import 'package:delivery_app/src/core/utils/dependency_injection.dart';
import 'package:delivery_app/src/features/auth/cubit/auth_cubit.dart';
import 'package:delivery_app/src/features/auth/cubit/auth_state.dart';
import 'package:delivery_app/src/features/auth/services/auth_service.dart';
import 'package:delivery_app/src/features/auth/pages/login_page.dart';
import 'package:delivery_app/src/features/auth/pages/signup_page.dart';
import 'package:delivery_app/src/features/home/pages/home_page.dart';
import 'package:delivery_app/src/features/notifications/services/notification_service.dart';
import 'package:delivery_app/l10n/app_localizations.dart';
import 'package:delivery_app/src/core/localization/locale_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _init();
  final storageDirectory = await getApplicationDocumentsDirectory();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(storageDirectory.path),
  );
  runApp(const MyApp(showOnboarding: true));
}

Future<void> _init() async {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  setupLocator();
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  const MyApp({super.key, this.showOnboarding = false});

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
        BlocProvider<OrderActiveCubit>(
          create: (context) => locator<OrderActiveCubit>(),
        ),
        BlocProvider<DriverCubit>(
          create: (context) => locator<DriverCubit>(),
        ),
        BlocProvider<NavigationCubit>(
          create: (context) => NavigationCubit(),
        ),
        BlocProvider<LocationCubit>(
          create: (context) => LocationCubit(),
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
            initialRoute: showOnboarding ? '/onboarding' : '/home',
            routes: {
              '/onboarding': (context) => const OnboardingPage(),
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
  bool _hasRequestedNotificationsConnection = false;
  bool _hasLoadedLocation = false;

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
      context.read<NotificationsCubit>().connect(
            userId: authState.userId,
          );
    });
  }

  void _loadLocationIfNeeded() {
    if (_hasLoadedLocation) return;
    _hasLoadedLocation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationCubit>().loadSavedLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthSuccess) {
          _connectNotificationsIfNeeded(authState: authState);
          _loadLocationIfNeeded();
          return BlocBuilder<LocationCubit, LocationState>(
            builder: (context, locationState) {
              if (locationState is LocationSuccess) {
                return const HomePage();
              }
              return const LocationPage();
            },
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
