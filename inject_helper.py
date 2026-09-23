def inject():
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    helper = """  PopupMenuItem<String> _buildPopupItem(String title, IconData icon, bool isDark) {
    return PopupMenuItem<String>(
      value: title,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: isDark ? Colors.white70 : Colors.grey[700], size: 20),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          if (currentFilter == title)
            const Icon(Icons.radio_button_checked, color: outlookBlue, size: 20)
          else
            Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }

"""
    build_idx = content.find("  @override\n  Widget build(BuildContext context)")
    
    if build_idx != -1 and "PopupMenuItem<String> _buildPopupItem" not in content:
        content = content[:build_idx] + helper + content[build_idx:]
        with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Injected helper")

inject()

