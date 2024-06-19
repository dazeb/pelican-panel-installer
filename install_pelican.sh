# Unofficial Pelican Panel Installer BETA 0.0.2  
# Created by dazeb. Free to anyone to use and distribute.  
# Please test the new beta branch and report any problems.  
# Created out of a love for Pelican Panel and its predecessor Pterodactyl ❤  
#!/bin/bash

# Update and install necessary packages
apt update
apt upgrade -y
apt install -y curl wget sudo lsb-release gnupg whiptail

# Ask for MySQL root password
MYSQL_ROOT_PASSWORD=$(whiptail --passwordbox "Enter MySQL root password:" 8 78 --title "MySQL Root Password" 3>&1 1>&2 2>&3)

# Install MariaDB
apt install -y mariadb-server
systemctl start mariadb
systemctl enable mariadb

# Secure MariaDB installation
mysql_secure_installation

# Ask for MySQL user password
MYSQL_USER="pterodactyl"
MYSQL_PASSWORD=$(whiptail --passwordbox "Enter password for MySQL user 'pterodactyl':" 8 78 --title "MySQL User Password" 3>&1 1>&2 2>&3)
MYSQL_DATABASE="pterodactyl"

# Create MySQL user and database
mysql -u root -p$MYSQL_ROOT_PASSWORD <<MYSQL_SCRIPT
CREATE DATABASE $MYSQL_DATABASE;
CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Install Redis
apt install -y redis-server
systemctl enable redis-server
systemctl start redis-server

# Install PHP and dependencies
apt install -y php php-fpm php-mysql php-redis php-xml php-mbstring php-zip php-gd php-curl

# Download and configure Pelican Panel
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# Configure environment
cp .env.example .env
sed -i "s/DB_DATABASE=pterodactyl/DB_DATABASE=$MYSQL_DATABASE/" .env
sed -i "s/DB_USERNAME=pterodactyl/DB_USERNAME=$MYSQL_USER/" .env
sed -i "s/DB_PASSWORD=secret/DB_PASSWORD=$MYSQL_PASSWORD/" .env

# Install Composer and dependencies
curl -sS https://getcomposer.org/installer | php
php composer.phar install --no-dev --optimize-autoloader

# Generate application key
php artisan key:generate --force

# Run database migrations
php artisan migrate --seed --force

# Set up crontab
(crontab -l ; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -

# Set permissions
chown -R www-data:www-data /var/www/pterodactyl

echo "Pelican Panel installation completed successfully!"
