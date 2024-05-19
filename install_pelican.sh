#!/bin/bash

# Function to print messages in green
print_success() {
    echo -e "\e[32m$1\e[0m"
}

# Function to print messages in red
print_error() {
    echo -e "\e[31m$1\e[0m"
}

# Check if whiptail is installed, if not install it
if ! command -v whiptail &> /dev/null; then
    print_error "whiptail is not installed. Installing..."
    sudo apt-get update && sudo apt-get install -y whiptail
    if [ $? -ne 0 ]; then
        print_error "Failed to install whiptail."
        exit 1
    else
        print_success "whiptail installed successfully."
    fi
fi

# Get user input for OS and webserver
OS=$(whiptail --title "Select Operating System" --menu "Choose your OS" 15 60 4 \
"Ubuntu 22.04" "" \
"Ubuntu 24.04" "" \
"Rocky Linux 9" "" \
"Debian 12" "" 3>&1 1>&2 2>&3)

WEBSERVER=$(whiptail --title "Select Webserver" --menu "Choose your webserver" 15 60 4 \
"NGINX" "" \
"Apache" "" 3>&1 1>&2 2>&3)

# Function to add ondrej/php repository
add_php_repo() {
    if ! grep -q "^deb .*$OS" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
        print_success "Adding ondrej/php repository..."
        sudo add-apt-repository ppa:ondrej/php -y
        if [ $? -ne 0 ]; then
            print_error "Failed to add ondrej/php repository."
            exit 1
        else
            print_success "ondrej/php repository added successfully."
        fi
    else
        print_success "ondrej/php repository already exists."
    fi
}

# Function to install dependencies
install_dependencies() {
    print_success "Installing dependencies..."
    sudo apt-get update
    sudo apt-get install -y php8.2 php8.2-gd php8.2-mysql php8.2-mbstring php8.2-bcmath php8.2-xml php8.2-curl php8.2-zip php8.2-intl php8.2-sqlite3 php8.2-fpm curl tar composer redis-server
    if [ "$WEBSERVER" == "NGINX" ]; then
        sudo apt-get install -y nginx
    elif [ "$WEBSERVER" == "Apache" ]; then
        sudo apt-get install -y apache2
    fi
    if [ $? -ne 0 ]; then
        print_error "Failed to install dependencies."
        exit 1
    else
        print_success "Dependencies installed successfully."
    fi
}

# Function to install MariaDB
install_mariadb() {
    print_success "Installing MariaDB..."
    curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
    sudo apt-get install -y mariadb-server
    if [ $? -ne 0 ]; then
        print_error "Failed to install MariaDB."
        exit 1
    else
        print_success "MariaDB installed successfully."
    fi
}

# Function to create MySQL user and database
setup_mysql() {
    print_success "Setting up MySQL user and database..."
    MYSQL_ROOT_PASSWORD=$(whiptail --passwordbox "Enter the MySQL root password:" 10 60 3>&1 1>&2 2>&3)
    MYSQL_PELICAN_PASSWORD=$(whiptail --passwordbox "Enter the password for the 'pelican' MySQL user:" 10 60 3>&1 1>&2 2>&3)

    sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER 'pelican'@'127.0.0.1' IDENTIFIED BY '$MYSQL_PELICAN_PASSWORD';"
    sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE panel;"
    sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON panel.* TO 'pelican'@'127.0.0.1';"
    sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

    if [ $? -ne 0 ]; then
        print_error "Failed to set up MySQL user and database."
        exit 1
    else
        print_success "MySQL user and database set up successfully."
    fi
}

