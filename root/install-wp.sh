#! /bin/bash -x

WP_DOMAIN="wp.cdticvirtual.xunta.es"
WP_PATH="/var/www/wordpress"
WP_ADMIN_USERNAME="admin"
# WP_ADMIN_PASSWORD="$(pwgen -1 -s 12)"
WP_ADMIN_PASSWORD="admin"
WP_ADMIN_EMAIL="noreply@cdticvirtual.xunta.es"
WP_DB_NAME="wordpress"
WP_DB_PASSWORD="$(pwgen -1 -s 12)"
MYSQL_ROOT_PASSWORD="$(pwgen -1 -s 12)"

echo "127.0.0.1 $WP_DOMAIN" >> /etc/hosts

apt-get update

###############################################################################
# Install mysql
echo "mysql-server-5.7 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections

apt install -y nginx php php-mysql php-curl php-gd mysql-server php7.0-fpm

service mysql stop
service mysql start
service php7.0-fpm stop
service php7.0-fpm start

mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE USER '$WP_DB_USERNAME'@'localhost' IDENTIFIED BY '$WP_DB_PASSWORD';
CREATE DATABASE $WP_DB_NAME;
GRANT ALL ON $WP_DB_NAME.* TO '$WP_DB_USERNAME'@'localhost';
EOF

###############################################################################
# Install nginx
mkdir -p $WP_PATH/public $WP_PATH/logs
tee /etc/nginx/sites-available/$WP_DOMAIN <<EOF
server {
  listen 80;
  server_name $WP_DOMAIN www.$WP_DOMAIN;

  root $WP_PATH/public;
  index index.php;

  access_log $WP_PATH/logs/access.log;
  error_log $WP_PATH/logs/error.log;

  location / {
    try_files \$uri \$uri/ /index.php?\$args;
  }

  location ~ \.php\$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php7.0-fpm.sock;
  }
}
EOF

ln -s /etc/nginx/sites-available/$WP_DOMAIN /etc/nginx/sites-enabled/$WP_DOMAIN
rm -f /etc/nginx/sites-enabled/default
service nginx restart

###############################################################################
# Install WordPress
rm -rf $WP_PATH/public/ # !!!
mkdir -p $WP_PATH/public/
chown -R www-data:www-data $WP_PATH/public/
cd $WP_PATH/public/

wget https://wordpress.org/latest.tar.gz
tar xf latest.tar.gz --strip-components=1
rm latest.tar.gz

mv wp-config-sample.php wp-config.php
sed -i s/database_name_here/$WP_DB_NAME/ wp-config.php
sed -i s/username_here/$WP_DB_USERNAME/ wp-config.php
sed -i s/password_here/$WP_DB_PASSWORD/ wp-config.php
echo "define('FS_METHOD', 'direct');" >> wp-config.php

chown -R www-data:www-data $WP_PATH/public/


##############################################################################
# Final test
curl "http://$WP_DOMAIN/wp-admin/install.php?step=2" \
	  --data-urlencode "weblog_title=$WP_DOMAIN"\
    --data-urlencode "user_name=$WP_ADMIN_USERNAME" \
	  --data-urlencode "admin_email=$WP_ADMIN_EMAIL" \
	  --data-urlencode "admin_password=$WP_ADMIN_PASSWORD" \
	  --data-urlencode "admin_password2=$WP_ADMIN_PASSWORD" \
	  --data-urlencode "pw_weak=1"

apt-get clean

cat << EOF
WP_DOMAIN=${WP_DOMAIN}
WP_ADMIN_USERNAME=${WP_ADMIN_USERNAME}
WP_ADMIN_PASSWORD=${WP_ADMIN_PASSWORD}
WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL}
WP_DB_NAME=${WP_DB_NAME}
WP_DB_PASSWORD=${WP_DB_PASSWORD}
WP_PATH=${WP_PATH}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
EOF


