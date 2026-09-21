import os
import re

def replace_in_file(path, old, new):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content.replace(old, new))

# 1. main_screen.dart uses ComposeEmailScreen and outlookBlue
replace_in_file('lib/screens/main_screen.dart', "import 'settings_screen.dart';", "import 'settings_screen.dart';\nimport 'compose_email_screen.dart';\nimport '../main.dart';")

# 2. mail_drawer.dart uses SettingsScreen and context inside onTap
replace_in_file('lib/widgets/mail_drawer.dart', "import '../main.dart';", "import '../main.dart';\nimport '../screens/settings_screen.dart';")

# Let's fix the context error in mail_drawer.dart:
# onTap: () {
#         Navigator.pop(context);
#         onFolderSelected(folder);
#       },
# Wait, context is missing in _buildDrawerItem because _buildDrawerItem signature is:
# Widget _buildDrawerItem(IconData icon, String title, String folder, String badge)
# Let's change it to Widget _buildDrawerItem(BuildContext context, IconData icon, String title, String folder, String badge)

def fix_drawer():
    with open('lib/widgets/mail_drawer.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Change signature
    content = content.replace("Widget _buildDrawerItem(\n    IconData icon,", "Widget _buildDrawerItem(\n    BuildContext context,\n    IconData icon,")
    content = content.replace("Widget _buildDrawerItem(IconData icon,", "Widget _buildDrawerItem(BuildContext context, IconData icon,")
    
    # Change calls
    content = re.sub(r'_buildDrawerItem\((Icons\.[a-zA-Z0-9_]+),', r'_buildDrawerItem(context, \1,', content)
    
    with open('lib/widgets/mail_drawer.dart', 'w', encoding='utf-8') as f:
        f.write(content)

fix_drawer()
print("Fixed.")
