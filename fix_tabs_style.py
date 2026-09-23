import re

def fix_tabs():
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # We need to replace the `// Filter / Tabs Row` block completely.
    old_tabs_block = r"          // Filter / Tabs Row\s*Container\([\s\S]*?Icon\(Icons\.filter_list[\s\S]*?Text\('Filter'[\s\S]*?\]\),\s*\n              \],\s*\n            \),\s*\n          \),"
    
    new_tabs_block = """
          // Filter / Tabs Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // Später: setState umschalten auf Relevant
                  },
                  child: Column(
                    children: [
                      Text(
                        'Relevant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : outlookBlue,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(height: 2, width: 40, color: isDark ? Colors.white : outlookBlue),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    // Später: setState umschalten auf Sonstige
                  },
                  child: Column(
                    children: [
                      Text(
                        'Sonstige',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6), // To align text baseline without underline
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 18, color: isDark ? Colors.white : Colors.black87),
                      const SizedBox(width: 4),
                      Text('Filter', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
"""
    
    content = re.sub(old_tabs_block, new_tabs_block.strip() + ",", content)

    with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

fix_tabs()
print("Fixed tabs style")

