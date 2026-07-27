import 'package:flutter/material.dart';

const navy = Color(0xFF102B55);
const blue = Color(0xFF2864E8);
const teal = Color(0xFF18AAA8);
const pageLight = Color(0xFFF7F9FC);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: blue,
    brightness: brightness,
    surface: dark ? const Color(0xFF101827) : Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF0B1220) : pageLight,
    fontFamilyFallback: const [
      'PingFang SC',
      'Noto Sans CJK SC',
      'Microsoft YaHei',
    ],
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
      bodyColor: dark ? Colors.white : navy,
      displayColor: dark ? Colors.white : navy,
    ),
    dividerTheme: DividerThemeData(
      color: dark ? Colors.white12 : const Color(0xFFDDE5EF),
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? const Color(0xFF162239) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: dark ? Colors.white12 : const Color(0xFFD7E0EC),
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: blue,
      unselectedItemColor: const Color(0xFF728197),
      backgroundColor: dark ? const Color(0xFF101827) : Colors.white,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}
