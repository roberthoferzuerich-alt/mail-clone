import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../main.dart';
import 'compose_email_screen.dart';

class EmailDetailScreen extends StatelessWidget {
  final Map<String, dynamic> email;
  final int? accountId;

  const EmailDetailScreen({super.key, required this.email, this.accountId});

  @override
  Widget build(BuildContext context) {
    final senderName = email['sender'].split('@').first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            if (email['attachments'] != null &&
                (email['attachments'] as List).isNotEmpty) ...[
              const Text(
                'Anhänge',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  Icons.reply,
                  'Antworten',
                  () => _handleReply(context, email, forward: false),
                ),
                _buildActionButton(
                  context,
                  Icons.reply_all,
                  'Allen antworten',
                  () => _handleReply(
                    context,
                    email,
                    forward: false,
                  ), // simplified
                ),
                _buildActionButton(
                  context,
                  Icons.forward,
                  'Weiterleiten',
                  () => _handleReply(context, email, forward: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: outlookBlue),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: outlookBlue, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _handleReply(
    BuildContext context,
    Map<String, dynamic> email, {
    required bool forward,
  }) {
    final sender = email['sender'];
    final originalSubject = email['subject'];
    final subject = forward
        ? 'WG: $originalSubject'
        : (originalSubject.startsWith('AW:')
              ? originalSubject
              : 'AW: $originalSubject');

    final date = _formatDateTime(email['date']);
    final quotedBody =
        '\n\n\n--- Ursprüngliche Nachricht ---\nVon: $sender\nDatum: $date\nBetreff: $originalSubject\n\n> ' +
        email['body'].toString().replaceAll('\n', '\n> ');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComposeEmailScreen(
                        accountId: accountId,
          initialTo: forward ? '' : sender,
          initialSubject: subject,
          initialBody: quotedBody,
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
