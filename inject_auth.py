import re

def add_token(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add import
    if "import '../services/auth_service.dart';" not in content:
        content = content.replace("import '../main.dart';", "import '../main.dart';\nimport '../services/auth_service.dart';")

    # Replace headers
    # We will inject the token fetch at the start of each method that makes http calls.
    # Methods: fetchFolderCounts, fetchEmails, _deleteEmail, _archiveEmail, _markAsRead
    
    methods = [
        'Future<void> fetchFolderCounts() async {',
        'Future<void> fetchEmails() async {',
        'Future<void> _deleteEmail(int id) async {',
        'Future<void> _archiveEmail(int id) async {',
        'Future<void> _markAsRead(int id) async {'
    ]
    
    for m in methods:
        content = content.replace(m, m + "\n    final token = await AuthService().getToken();")
        
    # Now replace headers
    content = content.replace(
        "headers: {'Bypass-Tunnel-Reminder': 'true'},",
        "headers: {'Bypass-Tunnel-Reminder': 'true', 'Authorization': 'Bearer $token', 'Accept': 'application/json'},"
    )
    
    content = content.replace(
        "headers: {\n          'Content-Type': 'application/json',\n          'Accept': 'application/json',\n          'Bypass-Tunnel-Reminder': 'true',\n        },",
        "headers: {\n          'Content-Type': 'application/json',\n          'Accept': 'application/json',\n          'Bypass-Tunnel-Reminder': 'true',\n          'Authorization': 'Bearer $token',\n        },"
    )

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

add_token('lib/screens/email_list_screen.dart')

# Now for compose_email_screen.dart
def add_token_compose(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    if "import '../services/auth_service.dart';" not in content:
        content = content.replace("import '../main.dart';", "import '../main.dart';\nimport '../services/auth_service.dart';")
        
    m = 'Future<void> _sendEmail() async {'
    content = content.replace(m, m + "\n    final token = await AuthService().getToken();")
    
    content = content.replace(
        "request.headers['Bypass-Tunnel-Reminder'] = 'true';",
        "request.headers['Bypass-Tunnel-Reminder'] = 'true';\n    request.headers['Authorization'] = 'Bearer $token';\n    request.headers['Accept'] = 'application/json';"
    )
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

add_token_compose('lib/screens/compose_email_screen.dart')
print("Injected auth tokens")
