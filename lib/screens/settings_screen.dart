import 'package:flutter/material.dart';
import '../main.dart';
import 'accounts_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Einstellungen'), elevation: 0),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Suchen',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'Schnelleinstellungen',
              style: TextStyle(color: outlookBlue, fontWeight: FontWeight.bold),
            ),
          ),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, _) {
              return ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dunkles Design (Dark Mode)'),
                trailing: Switch(
                  value: currentMode == ThemeMode.dark,
                  activeColor: outlookBlue,
                  onChanged: (value) {
                    themeNotifier.value = value
                        ? ThemeMode.dark
                        : ThemeMode.light;
                  },
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.format_paint_outlined),
            title: const Text('Anzeige und Darstellung'),
            subtitle: const Text('System / Blau / Geräumig'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.draw_outlined),
            title: const Text('Signaturen'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('Benachrichtigungen'),
            onTap: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              'Allgemein',
              style: TextStyle(color: outlookBlue, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('Konten'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('E-Mail'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Kalender'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.contacts_outlined),
            title: const Text('Kontakte'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.translate),
            title: const Text('Sprache'),
            subtitle: const Text('Auto'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.accessibility_new),
            title: const Text('Barrierefreiheit'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
