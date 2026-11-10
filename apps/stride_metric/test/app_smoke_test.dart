import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stride_metric/core/app_state.dart';
import 'package:stride_metric/core/shoe_catalog.dart';
import 'package:stride_metric/l10n/app_localizations.dart';
import 'package:stride_metric/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ShoeCatalog catalog;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    catalog = await ShoeCatalog.load();
  });

  testWidgets('main conversion flow renders and opens a result', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(catalog, await SharedPreferences.getInstance());
    await state.setLanguage(AppLanguage.simplifiedChinese);

    await tester.pumpWidget(StrideMetricApp(state: state));
    await tester.pump();

    expect(find.text('鞋码换算'), findsOneWidget);
    expect(find.text('换算'), findsOneWidget);
    expect(find.text('对照表'), findsOneWidget);
    expect(find.text('档案'), findsOneWidget);

    await tester.tap(find.text('开始换算'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('换算结果'), findsOneWidget);
    expect(find.text('对应尺码'), findsOneWidget);
  });

  testWidgets('dark mode applies to the complete app shell', (tester) async {
    SharedPreferences.setMockInitialValues({'darkMode': true});
    final state = AppState(catalog, await SharedPreferences.getInstance());
    await state.setLanguage(AppLanguage.simplifiedChinese);
    await state.setDarkMode(true);

    await tester.pumpWidget(StrideMetricApp(state: state));
    await tester.pump();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);

    final unitButton = tester.widget<OutlinedButton>(
      find.ancestor(of: find.text('cm'), matching: find.byType(OutlinedButton)),
    );
    final foreground = unitButton.style?.foregroundColor?.resolve({});
    expect(
      foreground,
      Theme.of(tester.element(find.text('cm'))).colorScheme.onSurface,
    );
  });

  testWidgets('German copy does not overflow and table filters stay pinned', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final state = AppState(catalog, await SharedPreferences.getInstance());
    await state.setLanguage(AppLanguage.german);

    await tester.pumpWidget(StrideMetricApp(state: state));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Größentabelle'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Damen'), findsOneWidget);
    expect(find.text('Herren'), findsOneWidget);
    expect(find.text('Kinder'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all languages reflow on compact phones without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final state = AppState(catalog, await SharedPreferences.getInstance());
    await tester.pumpWidget(StrideMetricApp(state: state));

    for (final language in AppLanguage.values) {
      await state.setLanguage(language);
      for (var tab = 0; tab < 3; tab++) {
        state.selectTab(tab);
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${language.tag} overflowed on tab $tab',
        );
      }
    }
  });

  testWidgets('measurement guide and foot picker match the complete flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final state = AppState(catalog, await SharedPreferences.getInstance());
    await state.setLanguage(AppLanguage.simplifiedChinese);

    await tester.pumpWidget(StrideMetricApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('如何测量'));
    await tester.pumpAndSettle();
    expect(find.text('测量脚长'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(tester.takeException(), isNull);

    Navigator.of(tester.element(find.text('测量脚长'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('脚长').last);
    await tester.pumpAndSettle();
    expect(find.text('选择脚长'), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.text('女款'), findsWidgets);
    expect(find.text('童款'), findsOneWidget);
    expect(find.text('完成'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('known-size mode keeps its label-reading guide', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(catalog, await SharedPreferences.getInstance());
    await state.setLanguage(AppLanguage.simplifiedChinese);

    await tester.pumpWidget(StrideMetricApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我知道现有尺码'));
    await tester.pumpAndSettle();

    expect(find.text('查看现有尺码'), findsOneWidget);
    await tester.tap(find.text('查看现有尺码'));
    await tester.pumpAndSettle();

    expect(find.text('EU 41'), findsOneWidget);
    expect(find.text('US 9.5 · UK 7.5'), findsOneWidget);
    expect(find.textContaining('鞋盒'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new profile editor uses compact separated sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final state = AppState(catalog, await SharedPreferences.getInstance());
    await state.setLanguage(AppLanguage.simplifiedChinese);

    await tester.pumpWidget(StrideMetricApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('档案'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新建'));
    await tester.pumpAndSettle();

    expect(find.text('编辑尺码档案'), findsOneWidget);
    expect(find.text('头像'), findsOneWidget);
    expect(find.text('档案名称'), findsOneWidget);
    expect(find.text('默认鞋款'), findsOneWidget);
    expect(find.text('脚部测量'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
