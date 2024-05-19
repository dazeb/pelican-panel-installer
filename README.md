# Unofficial Pelican Panel Installer Beta 0.0.1
A shell script to install Pelican Panel on a VPS or Virtual Machine. (Still in development but currently working) 🚧

Pelican Panel is the successor to Pterodactyl, the game hosting platform. 

In the below example we are using two VM's hosted on a homelab Proxmox host.

### Requirements:   
- Ubuntu 24.04 (Recommended) ✅  
- VPS or Virtual Machine ✅  
- IP Address ✅  
- SSL SUPPORT ❌  

## Usage  

**Only IP Addresses are supported at the moment because another script will need to be used for SSL creation**

Download and run the installer to your VM or VPS. The installer will ask you some questions.

### Download and set executable
```shell
wget https://raw.githubusercontent.com/dazeb/pelican-installer/main/install_pelican.sh
chmod +x install_pelican.sh
```

### Run the script
```shell
./install_pelican.sh
```

### What the script installs:
- Adds the `ondrej/php` repository.
- Installs dependencies including:
  - PHP 8.2 and required PHP extensions (`gd`, `mysql`, `mbstring`, `bcmath`, `xml`, `curl`, `zip`, `intl`, `sqlite3`, `fpm`).
  - MySQL server.
  - `curl`, `tar`, and `composer`.
  - NGINX or Apache webserver (based on user selection).
- Creates necessary directories and downloads the Pelican Panel files.
- Installs composer dependencies.
- Configures the environment using artisan commands.
- Sets up mail configuration (optional).
- Initializes the database.
- Creates an admin user (optional).
- Configures crontab for scheduled tasks.
- Sets appropriate file permissions.
- Configures NGINX (if selected as the webserver).

You can run the script more than once. For instance, if you want to create a new admin user after forgetting to create one initially, you can run the script again without negative consequences.  

## Run Webserver Config (nginx support)  

### Download and set executable
```shell
wget https://raw.githubusercontent.com/dazeb/pelican-installer/main/webserver_config_nginx.sh
chmod +x webserver_config_nginx.sh
```

### Run the config script
```shell
./webserver_config_nginx.sh
```

# Wings Installer  

### Requirements:   
- Ubuntu 24.04 (Recommended) ✅  
- VPS, Virtual Machine, LXC with nesting enabled ✅  
- IP Address ✅  
- SSL SUPPORT ❌  

Same as before, download and run the script.  

### Download and set executable
```shell
wget https://raw.githubusercontent.com/dazeb/pelican-installer/main/install_wings.sh
chmod +x install_wings.sh
```

### Run the script
```shell
./install_wings.sh
```

### What the script does:
- Checks and installs Docker if not already installed.
- Checks and installs Docker Compose if not already installed.
- Creates necessary directories and downloads the Wings executable.
- Configures Wings by prompting the user to paste the configuration from the Pelican host.
- Starts Wings in debug mode to ensure it runs without errors.
- Daemonizes Wings using systemd to run it as a background service.

The script will ask you to copy the configuration from your Pelican host. Paste the config in the file and press `ctrl+x`, then `y`, then `enter` and the script will proceed.

Go into your admin panel, add the node, and create the server.
