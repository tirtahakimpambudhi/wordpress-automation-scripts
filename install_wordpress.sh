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
        print_red "Error: Command '$cmd' not found."
        exit 1
    fi
}

check_url() {
    local url=$1
    local response_code

    if [ -z "$url" ]; then
        echo "Error: No URL provided."
        return 1
    fi

    response_code=$(curl -o /dev/null -s -w "%{http_code}" "$url")

    if [ "$response_code" -ge 400 ]; then
        echo "Error: URL '$url' is not accessible. HTTP Status Code: $response_code"
        exit 1
    fi
}

if [[ $EUID -ne 0 ]]; then
  print_red "This script must be run as root."
  exit 1
fi

read -p "Do you want to use Apache or Nginx? (apache/nginx): " web_server

print_green "Update, Upgrade, and Install LAMP/LEMP"
apt update && apt upgrade -y

if [[ $web_server == "apache" ]]; then
    apt install -y apache2 mysql-server php7.4 libapache2-mod-php7.4 php7.4-mysql 
    apt install php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip php7.4-common php7.4-cli php7.4-json
    check_command "apache2"
else
    apt install -y nginx mysql-server php-fpm php-mysql php-xml php-mbstring php-curl php-zip php-common php-cli php-json
    check_command "nginx"
fi

check_command "mysql"
check_command "php"

print_green "Setup MySQL and WordPress Database"
mysql_secure_installation

read -p "WordPress Username: " wp_user
read -sp "WordPress Password: " wp_pass
echo
read -p "WordPress Database: " wp_db

mysql -e "CREATE DATABASE $wp_db; CREATE USER '$wp_user'@'localhost' IDENTIFIED BY '$wp_pass'; GRANT ALL PRIVILEGES ON $wp_db.* TO '$wp_user'@'localhost'; FLUSH PRIVILEGES;" -u root -p

print_green "Setup WordPress"
rm /var/www/html/index.html
wget https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
mv wordpress/* /var/www/html/
rm -rf wordpress latest.tar.gz

# Create wp-config.php with the provided credentials
cat > /var/www/html/wp-config.php << EOF
<?php
define('DB_NAME', '${wp_db}');
define('DB_USER', '${wp_user}');
define('DB_PASSWORD', '${wp_pass}');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');
\$table_prefix = 'wp_';
define('WP_DEBUG', false);
if ( ! defined( 'ABSPATH' ) ) {
    define('ABSPATH', __DIR__ . '/');
}
require_once ABSPATH . 'wp-settings.php';
EOF

print_green "Modification of Executable and Permissions for WordPress"
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

if [[ $web_server == "apache" ]]; then
    print_green "Configuration Apache and WordPress"
    cat > /etc/apache2/sites-available/wordpress.conf << EOF
<VirtualHost *:80>
    ServerAdmin admin@domain.com
    DocumentRoot /var/www/html
    ServerName domain.com

    <Directory /var/www/html>
        AllowOverride All
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

    a2ensite wordpress.conf
    a2enmod rewrite
    systemctl restart apache2
else
    print_green "Configuration Nginx and WordPress"
    php_fpm_socket=$(find /var/run/php/ -name "php*-fpm.sock" | head -n 1)

    cat > /etc/nginx/sites-available/wordpress << EOF
server {
    listen 80;
    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
    	include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${php_fpm_socket};
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

    ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
    #sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/ to restore default configuration
    unlink /etc/nginx/sites-enabled/default
    nginx -t
    systemctl restart nginx
    
fi

print_green "Installation Complete!"

