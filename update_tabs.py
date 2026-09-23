import re

def update_body_tabs():
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the body: RefreshIndicator block
    # We will replace `body: RefreshIndicator(` with `body: Column(children: [_buildOutlookTabs(), Expanded(child: RefreshIndicator( ... ))],),`
    
    body_regex = r"body:\s*RefreshIndicator\([\s\S]*?onRefresh:\s*_syncImapEmails,\s*child:\s*isLoading[\s\S]*?itemCount:\s*emails\.length,\s*itemBuilder:\s*\(context,\s*index\)\s*\{[\s\S]*?return\s*Dismissible\("
    
    # Actually, it's easier to just do string replacement
    
    old_body_start = """
      body: RefreshIndicator(
        onRefresh: _syncImapEmails,
        child: isLoading
"""
    new_body_start = """
      body: Column(
        children: [
          _buildOutlookTabs(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _syncImapEmails,
              child: isLoading
"""
    
    # Need to close the Expanded and Column after the RefreshIndicator
    old_floating = """
      floatingActionButton: FloatingActionButton(
"""
    new_floating = """
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
"""
    
    # And we need to add the `_buildOutlookTabs()` method and state variables
    old_state_start = """
class _EmailListScreenState extends State<EmailListScreen> {
  List<dynamic> emails = [];
  bool isLoading = true;
"""
    new_state_start = """
class _EmailListScreenState extends State<EmailListScreen> {
  List<dynamic> emails = [];
  bool isLoading = true;
  bool showRelevant = true; // Neu für Outlook Tabs
"""

    tabs_method = """
  Widget _buildOutlookTabs() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white : outlookBlue;
    final inactiveColor = Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => showRelevant = true),
            child: Column(
              children: [
                Text(
                  'Relevant',
                  style: TextStyle(
                    fontWeight: showRelevant ? FontWeight.bold : FontWeight.normal,
                    color: showRelevant ? activeColor : inactiveColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                if (showRelevant)
                  Container(height: 2, width: 40, color: activeColor)
                else
                  const SizedBox(height: 2),
              ],
            ),
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: () => setState(() => showRelevant = false),
            child: Column(
              children: [
                Text(
                  'Sonstige',
                  style: TextStyle(
                    fontWeight: !showRelevant ? FontWeight.bold : FontWeight.normal,
                    color: !showRelevant ? activeColor : inactiveColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                if (!showRelevant)
                  Container(height: 2, width: 40, color: activeColor)
                else
                  const SizedBox(height: 2),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              // Filter logic here later
            },
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 18, color: isDark ? Colors.white : Colors.black87),
                const SizedBox(width: 4),
                Text('Filter', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
"""
    
    # We will insert `tabs_method` before `  @override\n  Widget build(BuildContext context) {`
    
    if "body: RefreshIndicator(" in content:
        content = content.replace(old_body_start, new_body_start)
        content = content.replace(old_floating, new_floating)
        content = content.replace(old_state_start, new_state_start)
        content = content.replace("  @override\n  Widget build(BuildContext context) {", tabs_method + "\n  @override\n  Widget build(BuildContext context) {")
        
        with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Added Outlook tabs")
    else:
        print("Failed to find body")

update_body_tabs()

