#!/bin/bash

print_green() {
  echo -e "\e[32m$1\e[0m"
}

print_red() {
  echo -e "\e[31m$1\e[0m"
}

check_command() {
    local cmd=$1
    if ! command -v "$cmd" &> /dev/null; then
        print_red "Command '$cmd' not found, skipping."
    else
        echo "$cmd"
    fi
}

if [[ $EUID -ne 0 ]]; then
  print_red "This script must be run as root."
  exit 1
fi

read -p "Do you want to remove Apache or Nginx? (apache/nginx): " web_server

print_green "Removing MySQL Server"
apt-get purge --auto-remove -y mysql-server

print_green "Removing PHP and Related Modules"
apt-get purge --auto-remove -y php php-mysql php-xml php-mbstring php-curl php-zip libapache2-mod-php php-common php-cli php-json php-fpm

if [[ $web_server == "apache" ]]; then
    print_green "Removing Apache2"
    apt-get purge --auto-remove -y apache2
else
    print_green "Removing Nginx"
    apt-get purge --auto-remove -y nginx
fi

print_green "Cleaning Up"
rm -rf /var/www/html/*
rm -rf /etc/apache2/sites-available/wordpress.conf
rm -rf /etc/nginx/sites-available/wordpress
rm -rf /etc/nginx/sites-enabled/wordpress
rm -rf /var/lib/mysql
rm -rf /etc/mysql

print_green "Package removal and cleanup complete."
