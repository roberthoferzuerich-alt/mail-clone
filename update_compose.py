import re

def update_compose():
    with open('lib/screens/compose_email_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    if "final int? accountId;" not in content:
        content = content.replace(
            "final String? initialBody;",
            "final String? initialBody;\n  final int? accountId;"
        )
        content = content.replace(
            "this.initialBody,\n  });",
            "this.initialBody,\n    this.accountId,\n  });"
        )
    
    # In send function, add accountId to request
    old_send = """
      request.fields['sender'] = _toController.text;
      request.fields['subject'] = _subjectController.text;
      request.fields['body'] = _bodyController.text;
"""
    new_send = """
      request.fields['sender'] = _toController.text;
      request.fields['subject'] = _subjectController.text;
      request.fields['body'] = _bodyController.text;
      if (widget.accountId != null) {
          request.fields['account_id'] = widget.accountId.toString();
      }
"""
    content = content.replace(old_send.strip(), new_send.strip())

    with open('lib/screens/compose_email_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

update_compose()
print("Updated compose")