# Function to create directories and download files
create_directories_and_download() {
    if [ ! -d /var/www/pelican ]; then
        print_success "Creating directories and downloading files..."
        sudo mkdir -p /var/www/pelican
        cd /var/www/pelican
        sudo curl -Lo panel.tar.gz https://github.com/pelican-dev/panel/releases/latest/download/panel.tar.gz
        sudo tar -xzvf panel.tar.gz
        sudo chmod -R 755 storage/* bootstrap/cache/
        if [ $? -ne 0 ]; then
            print_error "Failed to create directories and download files."
            exit 1
        else
            print_success "Directories created and files downloaded successfully."
        fi
    else
        print_success "Directories already exist. Skipping download."
    fi
}

# Function to install composer dependencies
install_composer_dependencies() {
    if [ ! -d /var/www/pelican/vendor ]; then
        print_success "Installing composer dependencies..."
        cd /var/www/pelican
        sudo composer install --no-dev --optimize-autoloader
        if [ $? -ne 0 ]; then
            print_error "Failed to install composer dependencies."
            exit 1
        else
            print_success "Composer dependencies installed successfully."
        fi
    else
        print_success "Composer dependencies already installed."
    fi
}

# Function to configure environment
configure_environment() {
    if [ ! -f /var/www/pelican/.env ]; then
        print_success "Configuring environment..."
        cd /var/www/pelican
        sudo php artisan p:environment:setup
        sudo php artisan p:environment:database
        if [ $? -ne 0 ]; then
            print_error "Failed to configure environment."
            exit 1
        else
            print_success "Environment configured successfully."
        fi
    else
        print_success "Environment already configured."
    fi
}

# Function to set up mail
setup_mail() {
    if (whiptail --title "Mail Setup" --yesno "Do you want to set up mail?" 10 60); then
        sudo php artisan p:environment:mail
        if [ $? -ne 0 ]; then
            print_error "Failed to set up mail."
            exit 1
        else
            print_success "Mail set up successfully."
        fi
    fi
}

# Function to initialize database
initialize_database() {
    if [ ! -f /var/www/pelican/database/initialized ]; then
        print_success "Initializing database..."
        cd /var/www/pelican
        sudo php artisan migrate --seed --force
        if [ $? -ne 0 ]; then
            print_error "Failed to initialize database."
            exit 1
        else
            touch /var/www/pelican/database/initialized
            print_success "Database initialized successfully."
        fi
    else
        print_success "Database already initialized."
    fi
}

# Function to create admin user
create_admin_user() {
    if (whiptail --title "Admin User Setup" --yesno "Do you want to create an admin user?" 10 60); then
        sudo php artisan p:user:make
        if [ $? -ne 0 ]; then
            print_error "Failed to create admin user."
            exit 1
        else
            print_success "Admin user created successfully."
        fi
    fi
}

# Function to configure crontab
configure_crontab() {
    if ! sudo crontab -l -u www-data | grep -q "artisan schedule:run"; then
        print_success "Configuring crontab..."
        echo "* * * * * php /var/www/pelican/artisan schedule:run >> /dev/null 2>&1" | sudo tee -a /etc/crontab
        if [ $? -ne 0 ]; then
            print_error "Failed to configure crontab."
            exit 1
        else
            print_success "Crontab configured successfully."
        fi
    else
        print_success "Crontab already configured."
    fi
}

# Function to set permissions
set_permissions() {
    print_success "Setting permissions..."
    if [ "$WEBSERVER" == "NGINX" ]; then
        sudo chown -R www-data:www-data /var/www/pelican
    elif [ "$WEBSERVER" == "Apache" ]; then
        sudo chown -R www-data:www-data /var/www/pelican
    fi
    if [ $? -ne 0 ]; then
        print_error "Failed to set permissions."
        exit 1
    else
        print_success "Permissions set successfully."
    fi
}

# Function to configure NGINX
configure_nginx() {
    if [ "$WEBSERVER" == "NGINX" ]; then
        DOMAIN=$(whiptail --inputbox "Enter your domain or IP address (Note: IPs cannot be used with SSL):" 10 60 3>&1 1>&2 2>&3)
        if [ ! -f /etc/nginx/sites-available/pelican.conf ]; then
            print_success "Creating new NGINX configuration file..."
            cat <<EOL | sudo tee /etc/nginx/sites-available/pelican.conf
server {
    listen 80;
    server_name $DOMAIN;

    root /var/www/pelican/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/pelican.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

            if [ $? -ne 0 ]; then
                print_error "Failed to create new NGINX configuration file."
                exit 1
            else
                print_success "New NGINX configuration file created successfully."
            fi

            print_success "Enabling new NGINX configuration..."
            sudo ln -s /etc/nginx/sites-available/pelican.conf /etc/nginx/sites-enabled/pelican.conf
            if [ $? -ne 0 ]; then
                print_error "Failed to enable new NGINX configuration."
                exit 1
            else
                print_success "New NGINX configuration enabled successfully."
            fi

            print_success "Restarting NGINX..."
            sudo systemctl restart nginx
            if [ $? -ne 0 ]; then
                print_error "Failed to restart NGINX."
                exit 1
            else
                print_success "NGINX restarted successfully."
            fi
        else
            print_success "NGINX configuration already exists."
        fi
    fi
}

# Function to configure Redis queue worker
configure_redis_queue_worker() {
    print_success "Configuring Redis queue worker..."

    cat <<EOL | sudo tee /etc/systemd/system/pelican.service
# Pelican Queue File
# ----------------------------------

[Unit]
Description=Pelican Queue Service
After=redis-server.service

[Service]
# On some systems the user and group might be different.
# Some systems use \`apache\` or \`nginx\` as the user and group.
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pelican/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOL

    if [ "$OS" == "Rocky Linux 9" ]; then
        sudo sed -i 's/redis-server.service/redis.service/' /etc/systemd/system/pelican.service
    fi

    sudo systemctl enable --now redis-server
    sudo systemctl enable --now pelican.service

    if [ $? -ne 0 ]; then
        print_error "Failed to configure Redis queue worker."
        exit 1
    else
        print_success "Redis queue worker configured successfully."
    fi
}

# Main script execution
add_php_repo
install_dependencies
install_mariadb
setup_mysql
create_directories_and_download
install_composer_dependencies
configure_environment
setup_mail
initialize_database
create_admin_user
configure_crontab
set_permissions
configure_nginx
configure_redis_queue_worker

print_success "Pelican Panel installation and configuration completed successfully!"
