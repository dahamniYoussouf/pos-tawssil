// lib/main.dart - Version mise à jour avec le thème Tawsil
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/order_provider.dart';
import 'screens/login_screen.dart';
import 'services/sync_service.dart';

// Always import sqflite normally
import 'package:sqflite/sqflite.dart';

// Conditional import: desktop OR web version
import 'database/desktop_init.dart'
    if (dart.library.html) 'database/web_stub.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database for desktop (Windows/Linux/macOS) or Web
  if (kIsWeb) {
    initDatabase(); // Web DB using sql.js
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    initDatabase(); // Desktop DB using FFI
  }
  // Android/iOS: sqflite works automatically

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        Provider(create: (_) => SyncService()),
      ],
      child: MaterialApp(
        title: 'POS Tawsil',
        debugShowCheckedModeBanner: false,
        theme: TawsilTheme.lightTheme, // ✅ Utiliser le thème Tawsil
        home: const LoginScreen(),
      ),
    );
  }
}