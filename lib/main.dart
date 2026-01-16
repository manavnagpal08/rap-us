import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rap_app/firebase_options.dart';
import 'package:rap_app/screens/splash_screen.dart';
import 'package:rap_app/screens/main_screen.dart';
import 'package:rap_app/theme/app_theme.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AppTheme.init();

  if (kIsWeb) {
    // This often fixes "channel" errors on restricted networks or certain browsers
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false, // Disable for testing
    );
  }

  // Connectivity test (Suggested Ping)
  try {
    debugPrint('Testing Firestore connection with ping...');
    await FirebaseFirestore.instance.collection('test').doc('ping').set({
      'ok': true,
      'timestamp': FieldValue.serverTimestamp(),
    });
    debugPrint('Firestore ping successful.');
  } catch (e) {
    debugPrint('Firestore ping failed: $e');
  }
  
  runApp(const RapApp());
}

class RapApp extends StatelessWidget {
  const RapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: AppTheme.localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'RAP Precision',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: mode,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: MainScreen(),
            );
          },
        );
      },
    );
  }
}
