import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(false);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrackoApp());
}

class TrackoApp extends StatelessWidget {
  const TrackoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          title: 'TRACKO - Money Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(isDarkMode: isDarkMode),
          home: const SplashScreen(),
        );
      },
    );
  }
}
