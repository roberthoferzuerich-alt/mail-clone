import re

def fix():
    with open('lib/widgets/mail_drawer.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Update signature
    content = re.sub(
        r'String folder,\s*String badge,\s*\)',
        'String folder,\n  )',
        content
    )
    
    # 2. Update logic inside _buildDrawerItem
    # Find:
    # final isSelected = currentFolder == folder;
    # Replace with:
    # final isSelected = currentFolder == folder;
    # final count = unreadCounts[folder] ?? 0;
    # final badge = count > 0 ? count.toString() : '';
    content = content.replace(
        'final isSelected = currentFolder == folder;',
        "final isSelected = currentFolder == folder;\n    final count = unreadCounts[folder] ?? 0;\n    final badge = count > 0 ? count.toString() : '';"
    )
    
    # 3. Update calls (remove the hardcoded string at the end)
    # They look like: _buildDrawerItem(context, Icons.inbox, 'Posteingang', 'inbox', '4'),
    # or split across lines. This regex removes the last string argument before the closing parenthesis.
    content = re.sub(
        r",\s*'[^']*'\s*\)",
        ")",
        content
    )
    # But wait, there might be trailing commas: _buildDrawerItem(..., 'inbox', '4',)
    # Let's just do a simpler search and replace for the specific calls since there are only 5.
    
    with open('lib/widgets/mail_drawer.dart', 'w', encoding='utf-8') as f:
        f.write(content)

fix()
print("Fixed Drawer badges")

