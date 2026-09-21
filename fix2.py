import os
import re

def fix_drawer():
    with open('lib/widgets/mail_drawer.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # We messed up by regex substituting incorrectly. Let's do it cleanly:
    # First, undo the double context if any
    content = content.replace("context, context,", "context,")
    
    # Actually, the error was: The argument type 'IconData' can't be assigned to the parameter type 'BuildContext'
    # This means I added BuildContext context to the definition, but missed adding it to the CALLS.
    # Calls look like: _buildDrawerItem(Icons.inbox, 'Posteingang', 'inbox', '4'),
    # Let's fix them:
    content = re.sub(r'_buildDrawerItem\(\s*Icons\.', r'_buildDrawerItem(context, Icons.', content)
    
    with open('lib/widgets/mail_drawer.dart', 'w', encoding='utf-8') as f:
        f.write(content)

fix_drawer()
print("Fixed drawer.")
