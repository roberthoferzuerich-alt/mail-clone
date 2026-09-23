import re

def fix_tabs_filtering():
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix the removeAt logic in _deleteEmail and _archiveEmail
    
    # _deleteEmail
    content = re.sub(
        r"final deletedEmail = emails\[index\];\s*setState\(\(\) \{\s*emails\.removeAt\(index\);\s*\}\);",
        r"final deletedEmail = emails.firstWhere((e) => e['id'] == id, orElse: () => null);\n    setState(() {\n      emails.removeWhere((e) => e['id'] == id);\n    });",
        content
    )
    
    # _archiveEmail
    content = re.sub(
        r"final archivedEmail = emails\[index\];\s*setState\(\(\) \{\s*emails\.removeAt\(index\);\s*\}\);",
        r"final archivedEmail = emails.firstWhere((e) => e['id'] == id, orElse: () => null);\n    setState(() {\n      emails.removeWhere((e) => e['id'] == id);\n    });",
        content
    )

    # 1. Add getter in _EmailListScreenState if not exists
    if "List<dynamic> get displayedEmails {" not in content:
        getter_code = """
  List<dynamic> get displayedEmails {
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
  }
"""
        build_idx = content.find("  @override\n  Widget build(BuildContext context)")
        if build_idx != -1:
            content = content[:build_idx] + getter_code + "\n" + content[build_idx:]

    # Replace emails.isEmpty -> displayedEmails.isEmpty inside the build method
    # Be careful not to replace it in fetchEmails etc if it exists there (it shouldn't)
    
    content = content.replace("emails.isEmpty", "displayedEmails.isEmpty")
    content = content.replace("itemCount: emails.length + 1", "itemCount: displayedEmails.length + 1")
    content = content.replace("final email = emails[index - 1];", "final email = displayedEmails[index - 1];")
    
    with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
        
fix_tabs_filtering()
print("Fixed tabs filtering logic")

