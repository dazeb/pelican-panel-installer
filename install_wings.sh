# Unofficial Pelican Panel Installer BETA 0.0.2  
# Created by dazeb. Free to anyone to use and distribute.  
# Please test the new beta branch and report any problems.  
# Created out of a love for Pelican Panel and its predecessor Pterodactyl ❤
#!/bin/bash

# Update and install necessary packages
apt update
apt upgrade -y
apt install -y curl wget sudo lsb-release gnupg whiptail

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
systemctl enable docker
systemctl start docker

# Create a user for Wings
useradd -m -d /etc/pterodactyl -s /bin/bash pterodactyl
usermod -aG docker pterodactyl

# Download and configure Wings
su - pterodactyl -c "mkdir -p /etc/pterodactyl"
su - pterodactyl -c "curl -Lo /etc/pterodactyl/config.yml https://raw.githubusercontent.com/pterodactyl/wings/develop/config.yml"
su - pterodactyl -c "curl -Lo /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
su - pterodactyl -c "chmod +x /usr/local/bin/wings"

# Set up Wings as a systemd service
cat <<EOT > /etc/systemd/system/wings.service
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=pterodactyl
WorkingDirectory=/etc/pterodactyl
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=600

[Install]
WantedBy=multi-user.target
EOT

systemctl enable wings
systemctl start wings

echo "Wings installation completed successfully!"
