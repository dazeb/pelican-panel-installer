# Unofficial Pelican Panel Installer BETA 0.0.2  
# Created by dazeb. Free to anyone to use and distribute.  
# Please test the new beta branch and report any problems.  
# Created out of a love for Pelican Panel and its predecessor Pterodactyl ❤
#!/bin/bash

# Update and install necessary packages
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl tar

# Add Docker repository and install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Enable and start Docker service
sudo systemctl enable --now docker

# Create a user for Wings
sudo useradd -m -d /etc/pelican -s /bin/false pelican

# Download and install Wings
cd /etc/pelican
sudo curl -Lo wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
sudo chmod +x wings

# Create Wings configuration file
whiptail --msgbox "Please go to your Panel administrative view, select Nodes from the sidebar, and create a new node. Copy the configuration code block and paste it into a new file called config.yml in /etc/pelican." 15 60
sudo nano /etc/pelican/config.yml

# Create systemd service for Wings
sudo tee /etc/systemd/system/wings.service <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=pelican
Group=pelican
WorkingDirectory=/etc/pelican
ExecStart=/etc/pelican/wings
Restart=on-failure
StartLimitInterval=600

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Wings service
sudo systemctl enable --now wings

echo "Wings installation completed successfully!"
