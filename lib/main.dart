import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const PresencaQRApp(),
    ),
  );
}

class PresencaQRApp extends StatelessWidget {
  const PresencaQRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PRESENÇA QR',
      theme: AppTheme.dark(),
      builder: (context, child) => DecoratedBox(
        decoration: AppTheme.backgroundDecoration,
        child: child ?? const SizedBox.expand(),
      ),
      home: const LoginScreen(),
    );
  }
}
