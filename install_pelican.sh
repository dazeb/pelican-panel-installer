# Unofficial Pelican Panel Installer BETA 0.0.2  
# Created by dazeb. Free to anyone to use and distribute.  
# Please test the new beta branch and report any problems.  
# Created out of a love for Pelican Panel and its predecessor Pterodactyl ❤  
#!/bin/bash  

# Update and install necessary packages
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y software-properties-common curl tar

# Add PHP repository and install PHP 8.3 and necessary extensions
sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update
sudo apt-get install -y php8.3 php8.3-gd php8.3-mysql php8.3-mbstring php8.3-bcmath php8.3-xml php8.3-curl php8.3-zip php8.3-intl php8.3-sqlite3 php8.3-fpm curl tar composer redis-server

# Install MariaDB
sudo apt-get install -y mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Create MariaDB alias for mysql
sudo ln -s /usr/bin/mariadb /usr/bin/mysql

# Secure MariaDB installation
sudo mysql_secure_installation

# Create database and user for Pelican Panel
DB_NAME="pelican"
DB_USER="pelicanuser"
DB_PASS="securepassword"

sudo mysql -u root -e "CREATE DATABASE ${DB_NAME};"
sudo mysql -u root -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

# Download and extract Pelican Panel
cd /var/www
sudo curl -Lo pelican.tar.gz https://github.com/pelicanpanel/pelican/releases/latest/download/pelican.tar.gz
sudo tar -xzvf pelican.tar.gz
sudo mv pelican-* pelican
cd pelican

# Install Composer dependencies
sudo composer install --no-dev --optimize-autoloader

# Set permissions and ownership
sudo chmod -R 755 /var/www/pelican/storage/* /var/www/pelican/bootstrap/cache/
sudo chown -R www-data:www-data /var/www/pelican

# Create .env file
sudo cp .env.example .env
sudo sed -i "s/DB_DATABASE=homestead/DB_DATABASE=${DB_NAME}/" .env
sudo sed -i "s/DB_USERNAME=homestead/DB_USERNAME=${DB_USER}/" .env
sudo sed -i "s/DB_PASSWORD=secret/DB_PASSWORD=${DB_PASS}/" .env
echo "TRUSTED_PROXIES=127.0.0.1" | sudo tee -a .env
echo "APP_BACKUP_DRIVER=daemon" | sudo tee -a .env

# Generate application key
sudo php artisan key:generate --force

# Run database migrations and seeders
sudo php artisan migrate --seed --force

# Configure NGINX
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

# Enable and start Redis service
sudo systemctl enable --now redis

# Configure crontab for www-data user
(crontab -l -u www-data 2>/dev/null; echo "* * * * * php /var/www/pelican/artisan schedule:run >> /dev/null 2>&1") | sudo crontab -u www-data -

# Display message for Wings configuration
whiptail --msgbox "Please go to your Panel administrative view, select Nodes from the sidebar, and create a new node. Copy the configuration code block and paste it into a new file called config.yml in /etc/pelican." 15 60
sudo nano /etc/pelican/config.yml

echo "Pelican Panel installation completed successfully!"
