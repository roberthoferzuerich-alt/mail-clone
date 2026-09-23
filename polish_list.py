import re

def polish_email_list():
    with open('lib/screens/email_list_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Change maxLines: 1 to maxLines: 2 for the body text
    old_body = """
                                  Text(
                                    email['body'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
"""
    new_body = """
                                  Text(
                                    email['body'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.grey, height: 1.3),
                                  ),
"""
    
    # Also adjust the subject font weight slightly (already bold if unread, but let's make it look sharper)
    old_subject = """
                                  Text(
                                    email['subject'],
                                    style: TextStyle(
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
"""
    new_subject = """
                                  Text(
                                    email['subject'],
                                    style: TextStyle(
                                      fontWeight: isRead
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
"""

    if "maxLines: 1," in content:
        content = content.replace(old_body.strip(), new_body.strip())
        content = content.replace(old_subject.strip(), new_subject.strip())
        
        with open('lib/screens/email_list_screen.dart', 'w', encoding='utf-8') as f:
            f.write(content)
        print("Polished email list!")
    else:
        print("Could not find body snippet")

polish_email_list()
