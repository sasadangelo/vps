#!/bin/bash -e
SCRIPT_DIR=$( cd $(dirname $0) ; pwd -P )
MYSQL_USER=root
MYSQL_PASSWD=root
BACKUP_FILE=""
BACKUP_FILENAME=""
CONFIG_WP="$SCRIPT_DIR/configure_wp.sh"
TMP="$SCRIPT_DIR/tmp"

source $SCRIPT_DIR/configure.sh
source $SCRIPT_DIR/configure_wp.sh

ENCRYPTED_PASSWD=$(openssl passwd -1 $HOST_PASSWD)

###################################################################
# delete_account
#
# Input: none
# Description: this function delete the system account.
# Return: none
###################################################################
delete_account() {
    echo "==== delete $HOST_USER account"
    if [ "$(id -u $HOST_USER > /dev/null 2>&1; echo $?)" != "0" ]; then
        sudo userdel $HOST_USER
    fi
    sudo rm -rf /home/$HOST_USER
}

###################################################################
# delete_db
#
# Input: none
# Description: this function delete the database.
# Return: none
###################################################################
delete_db() {
    echo "==== drop database $DB_NAME"

    DB_NAME_EXIST="$(mysql -u $MYSQL_USER -p$MYSQL_PASSWD -sse "SELECT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$DB_NAME')")"
    if [ "$DB_NAME_EXIST" = "1" ]; then
        mysql -u $MYSQL_USER -p$MYSQL_PASSWD -sse "DROP database $DB_NAME;"
    fi

    # Drop MySQL user if it exists
    DB_USER_EXIST="$(mysql -u $MYSQL_USER -p$MYSQL_PASSWD -sse "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$DB_USER')")"

    if [ "$DB_USER_EXIST" != 1 ]; then
        mysql -u $MYSQL_USER -p$MYSQL_PASSWD -sse "DROP USER $DB_USER@localhost;"
    fi
}

###################################################################
# undeploy_wp
#
# Input: none
# Description: this function remove the Wordpress instance.
# Return: none
###################################################################
undeploy_wp() {
    echo "==== remove wordpress"
    sudo rm -rf $DOCUMENT_ROOT
}

###################################################################
# unconfigure_nginx
#
# Input: none
# Description: this function configure unnginx removing a website.
# Return: none
###################################################################
unconfigure_nginx() {
    echo "====== unconfigure nginx"
    # Configure NGINX
    sudo rm -f /etc/nginx/sites-enabled/$DOMAIN
    sudo rm -f /etc/nginx/sites-available/$DOMAIN
    sudo service nginx restart
}

###################################################################
# uninstall_wp
#
# Input: none
# Description: this function uninstall a wordpress instance
# Return: none
###################################################################
uninstall_wp() {
    echo "====== Uninstall wordpress"
    unconfigure_nginx
    delete_db
    undeploy_wp
    delete_account
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
    echo "./wpuninstall.sh --help"
    echo ""
    echo "OPTIONS:"
    echo "-h, --help  Get this usage text"
    exit $1
}

###################################################################
# main
#
# Input: none
# Description: the main procedure
# Return: none
###################################################################
echo "================================================================="
echo "Awesome WordPress Uninstaller!!"
echo "================================================================="
uninstall_wp
echo "================================================================="
echo "Uninstall is complete."
echo "================================================================="
