#!/bin/bash -e
SCRIPT_DIR=$( cd $(dirname $0) ; pwd -P )

source $SCRIPT_DIR/configure.sh 

MYSQL_USER=root
MYSQL_PWD=root

ENCRYPTED_PASSWD=$(openssl passwd -1 $HOST_PASSWD)

###################################################################
# create_account
#
# Input: none
# Description: this function creates the system account. The
#              account will have a HOME folder where there will
#              be the DocumentRoot=HOME/www and the website
#              will be installed in HOME/www/DOMAIN
# Return: none
###################################################################
create_account() {
    sudo useradd -d /home/$HOST_USER -g admin -s /bin/bash -p $ENCRYPTED_PASSWD $HOST_USER
    sudo mkdir -p $DOCUMENT_ROOT
    sudo chown -R $HOST_USER:admin $DOCUMENT_ROOT
}

###################################################################
# download_wp
#
# Input: none
# Description: this function downloads, extracts, and configure  a 
#              wordpress package. 
# Return: none
###################################################################
download_wp() {
    # Download and extract wordpress
    sudo wget https://github.com/sasadangelo/$WEBSITE_TYPE/archive/$WEBSITE_VERSION.tar.gz -O $DOCUMENT_ROOT/$WEBSITE_VERSION.tar
    sudo tar xvf $DOCUMENT_ROOT/$WEBSITE_VERSION.tar -C $DOCUMENT_ROOT
    sudo mv $DOCUMENT_ROOT/$WEBSITE_TYPE-$WEBSITE_VERSION $DOCUMENT_ROOT/$DOMAIN
    sudo chown -R $HOST_USER:admin $DOCUMENT_ROOT/$DOMAIN
    sudo rm -f $DOCUMENT_ROOT/$WEBSITE_VERSION.tar.gz

    # Configure wp-config.php
    sed "s/DATABASE_NAME/$DATABASE_NAME/g" wordpress/wp-config.php > tmp/wp-config.php
    sed -i "s/DATABASE_USER/$DATABASE_USER/g" tmp/wp-config.php
    sed -i "s/DATABASE_PASSWD/$DATABASE_PASSWD/g" tmp/wp-config.php
    sed -i "s:DOMAIN:$DOMAIN:g" tmp/wp-config.php
    sudo cp tmp/wp-config.php $DOCUMENT_ROOT/$DOMAIN
    sudo chown $HOST_USER:admin $DOCUMENT_ROOT/$DOMAIN/wp-config.php
}

###################################################################
# create_db
#
# Input: none
# Description: this function creates an empty database and import
#              the data.
# Return: none
###################################################################
create_db() {
    # Create database
    sed "s/DATABASE_NAME/$DATABASE_NAME/g" mysql/database.sql > tmp/database.sql 
    sed -i "s/DATABASE_USER/$DATABASE_USER/g" tmp/database.sql
    sed -i "s/DATABASE_PASSWD/$DATABASE_PASSWD/g" tmp/database.sql
    mysql -u $MYSQL_USER -p$MYSQL_PWD < tmp/database.sql

    # Import wordpress data into the database
    #sudo sed -i "s/utf8mb4_unicode_520_ci/utf8mb4_unicode_ci/g" mysql/mywebsite_db.sql
    sudo sed -i "s:WEBSITE:$DOMAIN:g" $DOCUMENT_ROOT/$DOMAIN/mywebsite_db.sql
    mysql -u $DATABASE_USER -p$DATABASE_PASSWD $DATABASE_NAME < $DOCUMENT_ROOT/$DOMAIN/mywebsite_db.sql
}

###################################################################
# configure_nginx
#
# Input: none
# Description: this function configure nginx adding the new website.
# Return: none
###################################################################
configure_nginx() {
    # Configure NGINX
    sed "s:DOCUMENT_ROOT:$DOCUMENT_ROOT:g" nginx/site > tmp/site
    sed -i "s:DOMAIN:$DOMAIN:g" tmp/site
    sudo cp tmp/site /etc/nginx/sites-available/$DOMAIN
    sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN
    sudo service nginx restart
}

###################################################################
# main
#
# Input: none
# Description: the main procedure
# Return: none
###################################################################
main() {
    mkdir -p tmp
    create_account
    download_wp
    create_db
    configure_nginx
    rm -rf tmp
}

###################################################################
# Main block
###################################################################
main
