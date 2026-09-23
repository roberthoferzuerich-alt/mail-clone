import re

def update_drawer():
    with open('lib/widgets/mail_drawer.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    old_constructor = """
class MailDrawer extends StatelessWidget {
  final String currentFolder;
  final Map<String, int> unreadCounts;
  final Function(String) onFolderSelected;

  const MailDrawer({
    super.key,
    required this.currentFolder,
    required this.unreadCounts,
    required this.onFolderSelected,
  });
"""
    new_constructor = """
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
"""
    content = content.replace(old_constructor.strip(), new_constructor.strip())

    old_header = """
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 16),
                    child: Text(
                      'Alle Konten',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
"""
    new_header = """
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
    content = content.replace(old_header.strip(), new_header.strip())

    with open('lib/widgets/mail_drawer.dart', 'w', encoding='utf-8') as f:
        f.write(content)

update_drawer()
print("Updated mail drawer")

