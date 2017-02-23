#! /bin/bash -x

. /etc/wp_setup.env

WP_ADMIN_PASSWORD="$(pwgen -1 -s 12)"

echo "127.0.0.1 $WP_DOMAIN" >> /etc/hosts

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

###############################################################################
service mysql stop
service php7.0-fpm stop
service nginx stop

service mysql start
service php7.0-fpm start
service nginx start

##############################################################################
# Wordpress setup
WP_SUBMIT="Instalar WordPress"

curl "http://$WP_DOMAIN/wp-admin/install.php?step=1" --data-urlencode "language=$WP_LANG"
curl "http://$WP_DOMAIN/wp-admin/install.php?step=2" \
	  --data-urlencode "weblog_title=$WP_DOMAIN" \
	  --data-urlencode "user_name=$WP_ADMIN_USERNAME" \
	  --data-urlencode "admin_email=$WP_ADMIN_EMAIL" \
	  --data-urlencode "admin_password=$WP_ADMIN_PASSWORD" \
	  --data-urlencode "admin_password2=$WP_ADMIN_PASSWORD" \
	  --data-urlencode "pass1-text=$WP_ADMIN_PASSWORD" \
	  --data-urlencode "language=$WP_LANG" \
	  --data-urlencode "Submit=$WP_SUBMIT" \
	  --data-urlencode "pw_weak=on"


###############################################################################
# Activate authentication nginx

htpasswd -bc /etc/nginx/htpasswd $WP_ADMIN_USERNAME $WP_ADMIN_PASSWORD

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
    auth_basic "$WP_DOMAIN authentication user";                  
    auth_basic_user_file /etc/nginx/htpasswd; 

    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php7.0-fpm.sock;
  }
}
EOF

service nginx stop
service nginx start

##############################################################################
tee /etc/rc.local << EOF
#!/bin/sh -e
service mysql start
service php7.0-fpm start
service nginx start
bash
EOF
chmod +x /etc/rc.local

##############################################################################
cat << EOF > /etc/wp_setup.env
WP_DOMAIN=${WP_DOMAIN}
WP_LANG=${WP_LANG}
WP_ADMIN_USERNAME=${WP_ADMIN_USERNAME}
WP_ADMIN_PASSWORD=${WP_ADMIN_PASSWORD}
WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL}
WP_DB_NAME=${WP_DB_NAME}
WP_DB_PASSWORD=${WP_DB_PASSWORD}
WP_PATH=${WP_PATH}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
EOF


