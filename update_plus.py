import re

def update_plus_link():
    with open('lib/widgets/mail_drawer.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # The block we found:
    old_block = """
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.transparent,
                      child: Icon(Icons.add, color: Colors.grey),
                    ),
"""
    new_block = """
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AccountsScreen()),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.transparent,
                      child: Icon(Icons.add, color: Colors.grey),
                    ),
"""
    content = content.replace(old_block.strip(), new_block.strip())

    with open('lib/widgets/mail_drawer.dart', 'w', encoding='utf-8') as f:
        f.write(content)

update_plus_link()
print("Updated Plus link")

