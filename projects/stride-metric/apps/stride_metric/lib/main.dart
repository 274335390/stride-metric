import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_state.dart';
import 'l10n/app_localizations.dart';
import 'screens/comparison_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/profiles_screen.dart';
import 'ui/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const StrideMetricBootstrap());
}

class StrideMetricBootstrap extends StatefulWidget {
  const StrideMetricBootstrap({super.key});

  @override
  State<StrideMetricBootstrap> createState() => _StrideMetricBootstrapState();
}

class _StrideMetricBootstrapState extends State<StrideMetricBootstrap> {
  late final Future<AppState> _state = AppState.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppState>(
      future: _state,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final language = AppLanguage.fromTag(null);
          final copy = AppLocalizations(language);
          return MaterialApp(
            locale: language.locale,
            supportedLocales: AppLanguage.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '${copy.t('loadError')}\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return StrideMetricApp(state: snapshot.data!);
      },
    );
  }
}

class StrideMetricApp extends StatelessWidget {
  const StrideMetricApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return MaterialApp(
          title: 'StrideMetric',
          debugShowCheckedModeBanner: false,
          locale: state.language.locale,
          supportedLocales: AppLanguage.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
          home: _RootShell(state: state),
        );
      },
    );
  }
}

class _RootShell extends StatelessWidget {
  const _RootShell({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      ConverterScreen(state: state),
      ComparisonScreen(state: state),
      ProfilesScreen(state: state),
    ];
    return Scaffold(
      body: IndexedStack(index: state.tabIndex, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: state.tabIndex,
            onTap: state.selectTab,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.calculate_outlined),
                activeIcon: const Icon(Icons.calculate_rounded),
                label: l10n.t('convert'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.format_list_bulleted_rounded),
                activeIcon: const Icon(Icons.list_alt_rounded),
                label: l10n.t('table'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.account_circle_outlined),
                activeIcon: const Icon(Icons.account_circle_rounded),
                label: l10n.t('profiles'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
