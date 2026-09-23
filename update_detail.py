import re

def update_detail():
    with open('lib/screens/email_detail_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    if "final int? accountId;" not in content:
        content = content.replace(
            "final dynamic email;",
            "final dynamic email;\n  final int? accountId;"
        )
        content = content.replace(
            "required this.email});",
            "required this.email, this.accountId});"
        )

    # Pass accountId to ComposeEmailScreen in reply/forward
    content = content.replace(
        "builder: (context) => ComposeEmailScreen(",
        "builder: (context) => ComposeEmailScreen(\n                        accountId: accountId,"
    )

    with open('lib/screens/email_detail_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

update_detail()
print("Updated email detail")

