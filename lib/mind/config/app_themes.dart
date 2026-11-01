/*
 *
 *  * Copyright (c) 2024 ManoDhyan (https://github.com/techerrorNR)
 *  * Author : Rakesh Yadav (https://github.com/techerrorNR/Manodhyan)
 *  *
 *  * This source code is licensed under the GPL-2.0 license license found in the
 *  * LICENSE file in the root directory of this source tree.
 *
 */

import 'package:flutter/material.dart';
import 'package:focusjoy/mind/config/app_palette.dart';
import 'package:focusjoy/mind/ui/transitions/default_page_transition_builder.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AppTheme {
  static const _kSeedColor = AppPalette.primary;

  static final _kShimmerEffect = ShimmerEffect(
    highlightColor: Colors.white.withValues(alpha: 0.6),
    baseColor: Colors.grey.withValues(alpha: 0.3),
  );

  /// Custom transition for page routes
  static const _kPageTransitionTheme = PageTransitionsTheme(
    builders: {TargetPlatform.android: DefaultPageTransitionsBuilder()},
  );

  static final materialColors = <String, MaterialColor>{
    'Amber': Colors.amber,
    'Blue': Colors.blue,
    'Blue Grey': Colors.blueGrey,
    'Brown': Colors.brown,
    'Cyan': Colors.cyan,
    'Deep Orange': Colors.deepOrange,
    'Deep Purple': Colors.deepPurple,
    'Green': Colors.green,
    'Grey': Colors.grey,
    'Indigo': Colors.indigo,
    'Light Blue': Colors.lightBlue,
    'Light Green': Colors.lightGreen,
    'Lime': Colors.lime,
    'Orange': Colors.orange,
    'Pink': Colors.pink,
    'Purple': Colors.purple,
    'Red': Colors.red,
    'Teal': Colors.teal,
    'Yellow': Colors.yellow,
  };

  static ThemeData darkTheme({Color? seedColor, required bool isAmoled}) =>
      ThemeData.from(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor ?? _kSeedColor,
          brightness: Brightness.dark,
        ).copyWith(
          primary: seedColor ?? AppPalette.primary,
          onPrimary: AppPalette.textPrimary,
          primaryContainer: AppPalette.primaryContainer,
          onPrimaryContainer: AppPalette.textPrimary,
          secondary: AppPalette.secondary,
          onSecondary: AppPalette.background,
          secondaryContainer: AppPalette.secondaryContainer,
          onSecondaryContainer: AppPalette.textPrimary,
          tertiary: AppPalette.highlight,
          onTertiary: AppPalette.background,
          tertiaryContainer: AppPalette.secondaryContainer,
          onTertiaryContainer: AppPalette.textPrimary,
          surface: isAmoled ? Colors.black : AppPalette.card,
          onSurface: AppPalette.textPrimary,
          onSurfaceVariant: AppPalette.textSecondary,
          surfaceDim: AppPalette.background,
          surfaceBright: AppPalette.primaryContainer,
          surfaceContainerLowest: AppPalette.background,
          surfaceContainerLow: AppPalette.background,
          surfaceContainer: AppPalette.card,
          surfaceContainerHigh: AppPalette.primaryContainer,
          surfaceContainerHighest: AppPalette.primaryContainer,
          outline: Colors.white24,
          outlineVariant: AppPalette.divider,
          error: AppPalette.error,
          onError: AppPalette.background,
          surfaceTint: Colors.transparent,
        ),
      ).copyWith(
        pageTransitionsTheme: _kPageTransitionTheme,
        scaffoldBackgroundColor:
            isAmoled ? Colors.black : AppPalette.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppPalette.card,
          foregroundColor: AppPalette.textPrimary,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: const CardThemeData(
          color: AppPalette.card,
          surfaceTintColor: Colors.transparent,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppPalette.card,
          surfaceTintColor: Colors.transparent,
        ),
        extensions: [SkeletonizerConfigData.dark(effect: _kShimmerEffect)],
      );

  static ThemeData lightTheme({Color? seedColor}) => ThemeData.from(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor ?? _kSeedColor,
      brightness: Brightness.light,
    ),
  ).copyWith(
    pageTransitionsTheme: _kPageTransitionTheme,
    extensions: [SkeletonizerConfigData(effect: _kShimmerEffect)],
  );
}
