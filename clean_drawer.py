import re

def remove_home_and_dropdown():
    with open('lib/widgets/mail_drawer.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Remove Home Button
    home_button = """
                  // "Alle Konten" / Home Button
                  GestureDetector(
                    onTap: () {},
                    child: CircleAvatar(
                      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                      radius: 24,
                      child: Icon(
                        Icons.home,
                        color: isDark ? Colors.white : outlookBlue,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
"""
    content = content.replace(home_button, "")

    # 2. Replace ExpansionTile with simple Text
    expansion_regex = r"if \(accounts != null && accounts!\.isNotEmpty\)\s*ExpansionTile\([\s\S]*?else\s*Padding\([\s\S]*?Keine Konten[\s\S]*?\),"
    
    new_header = """
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 16),
                    child: Text(
                      selectedAccount != null ? selectedAccount!['email'] : 'Posteingang',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
"""
    
    content = re.sub(expansion_regex, new_header.strip() + ",", content)

    with open('lib/widgets/mail_drawer.dart', 'w', encoding='utf-8') as f:
        f.write(content)

remove_home_and_dropdown()
print("Cleaned up drawer")
