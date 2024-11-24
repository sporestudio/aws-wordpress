#!/usr/bin/env bash

## Automated script wordpress install ##

# Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColor="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purplecolor="\e[0;35m\033[1m"
turquoiseColour="\e[0;36\033[1m"
grayColour="\e[0;37m\033[1m"


## Variables for database
DB_NAME="wordpress"
DB_USER="wordpressuser"
DB_PASSWORD="#!The<3Admin"


function update() {
    echo "/n${yellowColour}[*]${endColour} Updating repositories..."
    apt update -y && apt upgrade -y
}


function allow_traffic() {
    ufw allow OpenSSH
    ufw allow "Apache Full"
    ufw allow --force enable
}


function dependencies() {
    clear
    dependencies=(wget unzip php-mysql)

    echo -e "${yellowColour}[*]${endColour}${grayColour} Checking necessary dependencies...${endColour}"
    sleep 2

    for program in "${dependencies[@]}"; do
        echo -ne "\n${yellowColour}[*]${endColour}${blueColor} Tool${endColour}${grayColour} $program${endColour}${blueColor}...${endColour}"

        test -f /usr/bin/$program

        if [ "$(echo $?)" == "0" ]; then
            echo -e "${greenColour}(V)${endColour}"
        else
            echo -e "${redColour}(X)${endColour}\n"
			echo -e "${yellowColour}[*]${endColour}${grayColour} Installing tool $program...${endColour}"
            sudo apt install -y $program
        fi
        sleep 1
    done  
}


function create_database() {
    clear
    echo -e "${yellowColour}[*]${endColour}${grayColour} Creating database...${endColour}"
    sleep 1

    mysql <<EOF
        CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
        CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
        GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
        FLUSH_PRIVILEGES;
        EXIT;
EOF
}


function download_wordpress() {
    clear
    echo -e "${yellowColour}[*]${endColour}${grayColour} Installing wordpress...${endColour}"
    sleep 1

    wget -c https://wordpress.org/latest.zip -O /tmp/latest.zip
    unzip -o /tmp/latest.zip -d /tmp/
    mv /tmp/wordpress /var/www/html/
}


function set_permissions() {
    chown -R www-data:www-data /var/www/html/wordpress
    chmod -R 755 /var/www/html/wordpress
}


function configure_wordpress() {
    cd /var/www/html/wordpress
    sudo cp wp-config-sample.php wp-config.php
    sudo sed -i "s/database_name_here/$DB_NAME/" wp-config.php
    sudo sed -i "s/username_here/$DB_USER/" wp-config.php
    sudo sed -i "s/password_here/$DB_PASSWORD/" wp-config.php

    # Generar claves únicas para WordPress
    AUTH_KEYS=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    echo "$AUTH_KEYS" | while read -r line; do
    sudo sed -i "0,/define('AUTH_KEY'/s|define('AUTH_KEY'.*|$line|" wp-config.php
    done
}


function set_apache() {
    clear
    echo -e "${yellowColour}[*]${endColour}${grayColour} Configuring virtual host for apache...${endColour}"
    sleep 1

    sudo tee /etc/apache2/sites-available/wordpress.conf > /dev/null <<EOL
        <VirtualHost *:80>
            ServerAdmin admin@localhost.com
            DocumentRoot /var/www/html/wordpress
            ErrorLog ${APACHE_LOG_DIR}/error.log
            CustomLog ${APACHE_LOG_DIR}/access.log combined
        </VirtualHost>
EOL

    a2ensite wordpress
    a2enmod rewrite
    systemctl restart apache2
}



# Program flow
function main() {
    if [ "$(id -u)" == "0" ]; then
        update
        allow_traffic
        dependecies
        create_database
        download_wordpress
        set_permissions
        configure_wordpress
        set_apache
    else
        echo -e "\n${redColour}[*]I'm not root${endColour}\n"
	    exit 2
    fi 
}

main