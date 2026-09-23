import re

def rewrite_appbar():
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    old_appbar = """
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: CircleAvatar(
                backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                child: Icon(
                  Icons.home,
                  color: isDark ? Colors.white : outlookBlue,
                ),
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
"""
    new_appbar = """
        appBar: AppBar(
          leading: Builder(
            builder: (context) {
              final isGmail = selectedAccount != null && selectedAccount!['email'].toString().toLowerCase().contains('gmail');
              return IconButton(
                icon: CircleAvatar(
                  backgroundColor: selectedAccount == null 
                      ? (isDark ? Colors.grey[800] : Colors.white) 
                      : (isGmail ? Colors.red : Colors.blue),
                  child: selectedAccount == null 
                      ? Icon(Icons.home, color: isDark ? Colors.white : outlookBlue)
                      : (isGmail 
                          ? const Icon(Icons.g_mobiledata, color: Colors.white, size: 30)
                          : const Icon(Icons.email, color: Colors.white, size: 20)),
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            }
          ),
"""
    if "icon: CircleAvatar(" in content:
        content = content.replace(old_appbar.strip(), new_appbar.strip())
        with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Updated AppBar")
    else:
        print("Could not find AppBar")

rewrite_appbar()

