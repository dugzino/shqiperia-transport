import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/favorites/favorites_controller.dart';
import 'core/favorites/favorites_scope.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_shell.dart';

class SoarAlbaniaApp extends StatefulWidget {
  const SoarAlbaniaApp({super.key});

  @override
  State<SoarAlbaniaApp> createState() => _SoarAlbaniaAppState();
}

class _SoarAlbaniaAppState extends State<SoarAlbaniaApp> {
  final _favorites = FavoritesController();

  @override
  void initState() {
    super.initState();
    _favorites.load();
  }

  @override
  void dispose() {
    _favorites.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FavoritesScope(
      controller: _favorites,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.statusBar,
        child: MaterialApp(
          title: 'Soar Albania',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          home: const MainShell(),
        ),
      ),
    );
  }
}
