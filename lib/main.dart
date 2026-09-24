import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

const Color outlookBlue = Color(0xFF0078D4);
final String apiUrl = 'https://rhz.internet-box.ch:8444/api';

void main() {
  runApp(const MainApp());
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData.light().copyWith(
            primaryColor: outlookBlue,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: outlookBlue,
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: outlookBlue,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1E1E1E),
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.grey,
            ),
          ),
          home: FutureBuilder<bool>(
            future: AuthService().isLoggedIn(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.data == true) {
                return const MainScreen();
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
