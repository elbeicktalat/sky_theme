// Copyright (c) 2024. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lets_theme/src/lets_theme_inherited.dart';
import 'package:lets_theme/src/lets_theme_manager.dart';
import 'package:lets_theme/src/utils/theme_mode_extension.dart';
import 'package:lets_theme/src/utils/theme_preferences.dart';

/// Builder function to build themed widget.
typedef ThemeBuilder = Widget Function(ThemeData light, ThemeData dark);

/// Widget that allows to switch themes dynamically. This is intended to be
/// used above [MaterialApp].
/// Example:
///
/// ```dart
///  LetsTheme(
///   light: ThemeData.light(),
///   dark: ThemeData.dark(),
///   initialMode: ThemeMode.system,
///   builder: (lightTheme, darkTheme) => MaterialApp(
///     theme: lightTheme,
///     darkTheme: darkTheme,
///     home: MyHomePage(),
///   ),
/// );
/// ```
class LetsTheme extends StatefulWidget {
  const LetsTheme({
    required this.light,
    required this.dark,
    required this.initialMode,
    required this.builder,
    super.key,
  });

  /// Represents the light theme for the app.
  final ThemeData light;

  /// Represents the dark theme for the app.
  final ThemeData dark;

  /// Indicates which [ThemeMode] to use initially.
  final ThemeMode initialMode;

  /// Provides a builder with access of light and dark theme. Intended to
  /// be used to return [MaterialApp].
  final ThemeBuilder builder;

  /// Key used to store theme information into shared-preferences. If you want
  /// to persist theme mode changes even after shared-preferences
  /// is cleared (e.g. after log out), do not remove this [preferencesKey]
  /// key from shared-preferences.
  static const String preferencesKey = 'lets_theme_preferences';

  @override
  State<LetsTheme> createState() => _LetsThemeState();

  /// Returns reference of the [LetsThemeManager] which allows access of
  /// the state object of [LetsTheme] in a restrictive way.
  static LetsThemeManager of(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<InheritedLetsTheme>()!;
    return context.findAncestorStateOfType<State<LetsTheme>>()!
        as LetsThemeManager;
  }

  /// Returns reference of the [LetsThemeManager] which allows access of
  /// the state object of [LetsTheme] in a restrictive way.
  /// This returns null if the state instance of [LetsTheme] is not found.
  static LetsThemeManager? maybeOf(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<InheritedLetsTheme>();
    final State<LetsTheme>? state =
        context.findAncestorStateOfType<State<LetsTheme>>();
    if (state == null) return null;
    return state as LetsThemeManager;
  }

  /// returns most recent theme mode. This can be used to eagerly get previous
  /// theme mode inside main method before calling [runApp].
  static Future<ThemeMode?> getThemeMode() async {
    return (await ThemePreferences.fromPrefs())?.mode;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ThemeData>('light', light));
    properties.add(DiagnosticsProperty<ThemeData>('dark', dark));
    properties.add(EnumProperty<ThemeMode>('initialMode', initialMode));
    properties.add(ObjectFlagProperty<ThemeBuilder>.has('builder', builder));
  }
}

class _LetsThemeState extends State<LetsTheme>
    with WidgetsBindingObserver, LetsThemeManager {
  @override
  void initState() {
    super.initState();
    initialize(
      light: widget.light,
      dark: widget.dark,
      initialMode: widget.initialMode,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  /// When device theme mode is changed, Flutter does not rebuild
  /// [MaterialApp] and Because of that, if theme is set to
  /// [ThemeMode.system]. it doesn't take effect. This check mitigates
  /// that and refreshes the UI to use new theme if needed.
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    if (mode.isSystem && mounted) setState(() {});
  }

  @override
  bool get isDefault =>
      lightTheme == widget.light &&
      darkTheme == widget.dark &&
      mode == defaultMode;

  @override
  Widget build(BuildContext context) {
    return InheritedLetsTheme(
      manager: this,
      child: widget.builder(theme, mode.isLight ? lightTheme : darkTheme),
    );
  }

  @override
  void updateState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    themeModeNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> reset() async {
    setTheme(
      light: widget.light,
      dark: widget.dark,
      notify: false,
    );
    return super.reset();
  }
}
