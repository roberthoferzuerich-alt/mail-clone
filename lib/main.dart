import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mail Clone',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const EmailListScreen(),
    );
  }
}

// ----------------------------------------------------------------------
// Hauptbildschirm: E-Mail Liste
// ----------------------------------------------------------------------
class EmailListScreen extends StatefulWidget {
  const EmailListScreen({super.key});

  @override
  State<EmailListScreen> createState() => _EmailListScreenState();
}

class _EmailListScreenState extends State<EmailListScreen> {
  List<dynamic> emails = [];
  bool isLoading = true;

  // HINWEIS: Wir verwenden nun einen öffentlichen Tunnel (localtunnel),
  // damit dein Handy garantiert darauf zugreifen kann.
  final String apiUrl = 'https://strong-jeans-shave.loca.lt/api/emails';

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
      // Wichtig: localtunnel benötigt diesen Header für APIs!
      final response = await http.get(
        Uri.parse(apiUrl),
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
      print('Fehler beim Abrufen der E-Mails: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Konnte E-Mails nicht laden. Bitte Verbindung prüfen.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteEmail(int id, int index) async {
    // Optimistisch aus der Liste entfernen für eine flüssige UI
    final deletedEmail = emails[index];
    setState(() {
      emails.removeAt(index);
    });

    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/$id'),
        headers: {'Bypass-Tunnel-Reminder': 'true'},
      );

      if (response.statusCode != 200) {
        throw Exception('Löschen fehlgeschlagen');
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('E-Mail gelöscht')));
      }
    } catch (e) {
      // Bei Fehler wiederherstellen
      setState(() {
        emails.insert(index, deletedEmail);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fehler beim Löschen')));
      }
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    if (emails[index]['isRead'] == true) return;

    // Optimistisch auf gelesen setzen
    setState(() {
      emails[index]['isRead'] = true;
    });

    try {
      await http.patch(
        Uri.parse('$apiUrl/$id/read'),
        headers: {'Bypass-Tunnel-Reminder': 'true'},
      );
    } catch (e) {
      print('Fehler beim Markieren als gelesen: $e');
    }
  }

  Future<void> _syncIMAP() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('https://strong-jeans-shave.loca.lt/api/imap/sync'),
        headers: {'Bypass-Tunnel-Reminder': 'true'},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Erfolgreich importiert')),
          );
        }
        await fetchEmails(); // Lade die Liste neu
      } else {
        throw Exception('Fehler beim IMAP-Sync');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim IMAP Sync (Zugangsdaten in .env geprüft?)')),
        );
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posteingang', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            tooltip: 'IMAP Import',
            icon: const Icon(Icons.cloud_download_outlined),
            onPressed: _syncIMAP,
          ),
          IconButton(
            tooltip: 'Aktualisieren',
            icon: const Icon(Icons.refresh),
            onPressed: fetchEmails,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchEmails,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : emails.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Text(
                      'Dein Posteingang ist leer!',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                itemCount: emails.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final email = emails[index];
                  final isRead = email['isRead'] ?? false;

                  return Dismissible(
                    key: Key(email['id'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      _deleteEmail(email['id'], index);
                    },
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors
                            .primaries[email['sender'].length %
                                Colors.primaries.length]
                            .shade200,
                        child: Text(
                          email['sender'][0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
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
                              color: isRead
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
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
                          const SizedBox(height: 2),
                          Text(
                            email['body'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      onTap: () {
                        _markAsRead(email['id'], index);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ComposeEmailScreen()),
          );
          // Wenn eine E-Mail erfolgreich gesendet wurde, aktualisiere die Liste
          if (result == true) {
            fetchEmails();
          }
        },
        icon: const Icon(Icons.edit),
        label: const Text('Schreiben'),
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.';
    } catch (e) {
      return '';
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () {},
          ),
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
                  backgroundColor: Colors.blue.shade100,
                  child: Text(senderName[0].toUpperCase()),
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
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
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
            Text(
              email['body'],
              style: const TextStyle(fontSize: 16, height: 1.5),
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

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://strong-jeans-shave.loca.lt/api/emails'),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: json.encode({
          'sender': _toController
              .text, // In einem echten System wäre das der Empfänger, für unser Datenmodell nutzen wir es als Absender/Kontakt
          'subject': _subjectController.text,
          'body': _bodyController.text,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context, true); // True = erfolgreich gesendet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E-Mail erfolgreich versendet!')),
          );
        }
      } else {
        throw Exception('Server antwortete mit Fehler');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neue Nachricht'),
        actions: [
          IconButton(
            icon: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    hintText: 'Nachricht schreiben',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (value) =>
                      value!.isEmpty ? 'Nachricht darf nicht leer sein' : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
