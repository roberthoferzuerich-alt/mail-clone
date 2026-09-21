import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

void main() {
  runApp(const MainApp());
}

const Color outlookBlue = Color(0xFF0078D4);
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Mail Clone',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: outlookBlue,
              primary: outlookBlue,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: outlookBlue,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: outlookBlue,
              primary: outlookBlue,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            useMaterial3: true,
          ),
          themeMode: currentMode,
          home: const MainScreen(),
        );
      },
    );
  }
}

// ----------------------------------------------------------------------
// Hauptbildschirm mit Bottom Navigation
// ----------------------------------------------------------------------
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

// ----------------------------------------------------------------------
// E-Mail Liste (Posteingang)
// ----------------------------------------------------------------------
class EmailListScreen extends StatefulWidget {
  const EmailListScreen({super.key});

  @override
  State<EmailListScreen> createState() => _EmailListScreenState();
}

class _EmailListScreenState extends State<EmailListScreen> {
  List<dynamic> emails = [];
  bool isLoading = true;
  String currentFolder = 'inbox';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final String apiUrl = 'https://strong-jeans-shave.loca.lt/api';

  @override
  void initState() {
    super.initState();
    fetchEmails();
  }

  Future<void> fetchEmails() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/emails?folder=$currentFolder&search=$searchQuery'),
        headers: {'Bypass-Tunnel-Reminder': 'true'},
      );
      if (response.statusCode == 200) {
        setState(() {
          emails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Fehler beim Laden der E-Mails');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshEmails() async {
    // Wenn wir in "inbox" sind, synce auch IMAP
    if (currentFolder == 'inbox') {
      try {
        await http.get(
          Uri.parse('$apiUrl/imap/sync'),
          headers: {'Bypass-Tunnel-Reminder': 'true'},
        ).timeout(const Duration(seconds: 15));
      } catch (_) {}
    }
    await fetchEmails();
  }

  Future<void> _deleteEmail(int id, int index) async {
    final deletedEmail = emails[index];
    setState(() {
      emails.removeAt(index);
    });

    try {
      await http.delete(
        Uri.parse('$apiUrl/emails/$id'),
        headers: {'Bypass-Tunnel-Reminder': 'true'},
      );
    } catch (e) {
      setState(() {
        emails.insert(index, deletedEmail);
      });
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    if (emails[index]['isRead'] == true) return;

    setState(() {
      emails[index]['isRead'] = true;
    });

    try {
      await http.patch(
        Uri.parse('$apiUrl/emails/$id/read'),
        headers: {'Bypass-Tunnel-Reminder': 'true'},
      );
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topBarColor = isDark ? Colors.black87 : outlookBlue;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: CircleAvatar(
              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
              child: Icon(Icons.home, color: isDark ? Colors.white : outlookBlue),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Suchen in ${currentFolder.toUpperCase()}...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            setState(() {
              searchQuery = value;
            });
            fetchEmails();
          },
        ),
        actions: [
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  searchQuery = '';
                });
                fetchEmails();
              },
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                searchQuery = _searchController.text;
              });
              fetchEmails();
            },
          ),
        ],
      ),
      drawer: MailDrawer(
        currentFolder: currentFolder,
        onFolderSelected: (folder) {
          setState(() {
            currentFolder = folder;
            searchQuery = '';
            _searchController.clear();
          });
          fetchEmails();
        },
      ),
      body: Column(
        children: [
          // Filter / Tabs Row
          Container(
            color: topBarColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Relevant', style: TextStyle(color: isDark ? Colors.white : outlookBlue, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Sonstige', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Filter', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),

          // E-Mail Liste
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshEmails,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : emails.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('Posteingang ist leer')),
                      ],
                    )
                  : ListView.separated(
                      itemCount: emails.length + 1, // +1 für den Header
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        indent: 72,
                        color: Colors.black12,
                      ),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Letzte Woche',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        final email = emails[index - 1];
                        final isRead = email['isRead'] ?? false;

                        return Dismissible(
                          key: Key(email['id'].toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) {
                            _deleteEmail(email['id'], index - 1);
                          },
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors
                                  .primaries[email['sender'].length %
                                      Colors.primaries.length]
                                  .shade400,
                              child: Text(
                                email['sender'][0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    email['sender'].split('@').first,
                                    style: TextStyle(
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatDate(email['date']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    color: isRead ? Colors.grey : outlookBlue,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email['subject'],
                                  style: TextStyle(
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  email['body'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            onTap: () {
                              _markAsRead(email['id'], index - 1);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EmailDetailScreen(email: email),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}. Sept.'; // Hardcoded für das Design, kann dynamisch gemacht werden
    } catch (e) {
      return '';
    }
  }
}

// ----------------------------------------------------------------------
// Drawer (Seitenmenü)
// ----------------------------------------------------------------------
class MailDrawer extends StatelessWidget {
  final String currentFolder;
  final Function(String) onFolderSelected;

  const MailDrawer({
    super.key,
    required this.currentFolder,
    required this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Drawer(
      child: Row(
        children: [
          // Schmale linke Leiste
          Material(
            color: isDark ? Colors.black54 : Colors.grey.shade100,
            child: SizedBox(
              width: 70,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  CircleAvatar(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    radius: 24,
                    child: Icon(Icons.home, color: isDark ? Colors.white : outlookBlue, size: 28),
                  ),
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.orange.shade300,
                    child: const Text('RH', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  const Icon(Icons.email_outlined, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Icon(Icons.add, color: Colors.grey),
                  const Spacer(),
                  const Icon(Icons.help_outline, color: Colors.grey),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.grey),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Breiter rechter Bereich
          Expanded(
            child: Material(
              color: Theme.of(context).cardColor,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 16),
                    child: Text('Alle Konten', style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  ),
                  _buildDrawerItem(Icons.inbox, 'Posteingang', 'inbox', '4'),
                  _buildDrawerItem(Icons.edit_outlined, 'Entwürfe', 'drafts', '24'),
                  _buildDrawerItem(Icons.inventory_2_outlined, 'Archiv', 'archive', ''),
                  _buildDrawerItem(Icons.send_outlined, 'Gesendet', 'sent', ''),
                  _buildDrawerItem(Icons.delete_outline, 'Gelöscht', 'trash', '354'),
                  _buildDrawerItem(Icons.folder_off_outlined, 'Junk-E-Mail', 'junk', ''),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String folder, String badge) {
    final isSelected = currentFolder == folder;
    return ListTile(
      leading: Icon(icon, color: isSelected ? outlookBlue : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? outlookBlue : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: badge.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? outlookBlue.withOpacity(0.2) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(color: isSelected ? outlookBlue : Colors.black54, fontSize: 12),
              ),
            )
          : null,
      onTap: () {
        onFolderSelected(folder);
      },
    );
  }
}

// ----------------------------------------------------------------------
// Einstellungen-Bildschirm
// ----------------------------------------------------------------------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Einstellungen'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Suchen',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text('Schnelleinstellungen', style: TextStyle(color: outlookBlue, fontWeight: FontWeight.bold)),
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
                    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
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
            onTap: () {},
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

// ----------------------------------------------------------------------
// Detailansicht: Eine einzelne E-Mail lesen
// ----------------------------------------------------------------------
class EmailDetailScreen extends StatelessWidget {
  final Map<String, dynamic> email;

  const EmailDetailScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final senderName = email['sender'].split('@').first;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(''),
        actions: [
          IconButton(icon: const Icon(Icons.archive_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.mark_email_unread_outlined),
            onPressed: () {},
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email['subject'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: outlookBlue.withOpacity(0.2),
                  child: Text(
                    senderName[0].toUpperCase(),
                    style: const TextStyle(color: outlookBlue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        email['sender'],
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDateTime(email['date']),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (email['attachments'] != null && (email['attachments'] as List).isNotEmpty) ...[
              const Text('Anhänge', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: (email['attachments'] as List).map((att) {
                  return Chip(
                    avatar: const Icon(Icons.insert_drive_file),
                    label: Text(att['name'] ?? 'Datei'),
                  );
                }).toList(),
              ),
              const Divider(),
              const SizedBox(height: 16),
            ],
            MarkdownBody(
              data: email['body'],
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

// ----------------------------------------------------------------------
// Compose-Screen: Eine neue E-Mail schreiben (POST Request)
// ----------------------------------------------------------------------
class ComposeEmailScreen extends StatefulWidget {
  const ComposeEmailScreen({super.key});

  @override
  State<ComposeEmailScreen> createState() => _ComposeEmailScreenState();
}

class _ComposeEmailScreenState extends State<ComposeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  bool isSending = false;
  bool isPreviewMode = false;
  List<PlatformFile> attachedFiles = [];

  void _insertMarkdown(String prefix, [String suffix = '']) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;

    if (selection.isValid && selection.start >= 0 && selection.end >= 0) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset:
              selection.start +
              prefix.length +
              selectedText.length +
              suffix.length,
        ),
      );
    } else {
      final newText = text + prefix + suffix;
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: newText.length - suffix.length,
        ),
      );
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        attachedFiles.addAll(result.files);
      });
    }
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSending = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://strong-jeans-shave.loca.lt/api/emails'),
      );
      
      request.headers['Bypass-Tunnel-Reminder'] = 'true';
      request.fields['sender'] = _toController.text;
      request.fields['subject'] = _subjectController.text;
      request.fields['body'] = _bodyController.text;

      for (var file in attachedFiles) {
        if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'attachments[]',
              file.path!,
              filename: file.name,
            )
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E-Mail erfolgreich versendet!')),
          );
        }
      } else {
        throw Exception('Server antwortete mit Fehler: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Senden der E-Mail')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Neue Nachricht'),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            tooltip: 'Anhang hinzufügen',
            onPressed: _pickFiles,
          ),
          IconButton(
            icon: Icon(isPreviewMode ? Icons.edit : Icons.remove_red_eye),
            tooltip: isPreviewMode ? 'Bearbeiten' : 'Vorschau',
            onPressed: () {
              setState(() {
                isPreviewMode = !isPreviewMode;
              });
            },
          ),
          IconButton(
            icon: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            onPressed: isSending ? null : _sendEmail,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: 'An',
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains('@')
                    ? 'Bitte gültige E-Mail eingeben'
                    : null,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Betreff',
                  border: InputBorder.none,
                ),
                validator: (value) => value!.isEmpty ? 'Betreff fehlt' : null,
              ),
            ),
            const Divider(height: 1),
            if (attachedFiles.isNotEmpty) ...[
              Container(
                height: 50,
                color: isDark ? Colors.grey[800] : Colors.grey.shade100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: attachedFiles.length,
                  itemBuilder: (context, index) {
                    final file = attachedFiles[index];
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
                      child: Chip(
                        label: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onDeleted: () {
                          setState(() {
                            attachedFiles.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
            ],
            if (!isPreviewMode) ...[
              Container(
                color: isDark ? Colors.grey[850] : Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.format_bold,
                        color: Colors.black54,
                      ),
                      onPressed: () => _insertMarkdown('**', '**'),
                      tooltip: 'Fett',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.format_italic,
                        color: Colors.black54,
                      ),
                      onPressed: () => _insertMarkdown('*', '*'),
                      tooltip: 'Kursiv',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.format_list_bulleted,
                        color: Colors.black54,
                      ),
                      onPressed: () => _insertMarkdown('- '),
                      tooltip: 'Liste',
                    ),
                    IconButton(
                      icon: const Icon(Icons.code, color: Colors.black54),
                      onPressed: () => _insertMarkdown('`', '`'),
                      tooltip: 'Code',
                    ),
                    IconButton(
                      icon: const Icon(Icons.link, color: Colors.black54),
                      onPressed: () => _insertMarkdown('[', '](url)'),
                      tooltip: 'Link',
                    ),
                    IconButton(
                      icon: const Icon(Icons.table_chart_outlined, color: Colors.black54),
                      onPressed: () => _insertMarkdown(
                        '\n| Kopf 1 | Kopf 2 | Kopf 3 |\n| :--- | :--- | :--- |\n| Wert 1 | Wert 2 | Wert 3 |\n| Wert 4 | Wert 5 | Wert 6 |\n',
                      ),
                      tooltip: 'Tabelle',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
            Expanded(
              child: isPreviewMode
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.grey.shade50,
                      child: SingleChildScrollView(
                        child: MarkdownBody(
                          data: _bodyController.text.isEmpty
                              ? '*Kein Text eingegeben*'
                              : _bodyController.text,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextFormField(
                        controller: _bodyController,
                        decoration: const InputDecoration(
                          hintText:
                              'Nachricht schreiben (Markdown unterstützt)',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        validator: (value) => value!.isEmpty
                            ? 'Nachricht darf nicht leer sein'
                            : null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
