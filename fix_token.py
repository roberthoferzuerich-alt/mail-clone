import re

def fix():
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Add token to _refreshEmails
    content = content.replace("Future<void> _refreshEmails() async {\n", "Future<void> _refreshEmails() async {\n    final token = await AuthService().getToken();\n")
    
    # Let's fix the others, maybe they had different signatures.
    # Future<void> _deleteEmail(int id, BuildContext context) maybe?
    # No, it's _deleteEmail(BuildContext context, int id)?
    
    content = re.sub(r'(Future<void> _deleteEmail\([^)]*\) async {)', r'\1\n    final token = await AuthService().getToken();', content)
    content = re.sub(r'(Future<void> _archiveEmail\([^)]*\) async {)', r'\1\n    final token = await AuthService().getToken();', content)
    content = re.sub(r'(Future<void> _markAsRead\([^)]*\) async {)', r'\1\n    final token = await AuthService().getToken();', content)
    
    # We must deduplicate if I accidentally add it twice
    content = re.sub(r'(final token = await AuthService\(\)\.getToken\(\);\s*){2,}', r'\1', content)

    with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

fix()
print("Fixed token")

