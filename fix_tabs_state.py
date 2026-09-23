import re

def fix_state():
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Add the variable
    if 'bool showRelevant' not in content:
        content = content.replace("class _EmailListScreenState extends State<EmailListScreen> {\n", "class _EmailListScreenState extends State<EmailListScreen> {\n  bool showRelevant = true;\n")

    # Replace the tabs logic
    old_tabs = """
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
    new_tabs = """
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
                    setState(() {
                      showRelevant = true;
                    });
                  },
                  child: Column(
                    children: [
                      Text(
                        'Relevant',
                        style: TextStyle(
                          fontWeight: showRelevant ? FontWeight.bold : FontWeight.normal,
                          color: showRelevant ? (isDark ? Colors.white : outlookBlue) : Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (showRelevant)
                        Container(height: 2, width: 40, color: isDark ? Colors.white : outlookBlue)
                      else
                        const SizedBox(height: 2),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showRelevant = false;
                    });
                  },
                  child: Column(
                    children: [
                      Text(
                        'Sonstige',
                        style: TextStyle(
                          fontWeight: !showRelevant ? FontWeight.bold : FontWeight.normal,
                          color: !showRelevant ? (isDark ? Colors.white : outlookBlue) : Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!showRelevant)
                        Container(height: 2, width: 40, color: isDark ? Colors.white : outlookBlue)
                      else
                        const SizedBox(height: 2),
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

    if old_tabs.strip() in content:
        content = content.replace(old_tabs.strip(), new_tabs.strip())
        with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Updated tabs state")
    else:
        print("Could not find old tabs")

fix_state()
