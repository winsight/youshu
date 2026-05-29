import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'core/l10n/app_locale.dart';
import 'core/theme/app_theme.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_mode_provider.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AssetSumApp()));
}

class AssetSumApp extends ConsumerWidget {
  const AssetSumApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(resolvedLocaleProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: '有数',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.systemOverlayStyle(isDark: isDark),
          child: child ?? const SizedBox.shrink(),
        );
      },
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('zh')],
      localizationsDelegates: const [
        AppL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == locale.languageCode) {
              return supported;
            }
          }
        }
        return supportedLocales.first;
      },
    );
  }
}
