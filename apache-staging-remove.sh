#!/usr/bin/env bash
# Purpose: WordPress staging remover for Apache
# Source: https://guides.wp-bullet.com
# Adapted
# Author: Mike
MYSQLROOTPASS=
APACHESITEPATH=/etc/apache2/sites-available
#where WordPress paths are
SITEPATH=/var/www
SITELIST=($(ls -lh $APACHESITEPATH | awk '{print $9}'))
#generate hash based on date and use first 8 characters for subdomain
NEWHASH=$(date | sha1sum | awk '{ print substr($0,0,8)}')

#capture first parameter
VHOST="$1"

if [ -z "$VHOST" ]; then
    echo "What is the name of your virtual host?"
    echo "Virtual hosts found:\n ${SITELIST[@]} "
    read VHOST
fi

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
