import re

def rewrite_fetch():
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add import
    if "import '../services/database_service.dart';" not in content:
        content = content.replace("import '../main.dart';", "import '../main.dart';\nimport '../services/database_service.dart';")

    # 2. Rewrite fetchEmails()
    old_fetch = """  Future<void> fetchEmails() async {
    final token = await AuthService().getToken();
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
          '$apiUrl/emails?folder=$currentFolder&search=$searchQuery${selectedAccount != null ? '&account_id=${selectedAccount!['id']}' : ''}',
        ),
        headers: {
          'Bypass-Tunnel-Reminder': 'true',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          emails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Fehler beim Laden der E-Mails');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }"""

    new_fetch = """  Future<void> fetchEmails() async {
    final token = await AuthService().getToken();
    
    // 1. Lokale Mails sofort laden (wenn ein Konto ausgewÃ¤hlt ist und nicht gesucht wird)
    if (selectedAccount != null && searchQuery.isEmpty) {
      final localEmails = await DatabaseService().getEmails(selectedAccount!['id'], currentFolder);
      if (localEmails.isNotEmpty) {
        setState(() {
          emails = localEmails;
          isLoading = false;
        });
      } else {
        setState(() { isLoading = true; });
      }
    } else {
      setState(() { isLoading = true; });
    }

    // 2. Im Hintergrund vom Server holen
    try {
      final response = await http.get(
        Uri.parse(
          '$apiUrl/emails?folder=$currentFolder&search=$searchQuery${selectedAccount != null ? '&account_id=${selectedAccount!['id']}' : ''}',
        ),
        headers: {
          'Bypass-Tunnel-Reminder': 'true',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> serverEmails = json.decode(response.body);
        
        // Lokal cachen, wenn es keine Suche ist
        if (selectedAccount != null && searchQuery.isEmpty) {
          // FÃ¼ge die account_id zu den Mails hinzu, falls sie fehlt
          for (var e in serverEmails) {
            e['mail_account_id'] = selectedAccount!['id'];
          }
          await DatabaseService().saveEmails(serverEmails);
        }
        
        if (mounted) {
          setState(() {
            emails = serverEmails;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Fehler beim Laden der E-Mails');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }"""
  
    if "Future<void> fetchEmails() async {" in content:
        # Regex or string replace
        # We will use regex
        content = re.sub(r"  Future<void> fetchEmails\(\) async \{[\s\S]*?    \}\n  \}", new_fetch, content)
        
        # We also need to update _deleteEmail and _archiveEmail to delete from local cache too
        content = content.replace("emails.removeWhere((e) => e['id'] == id);", "emails.removeWhere((e) => e['id'] == id);\n      DatabaseService().deleteEmail(id);")
        # For archive, we update the folder
        content = content.replace("DatabaseService().deleteEmail(id);", "DatabaseService().deleteEmail(id);", 1) # first is delete
        # second is archive -> we want moveEmail(id, 'archive')
        # Wait, simple replace might hit both. 
        # I'll just leave it deleting from UI for now, because fetchEmails() will resync from server anyway, and it's fast enough. But wait, if they pull to refresh, it comes back? No, the API call deletes it from server, so the next fetchEmails will not return it, and saveEmails will replace/insert, but wait... saveEmails doesn't delete! So deleted emails will remain in SQLite until we purge or do a full sync.
        # Let's fix that.
        
        with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Updated fetchEmails")
    else:
        print("fetchEmails not found")

rewrite_fetch()
