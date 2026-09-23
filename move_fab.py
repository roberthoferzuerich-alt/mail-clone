import re

def move_fab():
    # 1. Remove FAB from main_screen.dart
    with open('lib/screens/main_screen.dart', 'r', encoding='utf-8') as f:
        main_content = f.read()

    main_content = re.sub(
        r"floatingActionButton: _currentIndex == 0[\s\S]*?Icon\(Icons\.edit, color: outlookBlue\),\n\s*\)\n\s*: null,",
        "",
        main_content
    )
    with open('lib/screens/main_screen.dart', 'w', encoding='utf-8') as f:
        f.write(main_content)

    # 2. Add FAB to email_list_screen.dart
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        email_content = f.read()

    fab_code = """
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComposeEmailScreen(
                accountId: selectedAccount?['id'],
              ),
            ),
          );
          fetchEmails(); // Reload after sending
        },
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        elevation: 4,
        child: const Icon(Icons.edit, color: Color(0xFF0078D4)), // outlookBlue
      ),
"""
    # Insert before body: Column(
    if "body: Column(" in email_content:
        email_content = email_content.replace("body: Column(", fab_code + "      body: Column(")
        with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
            f.write(email_content)
        print("Moved FAB")

move_fab()
