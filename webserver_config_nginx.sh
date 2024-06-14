# Unofficial Pelican Panel Installer BETA 0.0.2  
# Created by dazeb. Free to anyone to use and distribute.  
# Please test the new beta branch and report any problems.  
# Created out of a love for Pelican Panel and its predecessor Pterodactyl ❤
#!/bin/bash

# Function to install and configure Apache
install_apache() {
    sudo apt-get update
    sudo apt-get install -y apache2 libapache2-mod-php8.3

    # Configure Apache for Pelican Panel
    sudo tee /etc/apache2/sites-available/pelican.conf <<EOF
<VirtualHost *:80>
    ServerAdmin admin@your_domain
    DocumentRoot /var/www/pelican/public
    ServerName your_domain_or_IP

    <Directory /var/www/pelican/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php8.3-fpm.sock|fcgi://localhost"
    </FilesMatch>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

    # Enable Apache site and rewrite module
    sudo a2ensite pelican
    sudo a2enmod rewrite
    sudo systemctl restart apache2
}

# Function to install and configure NGINX
install_nginx() {
    sudo apt-get update
    sudo apt-get install -y nginx

    # Configure NGINX for Pelican Panel
    sudo tee /etc/nginx/sites-available/pelican <<EOF
server {
    listen 80;
    server_name your_domain_or_IP;

    root /var/www/pelican/public;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

    # Enable NGINX site and restart NGINX
    sudo ln -s /etc/nginx/sites-available/pelican /etc/nginx/sites-enabled/
    sudo systemctl restart nginx
}

# Function to install and configure Caddy
install_caddy() {
    sudo apt-get update
    sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo apt-key add -
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo apt-get update
    sudo apt-get install -y caddy

    # Configure Caddy for Pelican Panel
    sudo tee /etc/caddy/Caddyfile <<EOF
your_domain_or_IP {
    root * /var/www/pelican/public
    encode gzip
    php_fastcgi unix//run/php/php8.3-fpm.sock
    file_server
}
EOF

    # Restart Caddy service
    sudo systemctl restart caddy
}

# Function to install and configure Lighttpd
install_lighttpd() {
    sudo apt-get update
    sudo apt-get install -y lighttpd php8.3-fpm

    # Enable FastCGI and PHP modules
    sudo lighty-enable-mod fastcgi
    sudo lighty-enable-mod fastcgi-php

    # Configure Lighttpd for Pelican Panel
    sudo tee /etc/lighttpd/conf-available/15-pelican.conf <<EOF
server.modules += ( "mod_fastcgi" )

$HTTP["host"] == "your_domain_or_IP" {
    server.document-root = "/var/www/pelican/public"
    index-file.names += ( "index.php", "index.html", "index.htm" )

    fastcgi.server = ( ".php" =>
        ( "localhost" =>
            (
                "socket" => "/run/php/php8.3-fpm.sock",
                "broken-scriptfilename" => "enable"
            )
        )
    )
}
EOF

    # Enable Pelican configuration and restart Lighttpd
    sudo lighty-enable-mod pelican
    sudo systemctl restart lighttpd
}

# Main script logic
echo "Select the web server to install and configure for Pelican Panel:"
echo "1) Apache"
echo "2) NGINX"
echo "3) Caddy"
echo "4) Lighttpd"
read -p "Enter your choice [1-4]: " choice

case $choice in
    1)
        install_apache
        ;;
    2)
        install_nginx
        ;;
    3)
        install_caddy
        ;;
    4)
        install_lighttpd
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "Web server installation and configuration completed successfully!"
fi

print_success "NGINX configuration for Pelican Panel completed successfully!"
