import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../main.dart';

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
