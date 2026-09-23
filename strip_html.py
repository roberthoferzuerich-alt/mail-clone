import re

def update_handle_reply():
    with open('lib/screens/email_detail_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # The handle reply block
    old_handle = """
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
        '\\n\\n\\n--- Urspr\\u00fcngliche Nachricht ---\\nVon: $sender\\nDatum: $date\\nBetreff: $originalSubject\\n\\n> ' +
        email['body'].toString().replaceAll('\\n', '\\n> ');

    Navigator.push(
"""
    
    new_handle = """
  String _stripHtml(String htmlString) {
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
        '\\n\\n\\n--- Urspr\\u00fcngliche Nachricht ---\\nVon: $sender\\nDatum: $date\\nBetreff: $originalSubject\\n\\n> ' +
        plainTextBody.replaceAll('\\n', '\\n> ');

    Navigator.push(
"""
    
    if "final quotedBody" in content:
        # Since encoding issues might happen with the string replace, I will use regex
        
        content = re.sub(r"void _handleReply\([\s\S]*?Navigator\.push\(", new_handle.strip() + "(", content)
        with open('lib/screens/email_detail_screen.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Updated _handleReply")

update_handle_reply()
