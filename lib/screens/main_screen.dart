import 'package:flutter/material.dart';
import 'email_list_screen.dart';
import 'settings_screen.dart';
import 'compose_email_screen.dart';
import '../main.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const EmailListScreen(),
    const Scaffold(body: Center(child: Text('Kalender'))),
    const Scaffold(body: Center(child: Text('Apps'))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComposeEmailScreen(),
                  ),
                );
                // Wenn wir zurückkommen und etwas gesendet wurde,
                // können wir die Liste neuladen.
                // Da wir nicht direkt auf den State zugreifen können,
                // wäre ein GlobalKey oder Provider besser.
                // Für diesen Klon verlassen wir uns auf den Pull-to-Refresh.
              },
              backgroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.edit_outlined, color: outlookBlue),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: outlookBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.email), label: 'E-Mail'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Kalender',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Apps'),
        ],
      ),
    );
  }
}
