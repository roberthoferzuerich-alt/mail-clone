import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/settings_screen.dart';

class MailDrawer extends StatelessWidget {
  final String currentFolder;
  final Map<String, int> unreadCounts;
  final List<dynamic>? accounts;
  final Map<String, dynamic>? selectedAccount;
  final Function(Map<String, dynamic>)? onAccountSelected;
  final Function(String) onFolderSelected;

  const MailDrawer({
    super.key,
    required this.currentFolder,
    required this.unreadCounts,
    this.accounts,
    this.selectedAccount,
    this.onAccountSelected,
    required this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: Row(
        children: [
          // Schmale linke Leiste
          Material(
            color: isDark ? Colors.black54 : Colors.grey.shade100,
            child: SizedBox(
              width: 70,
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
            ),
          ),
          // Breiter rechter Bereich
          Expanded(
            child: Material(
              color: Theme.of(context).cardColor,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 40),
                  if (accounts != null && accounts!.isNotEmpty)
                    ExpansionTile(
                      title: Text(
                        selectedAccount != null
                            ? selectedAccount!['email']
                            : 'Konto auswählen',
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
                  _buildDrawerItem(
                    context,
                    Icons.inbox,
                    'Posteingang',
                    'inbox',
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.edit_outlined,
                    'Entwürfe',
                    'drafts',
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.inventory_2_outlined,
                    'Archiv',
                    'archive',
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.send_outlined,
                    'Gesendet',
                    'sent',
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.delete_outline,
                    'Gelöscht',
                    'trash',
                  ),
                  _buildDrawerItem(
                    context,
                    Icons.folder_off_outlined,
                    'Junk-E-Mail',
                    'junk',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String folder,
  ) {
    final isSelected = currentFolder == folder;
    final count = unreadCounts[folder] ?? 0;
    final badge = count > 0 ? count.toString() : '';
    return ListTile(
      leading: Icon(icon, color: isSelected ? outlookBlue : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? outlookBlue : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: badge.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? outlookBlue.withOpacity(0.2)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: isSelected ? outlookBlue : Colors.black54,
                  fontSize: 12,
                ),
              ),
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        onFolderSelected(folder);
      },
    );
  }
}
