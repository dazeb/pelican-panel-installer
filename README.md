# Pelican Panel Installer Beta 0.0.1
A shell script to install Pelican Panel on a VPS or Virtual Machine. (Still in development)

### Requirements:   
Ubuntu 24.04 (Recomended) ✅  
VPS or Virtual Machine ✅  
IP Address ✅  
SSL SUPPORT ❌  

## Usage  

**Only IP Addresses are supported at the moment because another script will need to be used for SSL creation**

Download and run the installer to your VM or VPS the installer will ask you some questions.


## Download and set executable
```shell
wget https://raw.githubusercontent.com/dazeb/pelican-installer/main/install_pelican.sh
chmod +x install_pelican.sh
```
Then run the script
```shell
./install_pelican.sh
```

You can run the script more than once. Lets say for instance you want to create a new admin user if you forgot to create one you can run the script again without negative consequences.  

## Run Webserver Config (nginx support)  

```shell
wget https://raw.githubusercontent.com/dazeb/pelican-installer/main/webserver_config_nginx.sh
chmod +x webserver_config_nginx.sh
```
Run the config script.  

```shell
./webserver_config_nginx.sh
```

# Wings Installer  

### Requirements:   
Ubuntu 24.04 (Recomended) ✅  
VPS or Virtual Machine ✅  
IP Address ✅  
SSL SUPPORT ❌  

Same as before, download and run the script.  

```shell
wget https://raw.githubusercontent.com/dazeb/pelican-installer/main/install_wings.sh
chmod +x install_wings.sh
```
Run the script  

```shell
./install_wings.sh
```

====
