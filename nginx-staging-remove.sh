#!/usr/bin/env bash
# Purpose: WordPress staging for nginx
# Source: https://guides.wp-bullet.com
# Adapted
# Author: Mike

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "You must be root or a sudo user to run this script"
    exit 1
fi

MYSQLROOTPASS=
NGINXSITEPATH=/etc/nginx/sites-available
NGINXSITESENABLED=/etc/nginx/sites-enabled
SITEPATH=/var/www
SITELIST=($(ls -lh $NGINXSITEPATH | awk '{print $9}'))

# check MySQL root password is set
if [ -z "$MYSQLROOTPASS" ]; then
    echo "MySQL root password not set"
    exit
fi

#check if sites-available directory exists
if [ ! -d "$NGINXSITEPATH" ]; then
    echo "Sites available directory doesn't exist"
    exit
fi

#capture first parameter
VHOST="$1"

if [ -z "$VHOST" ]; then
    echo "What is the name of your virtual host?"
    echo "Virtual hosts found:\n ${SITELIST[@]} "
    read VHOST
fi

if [ ! -f $NGINXSITEPATH/$VHOST ]; then
    echo "$VHOST not found"
    exit
fi

VHOSTPATH=$NGINXSITEPATH/$VHOST
EXTRACTEDPATH=$(grep "root " $VHOSTPATH | awk '{print $2}' | tr -d ";")
# server_name without www
EXTRACTEDDOMAIN=$(grep server_name $VHOSTPATH | awk '{ gsub("www\.", ""); print $2 }' | tr -d ";")

#extract database information
DB=$(grep DB_NAME $EXTRACTEDPATH/wp-config.php | awk -F ["\'"] '{ print $4 }')
DBUSER=$(grep DB_USER $EXTRACTEDPATH/wp-config.php | awk -F ["\'"] '{ print $4 }')


#create new db user, pass
mysql -u root -p${MYSQLROOTPASS} -e "DROP USER ${DBUSER}@localhost;"
mysql -u root -p${MYSQLROOTPASS} -e "DROP DATABASE ${DB};"
mysql -u root -p${MYSQLROOTPASS} -e "FLUSH PRIVILEGES;"

#remove nginx virtualhost

unlink $SITESENABLED/$VHOST
rm $VHOSTPATH
rm -rf $EXTRACTEDPATH

#reload nginx
service nginx reload

#print results
echo "Staging domain is $EXTRACTEDDOMAIN removed"
echo "Staging path is $EXTRACTEDPATH removed"
