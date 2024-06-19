# Unofficial Pelican Panel Installer BETA 0.0.2  
# Created by dazeb. Free to anyone to use and distribute.  
# Please test the new beta branch and report any problems.  
# Created out of a love for Pelican Panel and its predecessor Pterodactyl ❤
#!/bin/bash

# Install web server (NGINX as an example)
apt install -y nginx
systemctl enable nginx
systemctl start nginx

# Ask for domain name
DOMAIN=$(whiptail --inputbox "Enter your domain name:" 8 78 --title "Domain Name" 3>&1 1>&2 2>&3)

# Configure NGINX
cat <<EOT > /etc/nginx/sites-available/pterodactyl
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/pterodactyl/public;

    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;  # Ensure this matches the installed PHP version
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOT

ln -s /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/pterodactyl
nginx -t
systemctl restart nginx

echo "Web server configuration completed successfully!"
