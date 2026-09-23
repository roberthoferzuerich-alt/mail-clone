import re

def rewrite_appbar2():
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    new_leading = """
        appBar: AppBar(
          leading: Builder(
            builder: (context) {
              final isGmail = selectedAccount != null && selectedAccount!['email'].toString().toLowerCase().contains('gmail');
              return IconButton(
                icon: CircleAvatar(
                  backgroundColor: selectedAccount == null 
                      ? (isDark ? Colors.grey[800] : Colors.white) 
                      : (isGmail ? Colors.red : Colors.blue.shade800),
                  child: selectedAccount == null 
                      ? Icon(Icons.home, color: isDark ? Colors.white : outlookBlue)
                      : Text(
                          isGmail ? 'G' : selectedAccount!['email'].split('@').last[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            },
          ),
"""

    # Replace from "appBar: AppBar(" to just before "title: Container("
    content = re.sub(r"appBar:\s*AppBar\([\s\S]*?title:\s*Container\(", new_leading.strip() + "\n          title: Container(", content)

    with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

rewrite_appbar2()
print("Force updated AppBar")

