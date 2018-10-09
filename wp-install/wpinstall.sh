#!/bin/bash -e
SCRIPT_DIR=$( cd $(dirname $0) ; pwd -P )
MYSQL_USER=root
MYSQL_PASSWD=root

source $SCRIPT_DIR/configure.sh

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
    echo "=== configure $HOST_USER account"
    if [ "$(id -u $HOST_USER > /dev/null 2>&1; echo $?)" != "0" ]; then
        sudo useradd -d /home/$HOST_USER -g admin -s /bin/bash \
 		-p $ENCRYPTED_PASSWD $HOST_USER
    fi
    sudo mkdir -p $DOCUMENT_ROOT
    sudo chown -R $HOST_USER:admin /home/$HOST_USER
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
    echo "=== install wordpress in $DOCUMENT_ROOT/$DOMAIN"

    # Create new Document Root
    if [ -d "$DOCUMENT_ROOT/$DOMAIN" ]; then
        sudo rm -rf $DOCUMENT_ROOT/$DOMAIN
    fi
    sudo mkdir -p $DOCUMENT_ROOT/$DOMAIN
    sudo chown $HOST_USER:admin $DOCUMENT_ROOT/$DOMAIN

    # Download the WordPress core files and configure wp-config.php
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
	wp core download --locale=$WP_LOCALE; \
	wp config create --dbname=$DB_NAME --dbuser=$DB_USER \
		--dbpass=$DB_PASSWD --skip-check"
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
    echo "=== create database $DB_NAME"
    # Create MySQL user if does not exist
    DB_USER_EXIST="$(mysql -u $MYSQL_USER -p$MYSQL_PASSWD -sse "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$DB_USER')")"

    if [ "$DB_USER_EXIST" != 1 ]; then
        mysql -u $MYSQL_USER -p$MYSQL_PASSWD -sse "CREATE USER $DB_USER@localhost IDENTIFIED BY \"$DB_PASSWD\";"
        mysql -u $MYSQL_USER -p$MYSQL_PASSWD -sse "GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@localhost;"
        mysql -u $MYSQL_USER -p$MYSQL_PASSWD -sse "FLUSH PRIVILEGES;"
    fi

    # Create database
    DB_NAME_EXIST="$(mysql -u $MYSQL_USER -p$MYSQL_PASSWD -sse "SELECT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$DB_NAME')")"

    if [ "$DB_NAME_EXIST" = "1" ]; then
        mysql -u $MYSQL_USER -p$MYSQL_PASSWD -sse "DROP database $DB_NAME;"
    fi 
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
        wp db create --dbuser=$DB_USER --dbpass=$DB_PASSWD"
}

###################################################################
# install_wp
#
# Input: none
# Description: this function install Wordpress in the new database.
# Return: none
###################################################################
install_wp() {
    echo "=== install wordpress"
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
	wp core install --url=\"$DOMAIN\" \
	--title=\"$WP_NAME\" --admin_user=\"$WP_USER\" \
	--admin_password=\"$WP_PASSWD\" --admin_email=\"$WP_USER_EMAIL\""
}

###################################################################
# configure_wp_settings
#
# Input: none
# Description: this function configure Wordpress Settings menu pages.
# Return: none
###################################################################
configure_wp_settings() {
    echo "====== configure wordpress settings"

    # Modify Settings->General

    # Modify blog description
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
        wp option update blogdescription \"$WP_DESCRIPTION\""
    # Modify Settings->Reading
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
        wp option update posts_per_page 6"
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
        wp option update posts_per_rss 7"

    # Modify Settings->Discussions
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
       wp option update thread_comments 0"
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
       wp option update moderation_notify 0"
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
       wp option update comment_whitelist 0"
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
       wp option update show_avatars 0"

    # Modify Settings->Permalink
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
       wp rewrite structure '/%postname%.html' --hard"
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
       wp rewrite flush --hard"
}

###################################################################
# configure_wp_plugins
#
# Input: none
# Description: this function install and configure Wordpress plugins.
# Return: none
###################################################################
configure_wp_plugins() {
    echo "====== configure wordpress plugins"

    # Delete akismet and hello dolly plugins
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
       wp plugin delete akismet"
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
       wp plugin delete hello"

    # Install plugins
    export IFS=","
    for plugin in $WP_PLUGINS; do
        sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
            wp plugin install $plugin --activate"
    done
}

# configure_wp
#
# Input: none
# Description: this function configure Wordpress.
# Return: none
###################################################################
configure_wp() {
    echo "=== configure wordpress"

    # Modify Settings configuration
    configure_wp_settings

    # Install and configure Wordpress plugins
    configure_wp_plugins
}

###################################################################
# configure_nginx
#
# Input: none
# Description: this function configure nginx adding the new website.
# Return: none
###################################################################
configure_nginx() {
    echo "====== configure nginx"
    # Configure NGINX
    sed "s:DOCUMENT_ROOT:$DOCUMENT_ROOT:g" nginx/site > tmp/site
    sed -i "s:DOMAIN:$DOMAIN:g" tmp/site
    sudo cp tmp/site /etc/nginx/sites-available/$DOMAIN
    sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN
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
    echo "================================================================="
    echo "Awesome WordPress Installer!!"
    echo "================================================================="
    mkdir -p tmp
    create_account
    download_wp
    create_db
    install_wp
    configure_wp
    configure_nginx
    rm -rf tmp
    echo "================================================================="
    echo "Installation is complete."
    echo "================================================================="
}

###################################################################
# Main block
###################################################################
main
