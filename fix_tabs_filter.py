import re

def fix_tabs_filtering():
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add getter in _EmailListScreenState
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
    # Insert it right before the build method
    build_idx = content.find("  @override\n  Widget build(BuildContext context)")
    if build_idx != -1:
        content = content[:build_idx] + getter_code + "\n" + content[build_idx:]

    # 2. Update the body to use `displayedEmails` instead of `emails` inside the build method
    
    # We only want to replace inside the build method.
    # We replace: 
    # `emails.isEmpty` -> `displayedEmails.isEmpty`
    # `itemCount: emails.length + 1` -> `itemCount: displayedEmails.length + 1`
    # `emails[index - 1]` -> `displayedEmails[index - 1]`
    # And there's also the Dismissible onDismissed logic that uses `index - 1` and `email['id']`. We should capture `final email = displayedEmails[index - 1];` instead of doing it later. Wait, the code already does `final email = displayedEmails[index - 1];` (or similar) inside itemBuilder!

    # Let's replace those safely:
    content = content.replace("emails.isEmpty", "displayedEmails.isEmpty")
    content = content.replace("itemCount: emails.length + 1", "itemCount: displayedEmails.length + 1")
    content = content.replace("final email = emails[index - 1];", "final email = displayedEmails[index - 1];")
    content = content.replace("final deletedEmail = emails[index];", "final deletedEmail = displayedEmails[index];")
    # Wait, _deleteEmail and _archiveEmail get the real ID of the email, so `emails.removeAt(index)` in those methods is dangerous if index comes from displayedEmails!
    
    with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
        
fix_tabs_filtering()
print("Replaced emails with displayedEmails")

