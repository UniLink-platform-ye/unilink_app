import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'services/fcm_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/splash_screen.dart';
import 'config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.loadHost();
  await Firebase.initializeApp();
  await FcmService.initialize();

  // تحميل الثيم وبيانات الهوية مرة واحدة
  final themeProvider  = ThemeProvider();
  final localeProvider = LocaleProvider();
  await Future.wait([themeProvider.load(), localeProvider.load()]);

  runApp(UniLinkApp(
    themeProvider:  themeProvider,
    localeProvider: localeProvider,
  ));
}

class UniLinkApp extends StatelessWidget {
  final ThemeProvider  themeProvider;
  final LocaleProvider localeProvider;

  const UniLinkApp({
    super.key,
    required this.themeProvider,
    required this.localeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, tp, lp, child) {
          return MaterialApp(
            title:             tp.branding.platformName,
            debugShowCheckedModeBanner: false,
            theme:      tp.buildTheme(Brightness.light),
            darkTheme:  tp.buildTheme(Brightness.dark),
            themeMode:  tp.themeMode,
            locale:     lp.locale,
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
