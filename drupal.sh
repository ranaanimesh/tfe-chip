#!/bin/bash

DBSTRING=$1

# Fix Apache
a2enmod rewrite || true
mv /tmp/apache.conf /etc/apache2/sites-available/000-default.conf
/etc/init.d/apache2 restart

# Install drush
wget http://files.drush.org/drush-unstable.phar
chmod +x drush-unstable.phar
mv drush-unstable.phar /usr/local/bin/drush

rm -rf /var/www/html
drush -y dl drupal-8.0.0 --destination=/tmp/drupal
mv /tmp/drupal/* /var/www/html
rmdir /tmp/drupal
builtin cd /var/www/html
drush -y si --db-url=mysql://${DBSTRING}
chown -R www-data.www-data /var/www/html/sites/default/files
