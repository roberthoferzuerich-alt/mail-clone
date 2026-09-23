import re

def rewrite_drawer():
    with open('lib/widgets/mail_drawer.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # We need to replace the entire left column content
    # And replace the right column header
    
    # Left column replacement:
    old_left_col = """
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  CircleAvatar(
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    radius: 24,
                    child: Icon(
                      Icons.home,
                      color: isDark ? Colors.white : outlookBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.orange.shade300,
                    child: const Text(
                      'RH',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Icon(Icons.email_outlined, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Icon(Icons.add, color: Colors.grey),
                  const Spacer(),
                  const Icon(Icons.help_outline, color: Colors.grey),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
"""
    
    new_left_col = """
              child: Column(
                children: [
                  const SizedBox(height: 40),
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
                  
                  // Dynamische Accounts aus der Datenbank
                  if (accounts != null)
                    ...accounts!.map((acc) {
                      final isSelected = selectedAccount != null && selectedAccount!['id'] == acc['id'];
                      final email = acc['email'].toString().toLowerCase();
                      final isGmail = email.contains('gmail');
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Drawer schließen
                            if (onAccountSelected != null) {
                              onAccountSelected!(acc);
                            }
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: isGmail ? Colors.red : Colors.blue,
                            child: isGmail 
                                ? const Icon(Icons.g_mobiledata, color: Colors.white, size: 30)
                                : const Icon(Icons.email, color: Colors.white, size: 20),
                          ),
                        ),
                      );
                    }).toList(),
                  
                  // Konto hinzufügen
                  GestureDetector(
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
                  ),
                  
                  const Spacer(),
                  const Icon(Icons.help_outline, color: Colors.grey),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.grey),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
"""

    if "const Icon(Icons.help_outline, color: Colors.grey)," in content:
        content = content.replace(old_left_col.strip(), new_left_col.strip())

    # Right column header replacement
    old_right_header = """
                  if (accounts != null && accounts!.isNotEmpty)
                    ExpansionTile(
                      title: Text(
                        selectedAccount != null ? selectedAccount!['email'] : 'Konto auswählen',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      children: accounts!.map((acc) {
                        return ListTile(
                          title: Text(acc['email']),
                          onTap: () {
                            Navigator.pop(context);
                            if (onAccountSelected != null) {
                              onAccountSelected!(acc);
                            }
                          },
                        );
                      }).toList(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 16),
                      child: Text(
                        'Keine Konten',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
"""
    new_right_header = """
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
    if "ExpansionTile(" in content:
        content = content.replace(old_right_header.strip(), new_right_header.strip())

    with open('lib/widgets/mail_drawer.dart', 'w', encoding='utf-8') as f:
        f.write(content)

rewrite_drawer()
print("Updated MailDrawer")

