#WEBMASTER_USER=webmaster
#WEBMASTER_PASSWORD=webmaster

# The default locale used by our VPS
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
#    sudo useradd -d /home/webmaster -g admin -s /bin/bash -p $(openssl passwd -1 $WEBMASTER_PASSWORD) $WEBMASTER_USER
#    sudo mkdir -p /home/webmaster/.ssh
#    sudo mkdir -p /home/webmaster/www
#    sudo mv /root/.ssh/authorized_keys /home/webmaster/.ssh/
#    sudo chown -R webmaster:admin /home/webmaster
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
    echo "mysql-server-5.5 mysql-server/root_password password root" | sudo debconf-set-selections
    echo "mysql-server-5.5 mysql-server/root_password_again password root" | sudo debconf-set-selections
    sudo apt-get -y install mysql-client mysql-server
}

###################################################################
# php_go
#
# Input: none
# Description: install PHP packages. PHP is a prerequisites for
#              Wordpress.
# Return: none
###################################################################
php_go() {
    sudo apt-get -y install php5-fpm php5-cli php5-gd php5-mysql
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
#    export LANGUAGE=en_US.UTF-8
#    export LANG=en_US.UTF-8
#    export LC_ALL=en_US.UTF-8
    sudo locale-gen en_US.UTF-8
    sudo dpkg-reconfigure locales
    sudo apt-get -y install vsftpd
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
# main
#
# Input: none
# Description: the main procedure
# Return: none
###################################################################
main() {
    check_lock
    update_go
    tools_go
    mysql_go
    php_go
    nginx_go
    create_lock
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
# Main block
###################################################################
main
