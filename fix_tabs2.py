import re

def fix_tabs():
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Find where it starts and ends
    start_str = "          // Filter / Tabs Row\n          Container("
    
    # We want to replace everything from start_str up to the Expanded child.
    
    idx = content.find(start_str)
    if idx == -1:
        print("Not found")
        return
        
    expanded_idx = content.find("          Expanded(\n", idx)
    
    new_tabs_block = """          // Filter / Tabs Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {},
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
                  onTap: () {},
                  child: Column(
                    children: [
                      const Text(
                        'Sonstige',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
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
    
    content = content[:idx] + new_tabs_block + content[expanded_idx:]

    with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

fix_tabs()
print("Fixed tabs!")

