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
  final String apiUrl = 'https://strong-jeans-shave.loca.lt/api';

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
          'Bypass-Tunnel-Reminder': 'true',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('E-Mail-Konten')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : accounts.isEmpty
              ? const Center(child: Text('Noch keine Konten hinterlegt.'))
              : ListView.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final acc = accounts[index];
                    return ListTile(
                      leading: const Icon(Icons.email, color: Color(0xFF0078D4)),
                      title: Text(acc['email']),
                      subtitle: Text('IMAP: ${acc['imap_host']} | SMTP: ${acc['smtp_host']}'),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0078D4),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAccountScreen()),
          );
          if (result == true) {
            _fetchAccounts();
          }
        },
      ),
    );
  }
}
