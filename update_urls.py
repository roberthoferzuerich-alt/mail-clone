import os
import glob

def replace_api_url():
    base_dir = r"C:\Users\rober\Flutter-Project\Work\mail_clone\lib"
    old_url = "https://strong-jeans-shave.loca.lt"
    new_url = "https://rhz.internet-box.ch:8444"
    
    for filepath in glob.glob(os.path.join(base_dir, '**', '*.dart'), recursive=True):
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        if old_url in content:
            content = content.replace(old_url, new_url)
            
            # Also remove Bypass-Tunnel-Reminder since we don't use Localtunnel anymore
            content = content.replace("'Bypass-Tunnel-Reminder': 'true',", "")
            content = content.replace("\"Bypass-Tunnel-Reminder\": \"true\",", "")
            
            # Specifically in compose_email_screen
            content = content.replace("request.headers['Bypass-Tunnel-Reminder'] = 'true';", "")
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated {filepath}")

replace_api_url()
