def fix():
    with open('lib/screens/email_detail_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    start_idx = content.find("  void _handleReply(")
    end_idx = content.find("    Navigator.push(", start_idx)

    if start_idx != -1 and end_idx != -1:
        new_handle = """  String _stripHtml(String htmlString) {
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
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
    final plainTextBody = _stripHtml(email['body'].toString());
    final quotedBody =
        '\\n\\n\\n--- Ursprüngliche Nachricht ---\\nVon: $sender\\nDatum: $date\\nBetreff: $originalSubject\\n\\n> ' +
        plainTextBody.replaceAll('\\n', '\\n> ');

"""
        content = content[:start_idx] + new_handle + content[end_idx:]
        with open('lib/screens/email_detail_screen.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Success")
fix()

