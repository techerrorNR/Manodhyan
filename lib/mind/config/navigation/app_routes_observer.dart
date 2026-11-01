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

class AppRoutesObserver extends RouteObserver<PageRoute<dynamic>> {
  /// Private constructor to enforce singleton pattern.
  AppRoutesObserver._internal();

  /// Singleton instance of the [AppRoutesObserver].
  static final AppRoutesObserver instance = AppRoutesObserver._internal();

  String _currentRoute = "";
  final showFocusShortcut = ValueNotifier<bool>(true);

  void _updateShortcut(Route<dynamic>? route) {
    if (route is! PageRoute) return;
    final visible = route.settings.name != '/mental-maths';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showFocusShortcut.value = visible;
    });
  }

  /// The current route of the app or empty string
  String get currentRoute => _currentRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _currentRoute = route.settings.name ?? "";
    _updateShortcut(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _currentRoute = newRoute?.settings.name ?? "";
    _updateShortcut(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _currentRoute = previousRoute?.settings.name ?? "";
    if (route is PageRoute) _updateShortcut(previousRoute);
    super.didPop(route, previousRoute);
  }
}
