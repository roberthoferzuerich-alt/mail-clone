import re

def add_filter_menu():
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Add state variable
    if "String currentFilter =" not in content:
        content = content.replace("bool showRelevant = true;", "bool showRelevant = true;\n  String currentFilter = 'Alle Nachrichten';")

    # Update getter logic
    old_getter = """  List<dynamic> get displayedEmails {
    return emails.where((email) {
      final sender = (email['sender'] ?? '').toLowerCase();
      final isNewsletter = sender.contains('newsletter') || 
                           sender.contains('noreply') || 
                           sender.contains('no-reply') || 
                           sender.contains('marketing') || 
                           sender.contains('info@') ||
                           sender.contains('news@');
      
      if (showRelevant) {
        return !isNewsletter;
      } else {
        return isNewsletter;
      }
    }).toList();
  }"""
  
    new_getter = """  List<dynamic> get displayedEmails {
    return emails.where((email) {
      // 1. Relevant / Sonstige
      final sender = (email['sender'] ?? '').toLowerCase();
      final isNewsletter = sender.contains('newsletter') || 
                           sender.contains('noreply') || 
                           sender.contains('no-reply') || 
                           sender.contains('marketing') || 
                           sender.contains('info@') ||
                           sender.contains('news@');
      
      bool matchesTabs = showRelevant ? !isNewsletter : isNewsletter;
      if (!matchesTabs) return false;

      // 2. Dropdown Filter
      if (currentFilter == 'Ungelesen') {
        final isRead = email['is_read'] == 1 || email['is_read'] == true || email['is_read'] == '1';
        if (isRead) return false;
      } else if (currentFilter == 'Mit Dateien') {
        final hasAttachments = email['attachments'] != null && (email['attachments'] as List).isNotEmpty;
        if (!hasAttachments) return false;
      }
      // Andere Filter (Gekennzeichnet, Angeheftet etc.) kÃ¶nnten hier noch implementiert werden
      
      return true;
    }).toList();
  }"""
  
    if "List<dynamic> get displayedEmails {" in content:
        # replace block
        start_idx = content.find("  List<dynamic> get displayedEmails {")
        end_idx = content.find("  }", start_idx) + 3
        content = content[:start_idx] + new_getter + content[end_idx:]

    # Replace GestureDetector with PopupMenuButton
    old_button = """                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 18, color: isDark ? Colors.white : Colors.black87),
                      const SizedBox(width: 4),
                      Text('Filter', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                ),"""
                
    new_button = """                PopupMenuButton<String>(
                  onSelected: (String value) {
                    setState(() {
                      currentFilter = value;
                    });
                  },
                  position: PopupMenuPosition.under,
                  color: isDark ? Colors.grey[850] : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 18, color: currentFilter != 'Alle Nachrichten' ? outlookBlue : (isDark ? Colors.white : Colors.black87)),
                      const SizedBox(width: 4),
                      Text(
                        currentFilter == 'Alle Nachrichten' ? 'Filter' : currentFilter,
                        style: TextStyle(color: currentFilter != 'Alle Nachrichten' ? outlookBlue : (isDark ? Colors.white : Colors.black87), fontWeight: currentFilter != 'Alle Nachrichten' ? FontWeight.bold : FontWeight.normal),
                      ),
                    ],
                  ),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    _buildPopupItem('Alle Nachrichten', Icons.mail_outline, isDark),
                    _buildPopupItem('Ungelesen', Icons.mark_email_unread_outlined, isDark),
                    _buildPopupItem('Gekennzeichnet', Icons.flag_outlined, isDark),
                    _buildPopupItem('Angeheftet', Icons.push_pin_outlined, isDark),
                    _buildPopupItem('Kategorisiert', Icons.label_outline, isDark),
                    _buildPopupItem('FÃ¼r mich', Icons.person_outline, isDark),
                    _buildPopupItem('Mit Dateien', Icons.attach_file, isDark),
                    _buildPopupItem('ErwÃ¤hnt mich', Icons.alternate_email, isDark),
                    _buildPopupItem('Ereignisse', Icons.event_note, isDark),
                  ],
                ),"""

    if old_button in content:
        content = content.replace(old_button, new_button)
        
    # Add helper method
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
    if build_idx != -1:
        content = content[:build_idx] + helper + "\n" + content[build_idx:]
        
    with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

add_filter_menu()
print("Added filter menu")
