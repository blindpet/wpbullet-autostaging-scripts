#!/usr/bin/env bash
# Purpose: WordPress staging remover for Apache
# Source: https://guides.wp-bullet.com
# Adapted
# Author: Mike

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "You must be root or a sudo user to run this script"
    exit 1
fi

# define mysql root password
MYSQLROOTPASS=

# define path to Apache virtual hosts
APACHESITEPATH=/etc/apache2/sites-available

# where WordPress sites are
SITEPATH=/var/www

# generate array of sites to display to user
SITELIST=($(ls -lh $APACHESITEPATH | awk '{print $9}'))

#capture first parameter
VHOST="$1"

# check MySQL root password is set
if [ -z "$MYSQLROOTPASS" ]; then
    echo "MySQL root password not set"
    exit
fi

# check if sites-available directory exists
if [ ! -d "$APACHESITEPATH" ]; then
    echo "Sites available directory doesn't exist"
    exit
fi

# check vhost exists and prompt
if [ -z "$VHOST" ]; then
    echo "What is the name of your virtual host?"
    echo "Virtual hosts found:\n ${SITELIST[@]} "
    read VHOST
fi

# check vhost exists
if [ ! -f $APACHEPATH/$VHOST ]; then
    echo "$VHOST not found"
    exit
fi

VHOSTPATH=$APACHESITEPATH/$VHOST
EXTRACTEDPATH=$(grep DocumentRoot $VHOSTPATH | grep -v "#" | awk '{ print $2 }')
# server_name without www
EXTRACTEDDOMAIN=$(grep ServerName $VHOSTPATH | grep -v "#" | awk '{ gsub("www\.", ""); print $2 }')
#extract siteurl

#extract database information
DB=$(grep DB_NAME $EXTRACTEDPATH/wp-config.php | awk -F ["\'"] '{ print $4 }')
DBUSER=$(grep DB_USER $EXTRACTEDPATH/wp-config.php | awk -F ["\'"] '{ print $4 }')


#delete db and its user
mysql -u root -p${MYSQLROOTPASS} -e "DROP USER ${DBUSER}@localhost;"
mysql -u root -p${MYSQLROOTPASS} -e "DROP DATABASE ${DB};"
mysql -u root -p${MYSQLROOTPASS} -e "FLUSH PRIVILEGES;"

#remove nginx virtualhost

a2dissite $VHOST
rm $VHOSTPATH
rm -rf $EXTRACTEDPATH

#reload nginx
service apache2 reload

#print results
echo "Staging domain is $EXTRACTEDDOMAIN removed"
echo "Staging path is $EXTRACTEDPATH removed"
