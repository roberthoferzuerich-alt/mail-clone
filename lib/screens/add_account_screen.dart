import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _imapHostController = TextEditingController();
  final _imapPortController = TextEditingController(text: '993');
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController(text: '587');

  bool _isLoading = false;
  final String apiUrl = 'https://strong-jeans-shave.loca.lt/api';

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final token = await AuthService().getToken();

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/mail-accounts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
          'imap_host': _imapHostController.text,
          'imap_port': int.tryParse(_imapPortController.text) ?? 993,
          'smtp_host': _smtpHostController.text,
          'smtp_port': int.tryParse(_smtpPortController.text) ?? 587,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konto erfolgreich hinzugefügt!')),
          );
          Navigator.pop(context, true); // Return true to refresh list
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fehler beim Speichern')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Netzwerkfehler')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Mail-Konto hinzufügen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'IMAP & SMTP Daten',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-Mail Adresse', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Passwort / App-Passwort', 
                  border: OutlineInputBorder(),
                  helperText: 'Bei Google bitte ein App-Passwort nutzen'
                ),
                obscureText: true,
                validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null,
              ),
              const SizedBox(height: 24),
              const Text('Posteingang (IMAP)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _imapHostController,
                      decoration: const InputDecoration(labelText: 'Server (z.B. imap.gmail.com)', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _imapPortController,
                      decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Postausgang (SMTP)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _smtpHostController,
                      decoration: const InputDecoration(labelText: 'Server (z.B. smtp.gmail.com)', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _smtpPortController,
                      decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _saveAccount,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Konto speichern', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
