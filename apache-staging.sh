#!/usr/bin/env bash
# Purpose: WordPress staging for Apache
# Source: https://guides.wp-bullet.com
# Adapted
# Author: Mike
MYSQLROOTPASS=
#user to run wp cli as
WPCLIUSER="www-data"
APACHESITEPATH=/etc/apache2/sites-available
#where WordPress paths are
SITEPATH=/var/www
SITELIST=($(ls -lh $APACHESITEPATH | awk '{print $9}'))
#generate hash based on date and use first 8 characters for subdomain
NEWHASH=$(date | sha1sum | awk '{ print substr($0,0,8)}')

#capture first parameter
VHOST="$1"

#if no parameter passed prompt user
if [ -z "$VHOST" ]; then
    echo "What is the name of your virtual host?"
    echo "Virtual hosts found:\n ${SITELIST[@]} "
    read VHOST
fi

#check if vhost exists
if [ ! -f $APACHEPATH/$VHOST ]; then
    echo "$VHOST not found"
    exit
fi

ORIGINALVHOST=$APACHESITEPATH/$VHOST
EXTRACTEDPATH=$(grep DocumentRoot $APACHESITEPATH/$VHOST | grep -v "#" | awk '{ print $2 }')
# server_name without www
EXTRACTEDDOMAIN=$(grep ServerName $APACHESITEPATH/$VHOST | grep -v "#" | awk '{ gsub("www\.", ""); print $2 }')
SITEURL=$(wp option get siteurl --path=$EXTRACTEDPATH --skip-plugins --skip-themes --allow-root | awk -F ["\/"] '{ print $3 }')

#make unique staging name for DNS and new path
STAGINGDOMAIN=$NEWHASH.$EXTRACTEDDOMAIN
STAGINGPATH="$SITEPATH/$STAGINGDOMAIN"
STAGINGVHOST="$APACHESITEPATH/$STAGINGDOMAIN.conf"

#multisitetest
MULSTISITETEST=(grep "MULTISITE" $EXTRACTEDPATH/wp-config.php)

if [ ! -z "$MULTISITETEST" ]; then
    echo "multisite not supported"
    exit
fi

#copy Apache virtual host
cp $APACHESITEPATH/$VHOST $STAGINGVHOST

#replace old server_name with new server_name
sed -i "/ServerName /c\ServerName $STAGINGDOMAIN" $STAGINGVHOST

#root folder replacement
sed -i "/DocumentRoot /c\DocumentRoot $STAGINGPATH" $STAGINGVHOST

#copy over wordpress folder
cp -r $EXTRACTEDPATH $STAGINGPATH

###
# MySQL stuff
###

#extract original DB stuff
OLDDB=$(grep DB_NAME $EXTRACTEDPATH/wp-config.php | awk -F ["\'"] '{ print $4 }')
OLDDBUSER=$(grep DB_USER $EXTRACTEDPATH/wp-config.php | awk -F ["\'"] '{ print $4 }')
OLDDBPASS=$(grep DB_PASSWORD $EXTRACTEDPATH/wp-config.php | awk -F ["\'"] '{ print $4 }')
NEWDB=$OLDDB$NEWHASH
NEWDBUSER=$OLDDBUSER$NEWHASH
NEWDBPASS=$OLDDBPASS$NEWHASH

#export original db and search replace 
sudo -u $WPCLIUSER wp search-replace $SITEURL $STAGINGDOMAIN --export=/tmp/$STAGINGDOMAIN.sql --path=$EXTRACTEDPATH --skip-themes --skip-plugins
#sudo -u www-data wp search-replace $EXTRACTEDDOMAIN $STAGINGDOMAIN '*_options' --export=/tmp/$STAGINGDOMAIN-url.sql --path=$EXTRACTEDPATH --skip-themes --skip-plugins

#create new db user, pass
mysql -u root -p${MYSQLROOTPASS} -e "CREATE USER ${NEWDBUSER}@localhost IDENTIFIED BY '${NEWDBPASS}';"
mysql -u root -p${MYSQLROOTPASS} -e "CREATE DATABASE ${NEWDB};"
mysql -u root -p${MYSQLROOTPASS} -e "GRANT ALL PRIVILEGES ON ${NEWDB}.* TO ${NEWDBUSER}@localhost IDENTIFIED BY '${NEWDBPASS}';"
mysql -u root -p${MYSQLROOTPASS} -e "FLUSH PRIVILEGES;"

#replace staging db info

sed -i "/define('DB_NAME', /c\define('DB_NAME', '${NEWDB}');" ${STAGINGPATH}/wp-config.php
sed -i "/define('DB_USER', /c\define('DB_USER', '${NEWDBUSER}');" ${STAGINGPATH}/wp-config.php
sed -i "/define('DB_PASSWORD', /c\define('DB_PASSWORD', '${NEWDBPASS}');" ${STAGINGPATH}/wp-config.php

#permissions fix

chown -R www-data:www-data $STAGINGPATH/
find $STAGINGPATH -type f -exec chmod 644 {} +
find $STAGINGPATH -type d -exec chmod 755 {} +

#import new db

sudo -u $WPCLIUSER wp db import /tmp/$STAGINGDOMAIN.sql --path=$STAGINGPATH --skip-themes --skip-plugins
#sudo -u www-data wp db import /tmp/$STAGINGDOMAIN-url.sql --path=$STAGINGPATH --skip-themes --skip-plugins
sudo -u $WPCLIUSER wp search-replace $EXTRACTEDPATH $STAGINGPATH --path=$STAGINGPATH --skip-themes --skip-plugins
#turn off indexing of search engines
sudo -u $WPCLIUSER wp option update blog_public 0 --path=$STAGINGPATH --skip-themes --skip-plugins

sudo rm /tmp/$STAGINGDOMAIN.sql

#reload Apache
a2ensite $STAGINGDOMAIN
service apache2 reload

#print results
echo "Staging domain is $STAGINGDOMAIN"
echo "Staging path is $STAGINGPATH"
