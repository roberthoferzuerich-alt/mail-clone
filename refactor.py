import os
import re

def main():
    with open('lib/main.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    chunks = re.split(r'// -{50,}\n// (.*?)\n// -{50,}', content)
    
    # Imports & Globals (Main)
    main_code = chunks[0]
    
    # 1. Hauptbildschirm
    main_screen = chunks[2]
    # 2. E-Mail Liste
    email_list = chunks[4]
    # 3. Drawer
    drawer = chunks[6]
    # 4. Einstellungen
    settings = chunks[8]
    # 5. Detailansicht
    detail = chunks[10]
    # 6. Compose
    compose = chunks[12]

    # Let's fix the Drawer issue (Navigator.pop(context)) in the Python script!
    drawer = re.sub(
        r'onTap: \(\) \{\s*onFolderSelected\(folder\);\s*\},',
        'onTap: () {\n        Navigator.pop(context);\n        onFolderSelected(folder);\n      },',
        drawer
    )

    def write_file(path, imports, code):
        with open(path, 'w', encoding='utf-8') as f:
            f.write(imports + '\n' + code.strip() + '\n')
            
    # main.dart
    write_file('lib/main.dart', '''import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

const Color outlookBlue = Color(0xFF0078D4);
final String apiUrl = 'https://strong-jeans-shave.loca.lt/api';

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
          home: const MainScreen(),
        );
      },
    );
  }
}
''', '')

    # screens/main_screen.dart
    write_file('lib/screens/main_screen.dart', '''import 'package:flutter/material.dart';
import 'email_list_screen.dart';
import 'settings_screen.dart';
''', main_screen)

    # screens/email_list_screen.dart
    write_file('lib/screens/email_list_screen.dart', '''import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/mail_drawer.dart';
import 'email_detail_screen.dart';
import 'compose_email_screen.dart';
import '../main.dart'; // for apiUrl, outlookBlue
''', email_list)

    # widgets/mail_drawer.dart
    write_file('lib/widgets/mail_drawer.dart', '''import 'package:flutter/material.dart';
import '../main.dart';
''', drawer)

    # screens/settings_screen.dart
    write_file('lib/screens/settings_screen.dart', '''import 'package:flutter/material.dart';
import '../main.dart';
''', settings)

    # screens/email_detail_screen.dart
    write_file('lib/screens/email_detail_screen.dart', '''import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../main.dart';
''', detail)

    # screens/compose_email_screen.dart
    write_file('lib/screens/compose_email_screen.dart', '''import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../main.dart';
''', compose)

    print("Refactoring complete.")

if __name__ == '__main__':
    main()
