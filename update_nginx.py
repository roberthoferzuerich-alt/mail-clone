import re

def update_nginx():
    with open(r'C:\laragon\www\mail-clone-backend\public\setup_pi.sh', 'r', encoding='utf-8') as f:
        content = f.read()

    new_nginx = """cat << 'EOF' | sudo tee /etc/nginx/sites-available/mail-clone
server {
    listen 8444 ssl;
    listen [::]:8444 ssl;
    server_name rhz.internet-box.ch;
    root /var/www/mail-clone-backend/public;

    index index.php index.html index.htm;

    ssl_certificate /etc/letsencrypt/live/rhz.internet-box.ch/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rhz.internet-box.ch/privkey.pem;

    # 1. Standard Laravel Routing
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # 2. PHP Verarbeitung
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;

        include fastcgi_params;
        fastcgi_param REQUEST_METHOD $request_method;
    }

    # 3. Sicherheit
    location ~ /\.ht {
        deny all;
    }
}
EOF"""

    content = re.sub(r"cat << 'EOF' \| sudo tee /etc/nginx/sites-available/mail-clone.*?EOF", new_nginx, content, flags=re.DOTALL)
    
    # Update the final echo message
    content = re.sub(
        r'echo "Setup abgeschlossen! Dein Laravel Backend lÃ¤uft jetzt auf http://192\.168\.1\.119:8001"',
        r'echo "Setup abgeschlossen! Dein Laravel Backend laeuft jetzt auf https://rhz.internet-box.ch:8444"',
        content
    )

    with open(r'C:\laragon\www\mail-clone-backend\public\setup_pi.sh', 'w', encoding='utf-8') as f:
        f.write(content)

update_nginx()
print("Updated Nginx config")

