import re

def update_settings():
    with open('lib/screens/settings_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    new_settings = """
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_calendar/device_calendar.dart';
import '../main.dart';
import 'accounts_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _syncCalendar = false;
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _syncCalendar = prefs.getBool('sync_calendar') ?? false;
    });
  }

  Future<void> _toggleSync(bool value) async {
    if (value) {
      var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && !permissionsGranted.data!) {
        permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
        if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
          // Keine Erlaubnis
          return;
        }
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_calendar', value);
    setState(() {
      _syncCalendar = value;
    });
  }

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
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('Konten'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountsScreen(),
                ),
              );
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_month_outlined),
            title: const Text('Kalender synchronisieren'),
            subtitle: const Text('Lokale Termine in der App anzeigen'),
            value: _syncCalendar,
            onChanged: _toggleSync,
            activeColor: outlookBlue,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Allgemein', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Benachrichtigungen'),
            value: true,
            onChanged: (bool value) {},
            activeColor: outlookBlue,
          ),
        ],
      ),
    );
  }
}
"""

    with open('lib/screens/settings_screen.dart', 'w', encoding='utf-8') as f:
        f.write(new_settings.strip())
        
update_settings()
print("Updated settings screen")
