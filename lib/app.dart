import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/main_shell.dart';

class KosovaTransitApp extends StatelessWidget {
  const KosovaTransitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kosova Transit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}
