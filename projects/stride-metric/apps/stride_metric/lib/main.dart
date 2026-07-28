import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ads/app_open_ad_manager.dart';
import 'ads/home_banner_ad.dart';
import 'core/app_state.dart';
import 'l10n/app_localizations.dart';
import 'screens/comparison_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/profiles_screen.dart';
import 'ui/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
  late final Future<AppState> _startup = _load();

  Future<AppState> _load() async {
    final stateFuture = AppState.load();
    await WidgetsBinding.instance.endOfFrame;
    await AppOpenAdManager.instance.initializeForLaunch();
    return stateFuture;
  }

  @override
  void dispose() {
    unawaited(AppOpenAdManager.instance.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppState>(
      future: _startup,
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
            builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: navy,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarColor: Color(0xFF071A34),
                systemNavigationBarIconBrightness: Brightness.light,
                systemStatusBarContrastEnforced: false,
                systemNavigationBarContrastEnforced: false,
              ),
              child: ColoredBox(
                color: navy,
                child: child ?? const SizedBox.expand(),
              ),
            ),
            home: const Scaffold(backgroundColor: navy, body: _StartupView()),
          );
        }
        return StrideMetricApp(state: snapshot.data!);
      },
    );
  }
}

class _StartupView extends StatelessWidget {
  const _StartupView();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: navy),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 30),
          child: SizedBox.expand(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 4),
                Container(
                  width: 116,
                  height: 116,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .16),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 32,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/branding/app-icon-source.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'StrideMetric',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Measure once. Fit everywhere.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .72),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .2,
                  ),
                ),
                const Spacer(flex: 5),
                const SizedBox(
                  width: 96,
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                    backgroundColor: Color(0x33FFFFFF),
                    color: teal,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'SHOE SIZE INTELLIGENCE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .42),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
          builder: (context, child) {
            final theme = Theme.of(context);
            final dark = theme.brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: dark
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: dark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness: dark
                    ? Brightness.light
                    : Brightness.dark,
                systemNavigationBarDividerColor: Colors.transparent,
                systemStatusBarContrastEnforced: false,
                systemNavigationBarContrastEnforced: false,
              ),
              child: ColoredBox(
                color: theme.scaffoldBackgroundColor,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.tabIndex == 0) const HomeBannerAd(),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                ),
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
          ),
        ],
      ),
    );
  }
}
