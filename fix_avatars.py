import re

def fix_avatars():
    # Fix MailDrawer
    with open('lib/widgets/mail_drawer.dart', 'r', encoding='utf-8') as f:
        drawer_content = f.read()

    old_avatar = """
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: isGmail ? Colors.red : Colors.blue,
                            child: isGmail 
                                ? const Icon(Icons.g_mobiledata, color: Colors.white, size: 30)
                                : const Icon(Icons.email, color: Colors.white, size: 20),
                          ),
"""
    new_avatar = """
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: isGmail ? Colors.red : Colors.blue.shade800,
                            child: Text(
                              isGmail ? 'G' : email.split('@').last[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
"""
    drawer_content = drawer_content.replace(old_avatar.strip(), new_avatar.strip())
    with open('lib/widgets/mail_drawer.dart', 'w', encoding='utf-8') as f:
        f.write(drawer_content)

    # Fix EmailListScreen AppBar
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        list_content = f.read()
        
    old_appbar_avatar = """
              return IconButton(
                icon: CircleAvatar(
                  backgroundColor: selectedAccount == null 
                      ? (isDark ? Colors.grey[800] : Colors.white) 
                      : (isGmail ? Colors.red : Colors.blue),
                  child: selectedAccount == null 
                      ? Icon(Icons.home, color: isDark ? Colors.white : outlookBlue)
                      : (isGmail 
                          ? const Icon(Icons.g_mobiledata, color: Colors.white, size: 30)
                          : const Icon(Icons.email, color: Colors.white, size: 20)),
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
"""
    new_appbar_avatar = """
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
"""
    list_content = list_content.replace(old_appbar_avatar.strip(), new_appbar_avatar.strip())
    with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
        f.write(list_content)

fix_avatars()
print("Fixed avatars")

