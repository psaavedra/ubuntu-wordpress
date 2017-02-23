#! /bin/bash -x

WP_DOMAIN="cdticvirtual.xunta.es"
WP_PATH="/var/www/wordpress"
WP_ADMIN_USERNAME="admin"
WP_LANG="gl_ES"
WP_ADMIN_EMAIL="noreply@cdticvirtual.xunta.es"
WP_DB_NAME="wordpress"
WP_DB_PASSWORD="$(pwgen -1 -s 12)"
MYSQL_ROOT_PASSWORD="$(pwgen -1 -s 12)"


###############################################################################
# Install mysql
echo "mysql-server-5.7 mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections

apt install -y nginx php php-mysql php-curl php-gd mysql-server php7.0-fpm

service mysql stop
service mysql start

mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE USER '$WP_DB_USERNAME'@'localhost' IDENTIFIED BY '$WP_DB_PASSWORD';
CREATE DATABASE $WP_DB_NAME;
GRANT ALL ON $WP_DB_NAME.* TO '$WP_DB_USERNAME'@'localhost';
EOF

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
sed -i 's/require_once/# require_once/' wp-config.php
echo "define('FS_METHOD', 'direct');" >> wp-config.php

cat << EOF >> wp-config.php
if(\$_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https'){
    \$_SERVER['HTTPS'] = 'on';
    \$_SERVER['SERVER_PORT'] = 443;
}
EOF

echo "require_once(ABSPATH . 'wp-settings.php');" >> wp-config.php

##############################################################################
# Install woocommerce plugin
cd $WP_PATH/public/wp-content/plugins
wget -O woocommerce-2.6.14.zip https://github.com/woocommerce/woocommerce/archive/2.6.14.zip
unzip  woocommerce-2.6.14.zip 
rm -f woocommerce-2.6.14.zip
mv woocommerce-* woocommerce

##############################################################################
mv /root/header.jpg /var/www/wordpress/public/wp-content/themes/twentyseventeen/assets/images/header.jpg

##############################################################################
# Set permissions
chown -R www-data:www-data $WP_PATH/public/

apt-get clean

##############################################################################
tee /etc/wp_setup.env << EOF
if [ -z \${WP_NAME} ]
then
  WP_DOMAIN=${WP_DOMAIN}
else
  WP_DOMAIN=\${WP_NAME}.${WP_DOMAIN}
fi
WP_LANG=${WP_LANG}
WP_ADMIN_USERNAME=${WP_ADMIN_USERNAME}
WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL}
WP_DB_NAME=${WP_DB_NAME}
WP_DB_PASSWORD=${WP_DB_PASSWORD}
WP_PATH=${WP_PATH}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
EOF

##############################################################################
tee /etc/rc.local << EOF
#!/bin/sh -e
/root/setup-wp.sh
/bin/bash
EOF

chmod +x /etc/rc.local
