import re

def fix_comma():
    with open('lib/widgets/mail_drawer.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # The regex replacement messed up the end of the text widget
    faulty = """
                    ),
                  ),,
                      ),
                    ),
"""
    fixed = """
                    ),
                  ),
"""
    content = content.replace(faulty, fixed)

    with open('lib/widgets/mail_drawer.dart', 'w', encoding='utf-8') as f:
        f.write(content)

fix_comma()
print("Fixed comma")
