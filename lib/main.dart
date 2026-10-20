import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/views/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: FunicaApp()));
}

class FunicaApp extends StatelessWidget {
  const FunicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Funica',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
