import re

def fix_html_widget():
    with open('lib/screens/email_detail_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Import replacement
    content = content.replace("import 'package:flutter_html/flutter_html.dart';", "import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';")

    # Widget replacement
    old_html = """
            Html(
              data: email['body'],
              style: {
                "body": Style(
                  fontSize: FontSize(16.0),
                  lineHeight: LineHeight(1.5),
                  color: isDark ? Colors.white : Colors.black87,
                ),
                "a": Style(
                  color: outlookBlue,
                ),
              },
            ),
"""
    new_html = """
            HtmlWidget(
              email['body'].toString(),
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

    if "Html(" in content:
        content = content.replace(old_html.strip(), new_html.strip())
        with open('lib/screens/email_detail_screen.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Updated HTML Widget")

fix_html_widget()
