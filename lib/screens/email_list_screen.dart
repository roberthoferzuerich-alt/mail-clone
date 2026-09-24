import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/mail_drawer.dart';
import 'email_detail_screen.dart';
import 'compose_email_screen.dart';
import '../main.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart'; // for apiUrl, outlookBlue

class EmailListScreen extends StatefulWidget {
  const EmailListScreen({super.key});

  @override
  State<EmailListScreen> createState() => _EmailListScreenState();
}

class _EmailListScreenState extends State<EmailListScreen> {
  bool showRelevant = true;
  String currentFilter = 'Alle Nachrichten';
  List<dynamic> emails = [];
  bool isLoading = true;
  String currentFolder = 'inbox';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Map<String, int> unreadCounts = {};
  List<dynamic> accounts = [];
  Map<String, dynamic>? selectedAccount;

  final String apiUrl = 'https://rhz.internet-box.ch:8444/api';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final token = await AuthService().getToken();
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/mail-accounts'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          
        },
      );
      if (response.statusCode == 200) {
        final accs = jsonDecode(response.body) as List;
        if (accs.isNotEmpty) {
          accounts = accs;
          selectedAccount = accs[0];
        }
      }
    } catch (_) {}
    fetchEmails();
    fetchFolderCounts();
  }

  Future<void> fetchFolderCounts() async {
    final token = await AuthService().getToken();
    try {
      final response = await http.get(
        Uri.parse(
          '$apiUrl/emails/counts${selectedAccount != null ? '?account_id=${selectedAccount!['id']}' : ''}',
        ),
        headers: {
          
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          unreadCounts = data.map((key, value) => MapEntry(key, value as int));
        });
      }
    } catch (e) {
      // Ignore for now
    }
  }

  Future<void> fetchEmails() async {
    final token = await AuthService().getToken();
    
    // 1. Lokale Mails sofort laden (wenn ein Konto ausgewÃ¤hlt ist und nicht gesucht wird)
    if (selectedAccount != null && searchQuery.isEmpty) {
      final localEmails = await DatabaseService().getEmails(selectedAccount!['id'], currentFolder);
      if (localEmails.isNotEmpty) {
        setState(() {
          emails = localEmails;
          isLoading = false;
        });
      } else {
        setState(() { isLoading = true; });
      }
    } else {
      setState(() { isLoading = true; });
    }

    // 2. Im Hintergrund vom Server holen
    try {
      final response = await http.get(
        Uri.parse(
          '$apiUrl/emails?folder=$currentFolder&search=$searchQuery${selectedAccount != null ? '&account_id=${selectedAccount!['id']}' : ''}',
        ),
        headers: {
          
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> serverEmails = json.decode(response.body);
        
        // Lokal cachen, wenn es keine Suche ist
        if (selectedAccount != null && searchQuery.isEmpty) {
          // FÃ¼ge die account_id zu den Mails hinzu, falls sie fehlt
          for (var e in serverEmails) {
            e['mail_account_id'] = selectedAccount!['id'];
          }
          await DatabaseService().saveEmails(serverEmails);
        }
        
        if (mounted) {
          setState(() {
            emails = serverEmails;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Fehler beim Laden der E-Mails');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshEmails() async {
    final token = await AuthService().getToken();
    // Wenn wir in "inbox" sind, synce auch IMAP
    if (currentFolder == 'inbox') {
      try {
        final imapUrl = selectedAccount != null
            ? '$apiUrl/imap/sync?account_id=${selectedAccount!['id']}'
            : '$apiUrl/imap/sync';
        await http
            .get(
              Uri.parse(imapUrl),
              headers: {
                
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 15));
      } catch (_) {}
    }
    await fetchEmails();
  }

  Future<void> _deleteEmail(int id, int index) async {
    final token = await AuthService().getToken();
    final deletedEmail = emails.firstWhere(
      (e) => e['id'] == id,
      orElse: () => null,
    );
    setState(() {
      emails.removeWhere((e) => e['id'] == id);
      DatabaseService().deleteEmail(id);
    });

    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/emails/$id'),
        headers: {
          
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        fetchFolderCounts();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('E-Mail gelöscht!')));
        }
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        emails.insert(index, deletedEmail);
      });
    }
  }

  Future<void> _archiveEmail(int id, int index) async {
    final token = await AuthService().getToken();
    final archivedEmail = emails.firstWhere(
      (e) => e['id'] == id,
      orElse: () => null,
    );
    setState(() {
      emails.removeWhere((e) => e['id'] == id);
      DatabaseService().deleteEmail(id);
    });

    try {
      final response = await http.patch(
        Uri.parse('$apiUrl/emails/$id/move'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'folder': 'archive'}),
      );
      if (response.statusCode != 200) {
        throw Exception();
      } else {
        fetchFolderCounts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E-Mail ins Archiv verschoben!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          emails.insert(index, archivedEmail);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Archivieren: $e')));
      }
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    final token = await AuthService().getToken();
    if (emails[index]['isRead'] == true) return;

    setState(() {
      emails[index]['isRead'] = true;
    });

    try {
      await http.patch(
        Uri.parse('$apiUrl/emails/$id/read'),
        headers: {
          
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      fetchFolderCounts();
    } catch (e) {
      // ignore
    }
  }

  List<dynamic> get displayedEmails {
    return emails.where((email) {
      final sender = (email['sender'] ?? '').toLowerCase();
      final isNewsletter =
          sender.contains('newsletter') ||
          sender.contains('noreply') ||
          sender.contains('no-reply') ||
          sender.contains('marketing') ||
          sender.contains('info@') ||
          sender.contains('news@');

      bool matchesTabs = showRelevant ? !isNewsletter : isNewsletter;
      if (!matchesTabs) return false;

      if (currentFilter == 'Ungelesen') {
        final isRead =
            email['is_read'] == 1 ||
            email['is_read'] == true ||
            email['is_read'] == '1';
        if (isRead) return false;
      } else if (currentFilter == 'Mit Dateien') {
        final hasAttachments =
            email['attachments'] != null &&
            (email['attachments'] as List).isNotEmpty;
        if (!hasAttachments) return false;
      }

      return true;
    }).toList();
  }

  PopupMenuItem<String> _buildPopupItem(
    String title,
    IconData icon,
    bool isDark,
  ) {
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isDark ? Colors.white70 : Colors.grey[700],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          if (currentFilter == title)
            const Icon(Icons.radio_button_checked, color: outlookBlue, size: 20)
          else
            Icon(
              Icons.radio_button_unchecked,
              color: Colors.grey[400],
              size: 20,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topBarColor = isDark ? Colors.black87 : outlookBlue;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            final isGmail =
                selectedAccount != null &&
                selectedAccount!['email'].toString().toLowerCase().contains(
                  'gmail',
                );
            return IconButton(
              icon: CircleAvatar(
                backgroundColor: selectedAccount == null
                    ? (isDark ? Colors.grey[800] : Colors.white)
                    : (isGmail ? Colors.red : Colors.blue.shade800),
                child: selectedAccount == null
                    ? Icon(
                        Icons.home,
                        color: isDark ? Colors.white : outlookBlue,
                      )
                    : Text(
                        isGmail
                            ? 'G'
                            : selectedAccount!['email']
                                  .split('@')
                                  .last[0]
                                  .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Suchen in ${currentFolder.toUpperCase()}...',
              hintStyle: const TextStyle(color: Colors.white70),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
            onSubmitted: (value) {
              setState(() {
                searchQuery = value;
              });
              fetchEmails();
            },
          ),
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
        unreadCounts: unreadCounts,
        accounts: accounts,
        selectedAccount: selectedAccount,
        onAccountSelected: (acc) {
          setState(() {
            selectedAccount = acc;
            currentFolder = 'inbox';
          });
          fetchEmails();
          fetchFolderCounts();
        },
        onFolderSelected: (folder) {
          setState(() {
            currentFolder = folder;
            searchQuery = '';
            _searchController.clear();
          });
          fetchEmails();
        },
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComposeEmailScreen(
                accountId: selectedAccount?['id'],
              ),
            ),
          );
          fetchEmails(); // Reload after sending
        },
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        elevation: 4,
        child: const Icon(Icons.edit, color: Color(0xFF0078D4)), // outlookBlue
      ),
      body: Column(
        children: [
          // Filter / Tabs Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showRelevant = true;
                    });
                  },
                  child: Column(
                    children: [
                      Text(
                        'Relevant',
                        style: TextStyle(
                          fontWeight: showRelevant
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: showRelevant
                              ? (isDark ? Colors.white : outlookBlue)
                              : Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (showRelevant)
                        Container(
                          height: 2,
                          width: 40,
                          color: isDark ? Colors.white : outlookBlue,
                        )
                      else
                        const SizedBox(height: 2),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showRelevant = false;
                    });
                  },
                  child: Column(
                    children: [
                      Text(
                        'Sonstige',
                        style: TextStyle(
                          fontWeight: !showRelevant
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: !showRelevant
                              ? (isDark ? Colors.white : outlookBlue)
                              : Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!showRelevant)
                        Container(
                          height: 2,
                          width: 40,
                          color: isDark ? Colors.white : outlookBlue,
                        )
                      else
                        const SizedBox(height: 2),
                    ],
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    setState(() {
                      currentFilter = value;
                    });
                  },
                  position: PopupMenuPosition.under,
                  color: isDark ? Colors.grey[850] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 18,
                        color: currentFilter != 'Alle Nachrichten'
                            ? outlookBlue
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentFilter == 'Alle Nachrichten'
                            ? 'Filter'
                            : currentFilter,
                        style: TextStyle(
                          color: currentFilter != 'Alle Nachrichten'
                              ? outlookBlue
                              : (isDark ? Colors.white : Colors.black87),
                          fontWeight: currentFilter != 'Alle Nachrichten'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        _buildPopupItem(
                          'Alle Nachrichten',
                          Icons.mail_outline,
                          isDark,
                        ),
                        _buildPopupItem(
                          'Ungelesen',
                          Icons.mark_email_unread_outlined,
                          isDark,
                        ),
                        _buildPopupItem(
                          'Gekennzeichnet',
                          Icons.flag_outlined,
                          isDark,
                        ),
                        _buildPopupItem(
                          'Angeheftet',
                          Icons.push_pin_outlined,
                          isDark,
                        ),
                        _buildPopupItem(
                          'Kategorisiert',
                          Icons.label_outline,
                          isDark,
                        ),
                        _buildPopupItem(
                          'Für mich',
                          Icons.person_outline,
                          isDark,
                        ),
                        _buildPopupItem(
                          'Mit Dateien',
                          Icons.attach_file,
                          isDark,
                        ),
                        _buildPopupItem(
                          'Erwähnt mich',
                          Icons.alternate_email,
                          isDark,
                        ),
                        _buildPopupItem('Ereignisse', Icons.event_note, isDark),
                      ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshEmails,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedEmails.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('Posteingang ist leer')),
                      ],
                    )
                  : ListView.separated(
                      itemCount:
                          displayedEmails.length + 1, // +1 für den Header
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

                        final email = displayedEmails[index - 1];
                        final isRead = email['isRead'] ?? false;

                        return Dismissible(
                          key: Key(email['id'].toString()),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            color: Colors.green,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(
                              Icons.archive,
                              color: Colors.white,
                            ),
                          ),
                          secondaryBackground: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) {
                            if (direction == DismissDirection.startToEnd) {
                              _archiveEmail(email['id'], index - 1);
                            } else if (direction ==
                                DismissDirection.endToStart) {
                              _deleteEmail(email['id'], index - 1);
                            }
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
                                  builder: (context) => EmailDetailScreen(
                                    email: email,
                                    accountId: selectedAccount != null
                                        ? selectedAccount!['id']
                                        : null,
                                  ),
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
