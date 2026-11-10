import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/tactical_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/survival_providers.dart';
import 'repositories/storage_repository.dart';
import 'services/notification_service.dart';
import 'ui/screens/main_navigation_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Offline-First Storage (with instant in-memory fallback)
  final storageRepository = StorageRepository();
  await storageRepository.init();

  // Initialize Zero-Server Local Notifications
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageRepositoryProvider.overrideWithValue(storageRepository),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const SurvivalManagerApp(),
    ),
  );
}

class SurvivalManagerApp extends ConsumerWidget {
  const SurvivalManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Survival & Shelter Manager',
      theme: TacticalTheme.darkTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainNavigationShell(),
    );
  }
}
