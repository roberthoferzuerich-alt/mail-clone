import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class AddAccountScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAccount;
  const AddAccountScreen({super.key, this.existingAccount});

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
  bool _obscurePassword = true;
  final String apiUrl = 'https://strong-jeans-shave.loca.lt/api';

  @override
  void initState() {
    super.initState();
    if (widget.existingAccount != null) {
      _emailController.text = widget.existingAccount!['email'] ?? '';
      _imapHostController.text = widget.existingAccount!['imap_host'] ?? '';
      _imapPortController.text =
          widget.existingAccount!['imap_port']?.toString() ?? '993';
      _smtpHostController.text = widget.existingAccount!['smtp_host'] ?? '';
      _smtpPortController.text =
          widget.existingAccount!['smtp_port']?.toString() ?? '587';
    }
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final token = await AuthService().getToken();

    try {
      final isEdit = widget.existingAccount != null;
      final url = isEdit
          ? '$apiUrl/mail-accounts/${widget.existingAccount!['id']}'
          : '$apiUrl/mail-accounts';

      final Map<String, dynamic> bodyData = {
        'email': _emailController.text,
        'imap_host': _imapHostController.text,
        'imap_port': int.tryParse(_imapPortController.text) ?? 993,
        'smtp_host': _smtpHostController.text,
        'smtp_port': int.tryParse(_smtpPortController.text) ?? 587,
      };

      if (!isEdit || _passwordController.text.isNotEmpty) {
        bodyData['password'] = _passwordController.text;
      }

      final response = isEdit
          ? await http.put(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
                'Bypass-Tunnel-Reminder': 'true',
              },
              body: jsonEncode(bodyData),
            )
          : await http.post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
                'Bypass-Tunnel-Reminder': 'true',
              },
              body: jsonEncode(bodyData),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEdit ? 'Konto aktualisiert!' : 'Konto hinzugefügt!',
              ),
            ),
          );
          Navigator.pop(context, true);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Netzwerkfehler')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konto löschen?'),
        content: const Text('Möchtest du dieses Konto wirklich entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    final token = await AuthService().getToken();

    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/mail-accounts/${widget.existingAccount!['id']}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Bypass-Tunnel-Reminder': 'true',
        },
      );
      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingAccount != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Konto bearbeiten' : 'Konto hinzufügen'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteAccount,
            ),
        ],
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
                decoration: const InputDecoration(
                  labelText: 'E-Mail Adresse',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: isEdit
                      ? 'Neues Passwort (leer lassen für keine Änderung)'
                      : 'Passwort / App-Passwort',
                  border: const OutlineInputBorder(),
                  helperText: 'Bei Google bitte ein App-Passwort nutzen',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (v) =>
                    (!isEdit && v!.isEmpty) ? 'Pflichtfeld' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Posteingang (IMAP)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _imapHostController,
                      decoration: const InputDecoration(
                        labelText: 'Server (z.B. imap.gmail.com)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _imapPortController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Postausgang (SMTP)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _smtpHostController,
                      decoration: const InputDecoration(
                        labelText: 'Server (z.B. smtp.gmail.com)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _smtpPortController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        border: OutlineInputBorder(),
                      ),
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
                    : const Text(
                        'Konto speichern',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
