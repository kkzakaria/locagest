import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme.dart';

/// Adapte l'URL Supabase pour l'émulateur Android
/// L'émulateur Android ne peut pas accéder à localhost (127.0.0.1)
/// Il faut utiliser 10.0.2.2 qui pointe vers l'hôte
String _getSupabaseUrl(String url) {
  // Sur Android (pas web), remplacer localhost par 10.0.2.2
  if (!kIsWeb && Platform.isAndroid) {
    return url
        .replaceAll('localhost', '10.0.2.2')
        .replaceAll('127.0.0.1', '10.0.2.2');
  }
  return url;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables based on flavor
  const environment = String.fromEnvironment('ENV', defaultValue: 'dev');
  final envFile = environment == 'prod' ? '.env.production' : '.env';
  await dotenv.load(fileName: envFile);

  // Initialize Supabase (avec adaptation URL pour émulateur Android)
  final supabaseUrl = _getSupabaseUrl(dotenv.env['SUPABASE_URL']!);
  debugPrint('🔗 Supabase URL: $supabaseUrl');
  debugPrint('🤖 Platform: Android=${!kIsWeb && Platform.isAndroid}');
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize date formatting for French locale
  await initializeDateFormatting('fr_FR');

  runApp(
    const ProviderScope(
      child: LocaGestApp(),
    ),
  );
}

class LocaGestApp extends ConsumerWidget {
  const LocaGestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Configure system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiOverlayStyle);

    return MaterialApp.router(
      title: 'LocaGest',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('fr', 'FR'),
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
