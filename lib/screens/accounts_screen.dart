import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'add_account_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<dynamic> accounts = [];
  bool isLoading = true;
  final String apiUrl = 'https://rhz.internet-box.ch:8444/api';

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    setState(() => isLoading = true);
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
        setState(() {
          accounts = jsonDecode(response.body);
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _openAddOrEdit([Map<String, dynamic>? account]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAccountScreen(existingAccount: account),
      ),
    );
    if (result == true) {
      _fetchAccounts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // Maybe toggle edit mode, but for now we just edit on tap
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ...accounts.map((acc) {
                  final isGmail = acc['email']
                      .toString()
                      .toLowerCase()
                      .contains('gmail.com');
                  return ListTile(
                    leading: isGmail
                        ? const Icon(
                            Icons.g_mobiledata,
                            size: 40,
                            color: Colors.red,
                          ) // Approximation of Google logo
                        : const Icon(Icons.mail_outline),
                    title: Text(isGmail ? 'Google' : 'IMAP'),
                    subtitle: Text(acc['email']),
                    onTap: () => _openAddOrEdit(acc),
                  );
                }),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Konto hinzufügen'),
                  onTap: () => _openAddOrEdit(),
                ),
                ListTile(
                  title: const Text('Neues Konto erstellen'),
                  onTap: () {},
                ),
              ],
            ),
    );
  }
}
