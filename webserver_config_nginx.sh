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

# Get user input for domain
DOMAIN=$(whiptail --inputbox "Enter your domain or IP address (Note: IPs cannot be used with SSL):" 10 60 3>&1 1>&2 2>&3)

# Remove the default NGINX configuration
print_success "Removing default NGINX configuration..."
sudo rm /etc/nginx/sites-enabled/default
if [ $? -ne 0 ]; then
    print_error "Failed to remove default NGINX configuration."
    exit 1
else
    print_success "Default NGINX configuration removed successfully."
fi

# Create the new NGINX configuration file
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

# Enable the new NGINX configuration
print_success "Enabling new NGINX configuration..."
sudo ln -s /etc/nginx/sites-available/pelican.conf /etc/nginx/sites-enabled/pelican.conf
if [ $? -ne 0 ]; then
    print_error "Failed to enable new NGINX configuration."
    exit 1
else
    print_success "New NGINX configuration enabled successfully."
fi

# Restart NGINX to apply the changes
print_success "Restarting NGINX..."
sudo systemctl restart nginx
if [ $? -ne 0 ]; then
    print_error "Failed to restart NGINX."
    exit 1
else
    print_success "NGINX restarted successfully."
fi

print_success "NGINX configuration for Pelican Panel completed successfully!"
