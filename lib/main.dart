import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'app_colors.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
    );
  } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    await FirebaseAppCheck.instance.activate(
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  }

  runApp(const KkopiTeaApp());
}

class KkopiTeaApp extends StatelessWidget {
  const KkopiTeaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KKOPI.TEA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.orange),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
