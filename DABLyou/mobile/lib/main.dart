import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/design_system.dart';
import 'ui/root_page.dart';

void main() {
  runApp(const ProviderScope(child: Taba3App()));
}

class Taba3App extends ConsumerWidget {
  const Taba3App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'تبّع و أربح',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('ar', 'TN'),
      supportedLocales: const [Locale('ar', 'TN'), Locale('fr', 'TN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Force RTL for the main MVP experience.
        return Directionality(textDirection: TextDirection.rtl, child: child ?? const SizedBox());
      },
      home: const RootPage(),
    );
  }
}
