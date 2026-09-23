import re

def rewrite():
    with open('lib/screens/email_detail_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    new_html = """
            HtmlWidget(
              email['body']?.toString() ?? '',
              textStyle: TextStyle(
                fontSize: 16.0,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.5,
              ),
              customStylesBuilder: (element) {
                if (element.classes.contains('a')) {
                  return {'color': 'blue'};
                }
                return null;
              },
            ),
"""
    # Replace from Html( up to },\n            ),
    idx_start = content.find("            Html(")
    if idx_start != -1:
        idx_end = content.find("            ),", idx_start)
        if idx_end != -1:
            idx_end += len("            ),")
            content = content[:idx_start] + new_html.strip() + "\n" + content[idx_end:]
            with open('lib/screens/email_detail_screen.dart', 'w', encoding='utf-8') as f:
                f.write(content)
            print("Success")
rewrite()

