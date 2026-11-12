import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/core/application/locale_provider.dart';
import 'package:msupperlimbs/core/router/app_router.dart';
import 'package:msupperlimbs/core/theme/app_theme.dart';
import 'package:msupperlimbs/features/match/application/match_providers.dart';
import 'package:msupperlimbs/l10n/generated/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MsUpperLimbsApp()));
}

class MsUpperLimbsApp extends ConsumerWidget {
  const MsUpperLimbsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    ref.watch(pendingUploadsFlushProvider);

    return MaterialApp.router(
      title: 'MS Upper Limbs',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
