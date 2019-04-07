#!/bin/bash -e
SCRIPT_DIR=$( cd $(dirname $0) ; pwd -P )
MYSQL_USER=root
MYSQL_PASSWD=root
BACKUP_FILE=""
BACKUP_FILENAME=""
CONFIG_WP="$SCRIPT_DIR/configure_wp.sh"
TMP="/tmp"

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
    echo "==== configure $HOST_USER account"
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
    echo "==== install wordpress in $DOCUMENT_ROOT/$DOMAIN"

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
    echo "==== create database $DB_NAME"
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
# deploy_wp
#
# Input: none
# Description: this function install Wordpress in the new database.
# Return: none
###################################################################
deploy_wp() {
    echo "==== install wordpress"
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
    echo "===== configure wordpress settings"

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

###################################################################
# configure_wp_aspect
#
# Input: none
# Description: this function configure Wordpress aspects like
#              themes, menu, etc.
# Return: none
###################################################################
configure_wp_aspect() {
    echo "====== configure wordpress aspect"

    # Install the Theme
    sudo su - $HOST_USER -c "cd $DOCUMENT_ROOT/$DOMAIN; \
        wp theme install $WP_THEME --activate"
}

###################################################################
# configure_wp_config
#
# Input: none
# Description: this function configure direct FTP and memory limit
#              to install plugins from WP dashboard.
# Return: none
###################################################################
configure_wp_config() {
    echo "====== Configure wp-config.php"
    if ! grep -q "define('FS_METHOD', 'direct');" $DOCUMENT_ROOT/$DOMAIN/wp-config.php;
    then
        sudo su - $HOST_USER -c "echo \"define('FS_METHOD', 'direct');\" >> $DOCUMENT_ROOT/$DOMAIN/wp-config.php"
    fi
    if ! grep -q "define('WP_MEMORY_LIMIT', '3000M');" $DOCUMENT_ROOT/$DOMAIN/wp-config.php;
    then
        sudo su - $HOST_USER -c "echo \"define('WP_MEMORY_LIMIT', '3000M');\" >> $DOCUMENT_ROOT/$DOMAIN/wp-config.php"
    fi
}

###################################################################
# configure_wp
#
# Input: none
# Description: this function configure Wordpress.
# Return: none
###################################################################
configure_wp() {
    echo "==== configure wordpress"

    # Modify Settings configuration
    configure_wp_settings

    # Install and configure Wordpress plugins
    configure_wp_plugins

    # Configure Wordpress aspect
    configure_wp_aspect

    # Configure Wordpress dashboard
    configure_wp_config
}

###################################################################
# import:_wp
#
# Input: none
# Description: this function import WordPress db and site images
# Return: none
###################################################################
restore_wp() {
    echo "===== Import wordpress database and files"
    mysql -u $MYSQL_USER -p$MYSQL_PASSWD $DB_NAME < $SCRIPT_DIR/$DB_NAME.sql

    # Import wordpress files
    cp -R $SCRIPT_DIR/wordpress/uploads $DOCUMENT_ROOT/$DOMAIN/wp-content

    # Change file permission on wp-content wordpress folder
    chown -R www-data:www-data $WP_CONTENT_FOLDER
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
    sed "s:DOCUMENT_ROOT:$DOCUMENT_ROOT:g" /vagrant/wp-install/nginx/site > /vagrant/tmp/site
    sed -i "s:DOMAIN:$DOMAIN:g" /vagrant/tmp/site
    sudo cp /vagrant/tmp/site /etc/nginx/sites-available/$DOMAIN
    sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN
    sudo service nginx restart
}

###################################################################
# install_wp
#
# Input: none
# Description: this function install a default wordpress
# Return: none
###################################################################
install_wp() {
    echo "================================================================="
    echo "Awesome WordPress Installer!!"
    echo "================================================================="
    mkdir -p /vagrant/tmp
    create_account
    download_wp
    create_db
    deploy_wp
    configure_wp
    configure_nginx
    rm -rf /vagrant/tmp
    echo "================================================================="
    echo "Installation is complete."
    echo "================================================================="
}

###################################################################
# load_config_wp
#
# Input Parameters:
#     none
#
# Description:
#     Load Wordpress configuration from project configure_wp.sh files
#     or from a backup file.
#
# Return:
#     None
###################################################################
load_config_wp() {
    source $CONFIG_WP
}

###################################################################
# usage
#
# Input Parameters:
#     none
#
# Description:
#     This function prints the usage.
#
# Return:
#     None
###################################################################
usage() {
    echo "Usage:"
    echo "./wpinstall.sh [--backup <BACKUP FILE>]"
    echo "./wpinstall.sh --help"
    echo ""
    echo "OPTIONS:"
    echo "-h, --help                  Get this usage text"
    echo "-r, --restore <BACKUP FILE>  BACKUP FILE is the backup file to restore."
}

###################################################################
# parse_parms
#
# Input Parameters:
#     none
#
# Description:
#     This function validates the input parameters.
#
# Return:
#     None
###################################################################
parse_parms() {
    local CPARM
    echo "====== parse parameters"

    while [ $# -gt 0 ]; do
        CPARM=$1; export CPARM
        shift
        case ${CPARM} in
            -h | --help)
                usage
            ;;
            -r | --restore)
                BACKUP_FILE=$1; shift
            ;;
            *)
                usage 1 "Invalid argument ${CPARM}"
            ;;
        esac
    done

    if [ "$BACKUP_FILE" != "" ]
    then
        if [ ! -e $BACKUP_FILE ]
        then
            echo "ERROR: file $BACKUP_FILE does not exist."
            exit 1
        fi
        if [ ! -f $BACKUP_FILE ]
        then
            echo "ERROR: file $BACKUP_FILE must be a valid file."
            exit 1
        fi
        if [ ${BACKUP_FILE: -4} != ".zip" ]
        then
            echo "ERROR: file $BACKUP_FILE is not a zip file."
            exit 1
        fi
        BACKUP_FILENAME=$(basename $BACKUP_FILE)
    fi
}

###################################################################
# extract_wp
#
# Input: none
# Description: extract the backup in /tmp/<backup file name>
# Return: none
###################################################################
extract_wp() {
    mkdir -p $TMP/$BACKUP_FILENAME
    unzip $BACKUP_FILE -d $TMP/$BACKUP_FILENAME
    CONFIG_WP=$TMP/$BACKUP_FILENAME/configure_wp.sh
}

###################################################################
# main
#
# Input: none
# Description: the main procedure
# Return: none
###################################################################
main() {
    parse_parms

    if [ "$BACKUP_FILE" != "" ]
    then
        extract_wp
        load_config_wp
        install_wp
        restore_wp
    else
        load_config_wp
        install_wp
    fi
}

###################################################################
# Main block
###################################################################
main
