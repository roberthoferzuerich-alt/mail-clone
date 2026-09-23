import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/mail_drawer.dart';
import 'email_detail_screen.dart';
import 'compose_email_screen.dart';
import '../main.dart';
import '../services/auth_service.dart'; // for apiUrl, outlookBlue

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

  Map<String, int> unreadCounts = {};
  List<dynamic> accounts = [];
  Map<String, dynamic>? selectedAccount;

  final String apiUrl = 'https://strong-jeans-shave.loca.lt/api';

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
          'Bypass-Tunnel-Reminder': 'true',
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
          'Bypass-Tunnel-Reminder': 'true',
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
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
          '$apiUrl/emails?folder=$currentFolder&search=$searchQuery${selectedAccount != null ? '&account_id=${selectedAccount!['id']}' : ''}',
        ),
        headers: {
          'Bypass-Tunnel-Reminder': 'true',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
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
                'Bypass-Tunnel-Reminder': 'true',
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
    final deletedEmail = emails[index];
    setState(() {
      emails.removeAt(index);
    });

    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/emails/$id'),
        headers: {
          'Bypass-Tunnel-Reminder': 'true',
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
    final archivedEmail = emails[index];
    setState(() {
      emails.removeAt(index);
    });

    try {
      final response = await http.patch(
        Uri.parse('$apiUrl/emails/$id/move'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
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
          'Bypass-Tunnel-Reminder': 'true',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      fetchFolderCounts();
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
            builder: (context) {
              final isGmail = selectedAccount != null && selectedAccount!['email'].toString().toLowerCase().contains('gmail');
              return IconButton(
                icon: CircleAvatar(
                  backgroundColor: selectedAccount == null 
                      ? (isDark ? Colors.grey[800] : Colors.white) 
                      : (isGmail ? Colors.red : Colors.blue.shade800),
                  child: selectedAccount == null 
                      ? Icon(Icons.home, color: isDark ? Colors.white : outlookBlue)
                      : Text(
                          isGmail ? 'G' : selectedAccount!['email'].split('@').last[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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
      body: Column(
        children: [
          // Filter / Tabs Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Column(
                    children: [
                      Text(
                        'Relevant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : outlookBlue,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(height: 2, width: 40, color: isDark ? Colors.white : outlookBlue),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {},
                  child: Column(
                    children: [
                      const Text(
                        'Sonstige',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 18, color: isDark ? Colors.white : Colors.black87),
                      const SizedBox(width: 4),
                      Text('Filter', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
