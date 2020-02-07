# The default locale used by our VPS
SCRIPT_DIR="/vagrant"

BACKUP_FILE=""
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

###################################################################
# nginx_go
#
# Input: none
# Description: Nginx will be the HTTP server used for our VPS
#              solution. This function will install it.
# Return: none
###################################################################
nginx_go() {
    sudo apt-get -y install nginx
}

###################################################################
# mysql_go
#
# Input: none
# Description: this function installs the MySQL packages.
# Retur: none
###################################################################
mysql_go() {
    # MySQL during installation ask the user for root password. A
    # prompt in an automatic procedure is not acceptable, to avoid
    # it the following two echo commands are used to set the root
    # password equal to "root", this will be changed later by the
    # administrator.
    echo "mysql-server-5.7 mysql-server/root_password password root" | sudo debconf-set-selections
    echo "mysql-server-5.7 mysql-server/root_password_again password root" | sudo debconf-set-selections
    sudo apt-get -y install mysql-client mysql-server
}

###################################################################
# php_go
#
# Input: none
# Description: install PHP packages. PHP is a prerequisites for
#              Wordpress. php7.0-xml is used by WP Google Map 
#              plugin.
# Return: none
###################################################################
php_go() {
    sudo apt-get -y install php7.0 php7.0-gd php7.0-mysql php7.0-curl php7.0-xml 
}

###################################################################
# tools_go
#
# Input: none
# Description: VPS and applications requires some basic tool and
#     configuration to run properly. This function will be
#     responsible to install and configure all the not main packages
#     of our environment. So far the script has been tested only on
#     Ubuntu 16 and Wordpress and here the packages and configuration
#     required:
#         vsftpd, necessary to update wordpress, its plugins and themes
#         locales, Ubuntu 16 does not configure locales so it is required
#                  this step to have some commands (i.e. apt-get) work
#                  properly.
###################################################################
tools_go() {
    sudo locale-gen en_US.UTF-8
    sudo dpkg-reconfigure --frontend noninteractive locales
    sudo apt-get -y install vsftpd sendmail unzip
}

###################################################################
# check_lock
#
# Input: none
# Description: provisioning must be done once when the virtual
#    machine is created. To enforce this behaviour and avoid the
#    administrtor run the script multiple time we will create a
#    lock file once the procedure complete. In this way, the next
#    time it is executed an error message will appear. This
#    function checks if the lock exists and, in case, show the
#    error message.
###################################################################
check_lock() {
    if [[ -e /var/lock/vagrant-provision ]]; then
        cat 1>&2 << EOF
###################################################################
# To re-run full provisioning, delete /var/lock/vagrant-provision
# and run:
#
#    $ vagrant provision
#
# From the host machine
###################################################################
EOF
        exit 0
    fi
}

###################################################################
# create_lock
#
# Input: none
# Description: provisioning must be done once when the virtual
#     machine is created. To enforce this behaviour and avoid the
#     administrtor run the script multiple time we will create a
#     lock file once the procedure complete. In this way, the next
#     time it is executed an error message will appear.
###################################################################
create_lock() {
    touch /var/lock/vagrant-provision
}

###################################################################
# wpcli_go
#
# Input: none
# Description: this function install wp-cli.
###################################################################
wpcli_go() {
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
}

###################################################################
# update_go
#
# Input: none
# Description: this function upgrade packages of VPS
# Return: none
###################################################################
update_go() {
    sudo apt-get update
    sudo apt-get -y upgrade
}

###################################################################
# wpinstall_go
#
# Input: none
# Description: this function install Wordpress for San Patrignano Website
# Return: none
###################################################################
wpinstall_go() {
    if [ "$BACKUP_FILE" != "" ]
    then
        $SCRIPT_DIR/wp-install/wprestore.sh "-r $SCRIPT_DIR/$BACKUP_FILE"
    else
        $SCRIPT_DIR/wp-install/wpinstall.sh
    fi
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
        CPARM="$1"; export CPARM
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
        if [ ! -e $SCRIPT_DIR/$BACKUP_FILE ]
        then
            echo "$(pwd)"
            echo "ERROR: file $BACKUP_FILE does not exist in $SCRIPT_DIR folder."
            exit 1
        fi
        if [ ! -f $SCRIPT_DIR/$BACKUP_FILE ]
        then
            echo "ERROR: file $BACKUP_FILE must be a valid file."
            exit 1
        fi
        if [ ${BACKUP_FILE: -4} != ".zip" ]
        then
            echo "ERROR: file $BACKUP_FILE is not a zip file."
            exit 1
        fi
    fi
}

###################################################################
# main
#
# Input: none
# Description: the main procedure
# Return: none
###################################################################
main() {
    parse_parms "$@"
    check_lock
    update_go
    tools_go
    mysql_go
    php_go
    nginx_go
    wpcli_go
    wpinstall_go
    create_lock
}

###################################################################
# Main block
###################################################################
main "$@"
