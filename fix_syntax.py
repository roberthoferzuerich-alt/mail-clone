def fix():
    with open('lib/screens/email_detail_screen.dart', 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    # We want to delete the lines:
    #                 "a": Style(color: outlookBlue),
    #               },
    #             ),
    
    start_del = -1
    for i, line in enumerate(lines):
        if '"a": Style(color: outlookBlue)' in line:
            start_del = i
            break
            
    if start_del != -1:
        # delete that line and the next two lines
        del lines[start_del:start_del+3]
        
    with open('lib/screens/email_detail_screen.dart', 'w', encoding='utf-8') as f:
        f.writelines(lines)
        
fix()
print("Fixed syntax")

