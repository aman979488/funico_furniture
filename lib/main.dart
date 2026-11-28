import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'core/router/app_router.dart';
import 'core/services/pin_session.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase initialization warning: $e');
    }

    const googleClientId = String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue:
          '655147824865-a7grii2oo0ra9ia0q7ef2glq0tpl1h7q.apps.googleusercontent.com',
    );
    // Initialize GoogleSignIn without blocking first frame render
    GoogleSignIn.instance
        .initialize(
          clientId: kIsWeb && googleClientId.isNotEmpty ? googleClientId : null,
          serverClientId:
              !kIsWeb && googleClientId.isNotEmpty ? googleClientId : null,
        )
        .catchError((Object e) {
      debugPrint('GoogleSignIn initialization warning: $e');
    });
  }
  runApp(const ProviderScope(child: FunicaApp()));
}

class FunicaApp extends StatefulWidget {
  const FunicaApp({super.key});

  @override
  State<FunicaApp> createState() => _FunicaAppState();
}

class _FunicaAppState extends State<FunicaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      PinSession.lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Funica',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
