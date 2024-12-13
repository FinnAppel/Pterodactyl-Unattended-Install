#!/bin/bash

# Variables
hostname=$(hostname)
db_user="pterodactyl"
db_name="panel"
db_password=$(openssl rand -base64 16) # Generate a random password
txt_file="/home/pterodactyl_credentials.txt"
admin_email="changethis@luxehost.nl"  # Set your desired email address here
admin_password=$(openssl rand -base64 16)  # Generate a random password for the admin user
dbnode_password=$(openssl rand -base64 16) 

# Detect public IP or local IP
ip_address=$(hostname -I | awk '{print $1}')

# Detect operating system
OS="$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '\"')"

# Print OS name
echo     
echo     
echo "======================================"
echo "    Pterodactyl Unattended Install"
echo "    Your OS: $OS"
echo "    Checking if your OS is supported."
echo "======================================"
echo 
sleep 2

# Check if OS is supported
if [[ "$OS" == "Ubuntu" ]]; then
    echo "Your OS is supported. Proceeding with the installation."
    sleep 4
else
    echo "Sorry, your OS: $OS is not supported."
    exit 1
fi

# Update and install dependencies
echo "Updating system and installing dependencies..."
sleep 2

export DEBIAN_FRONTEND=noninteractive

# Add "add-apt-repository" command
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg

# Add additional repositories for PHP (Ubuntu 20.04 and Ubuntu 22.04)
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php\

# Add Redis official APT repository
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

# MariaDB repo setup script (Ubuntu 20.04)
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

# Update repositories list
apt update
apt -y upgrade


# Install Dependencies
apt -y install php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server

# Install Composer
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# Download Files
echo "Downloading and installing Pterodactyl Panel..."
sleep 2
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# Create database and user
echo "Creating database and user..."
sleep 3
mysql -u root -e "CREATE DATABASE ${db_name};"
mysql -u root -e "CREATE USER '${db_user}'@'127.0.0.1' IDENTIFIED BY '${db_password}';"
mysql -u root -e "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'127.0.0.1';"\
mysql -u root -e "FLUSH PRIVILEGES;"

# Set up environment variables
cp .env.example .env
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
sed -i "s/DB_PASSWORD=secret/DB_PASSWORD=${db_password}/g" .env
sed -i "s/DB_USERNAME=pterodactyl/DB_USERNAME=${db_user}/g" .env
sed -i "s/DB_DATABASE=pterodactyl/DB_DATABASE=${db_name}/g" .env

echo "Running Pterodactyl API Key setup..."
php artisan key:generate --force
sleep 2

# Run the environment setup command (no prompts)
echo "Running Pterodactyl environment setup..."
sleep 2

  # Fill in environment:setup automatically
  php artisan p:environment:setup \
    --author="${admin_email}" \
    --url="${ip_address}" \
    --timezone="UTC" \
    --cache="redis" \
    --session="redis" \
    --queue="redis" \
    --redis-host="localhost" \
    --redis-pass="null" \
    --redis-port="6379" \
    --settings-ui=true \
    --telemetry=no


echo "Running Pterodactyl database setup..."
sleep 2
  php artisan p:environment:database \
    --host="127.0.0.1" \
    --port="3306" \
    --database="${db_name}" \
    --username="${db_user}" \
    --password="${db_password}"

php artisan migrate --seed --force

echo "Running Pterodactyl permissions setup..."
sleep 2
chown -R www-data:www-data /var/www/pterodactyl/*
* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1

echo "Running Pterodactyl user creation..."
sleep 2
  php artisan p:user:make \
    --email="${admin_email}" \
    --username="${hostname}" \
    --name-first="Name" \
    --name-last="Surname" \
    --password="${admin_password}" \
    --admin=1

echo "Create the pteroq.service file"

sleep 5

# Fetch the pteroq.service file from the GitHub repository
curl -s https://raw.githubusercontent.com/FinnAppel/Pterodactyl-Unattended-Install/main/config/pteroq.service > /etc/systemd/system/pteroq.service


sudo systemctl enable --now redis-server

sudo systemctl enable --now pteroq.service


# Configure Nginx with dynamic IP
echo "Configuring Nginx for IP: ${ip_address}..."

sleep 3

rm /etc/nginx/sites-enabled/default

# Fetch the configuration file and replace placeholders
curl -s https://raw.githubusercontent.com/FinnAppel/Pterodactyl-Unattended-Install/main/config/pterodactyl.conf | \
sed "s/\${ip_address}/${ip_address}/g" > /etc/nginx/sites-available/pterodactyl.conf


sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf

sudo systemctl restart nginx

# Allow ports
echo "Allowing ports."
sleep 1
ufw allow 80
echo "Enabled Port 80"
sleep 1
ufw allow 443
echo "Enabled Port 443"
sleep 1
ufw allow 2022
echo "Enabled Port 2022"
sleep 1
ufw allow 8080
echo "Enabled Port 8080"
sleep 1
ufw allow 3306
echo "Enabled Port 3306"
sleep 1


# Install Pterodactyl Daemon
echo "Installing Pterodactyl Daemon..."
sleep 2
curl -sSL https://get.docker.com/ | CHANNEL=stable bash
sudo systemctl enable --now docker
GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"
sudo mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
sudo chmod u+x /usr/local/bin/wings

# Install Pterodactyl Node Database
echo "Creating Pterodactyl Node Database..."
sleep 2
mysql -u root -p
CREATE USER 'pterodactyluser'@'127.0.0.1' IDENTIFIED BY '${dbnode_password}';"
GRANT ALL PRIVILEGES ON *.* TO 'pterodactyluser'@'127.0.0.1' WITH GRANT OPTION;
exit


# Create Pterodactyl credentials file
echo "Creating credentials file in /home directory..."
echo "Panel URL: http://${ip_address}" >> ${txt_file}
PLEASE CHANGE THE LOGIN
echo "Admin Username: ${hostname}" >> ${txt_file}
echo "Admin Email: ${admin_email}" >> ${txt_file}
echo "Admin Password: ${admin_password}" >> ${txt_file}

echo "Database Username: ${db_user}" >> ${txt_file}
echo "Database Password: ${db_password}" >> ${txt_file}
echo "Database Panel: ${db_name}" >> ${txt_file}

echo "Database Node Username: pterodactyluser" >> ${txt_file}
echo "Database Node Password: ${dbnode_password}" >> ${txt_file}
echo "Database Host: 127.0.0.1" >> ${txt_file}

# Output completion message
echo " "
echo "Pterodactyl installation completed. Credentials are saved in ${txt_file}"
echo "If this was helpful consider leaving a star on my GitHub repository.
