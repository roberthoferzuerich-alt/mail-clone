import re

def update_script():
    with open(r'C:\laragon\www\mail-clone-backend\public\setup_pi.sh', 'r', encoding='utf-8') as f:
        content = f.read()

    new_env_setup = """cp .env.example .env
echo "DB_CONNECTION=mysql" >> .env
echo "DB_HOST=127.0.0.1" >> .env
echo "DB_PORT=3306" >> .env
echo "DB_DATABASE=mail_clone" >> .env
echo "DB_USERNAME=root" >> .env
echo "DB_PASSWORD=\\"A67d201#\\"" >> .env
sed -i 's/APP_ENV=local/APP_ENV=local/' .env
sed -i 's/APP_DEBUG=false/APP_DEBUG=true/' .env
"""
    content = re.sub(
        r"cp \.env\.example \.env.*?sed -i 's/APP_DEBUG=false/APP_DEBUG=true/' \.env\n",
        new_env_setup,
        content,
        flags=re.DOTALL
    )

    with open(r'C:\laragon\www\mail-clone-backend\public\setup_pi.sh', 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)

update_script()
print("Updated .env setup")

