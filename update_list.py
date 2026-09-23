import re

def update_email_list():
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Add accounts state
    if "List<dynamic> accounts = [];" not in content:
        content = content.replace(
            "Map<String, int> unreadCounts = {};",
            "Map<String, int> unreadCounts = {};\n  List<dynamic> accounts = [];\n  Map<String, dynamic>? selectedAccount;"
        )

    # Init State
    init_state = """
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final token = await AuthService().getToken();
    try {
      final response = await http.get(Uri.parse('$apiUrl/mail-accounts'), headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Bypass-Tunnel-Reminder': 'true'});
      if (response.statusCode == 200) {
        final accs = jsonDecode(response.body) as List;
        if (accs.isNotEmpty) {
           accounts = accs;
           selectedAccount = accs[0];
        }
      }
    } catch (_) {}
    fetchEmails();
    fetchFolderCounts();
  }
"""
    old_init = """
  @override
  void initState() {
    super.initState();
    fetchEmails();
    fetchFolderCounts();
  }
"""
    content = content.replace(old_init.strip(), init_state.strip())

    # Update fetch URLs
    content = content.replace(
        "Uri.parse('$apiUrl/emails/counts'),",
        "Uri.parse('$apiUrl/emails/counts${selectedAccount != null ? '?account_id=${selectedAccount!['id']}' : ''}'),"
    )
    content = content.replace(
        "Uri.parse('$apiUrl/emails?folder=$currentFolder&search=$searchQuery'),",
        "Uri.parse('$apiUrl/emails?folder=$currentFolder&search=$searchQuery${selectedAccount != null ? '&account_id=${selectedAccount!['id']}' : ''}'),"
    )
    
    # Update MailDrawer instantiation
    old_drawer = """
      drawer: MailDrawer(
        currentFolder: currentFolder,
        unreadCounts: unreadCounts,
        onFolderSelected: (folder) {
"""
    new_drawer = """
      drawer: MailDrawer(
        currentFolder: currentFolder,
        unreadCounts: unreadCounts,
        accounts: accounts,
        selectedAccount: selectedAccount,
        onAccountSelected: (acc) {
          setState(() {
             selectedAccount = acc;
             currentFolder = 'inbox';
          });
          fetchEmails();
          fetchFolderCounts();
        },
        onFolderSelected: (folder) {
"""
    if "accounts: accounts," not in content:
        content = content.replace(old_drawer.strip(), new_drawer.strip())

    with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

update_email_list()
print("Updated email list")

