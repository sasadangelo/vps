# Wordpress for Virtual Private Server (VPS)

Do you need a Wordpress website to run on a Virtual Private Server (VPS) or in your locale machine? Do you have a Wordpress website and you need a local copy for test purpose? Wordpress for VPS help you to create easily a running wordpress website on your local machine or remote VPS.

The tool use Vagrant as abstraction layer on your Virtual Server provider to manage its lifecycle. The following Wordpress prerequisites are installed on the Virtual Machine:

- Ubuntu Xenial 16.04
- Nginx
- MySQL
- PHP 7

## Prerequisites

Prerequisites for this project is [Vagrant](https://www.vagrantup.com/) that can be used to deploy your Wordpress stack in local on a remote VPS. For a local installation you need [Virtual Box](https://www.virtualbox.org/) installed on your local machine. The tool use an Ubuntu Xenial 16.04 as virtual machine.

## Wordpress on Local Virtual Machine

Configure the files ```wp-install/configure.sh``` and ```wp-install/configure_wp.sh``` to customize your Wordpress installation. You can configure:

- the linux account that owns the wordpress files
- the website domain
- the database name
- the database credentials
- the Wordpress name and description
- the Wordpress credentials
- the Wordpress theme
- the Wordpress plugins

Run the following commands.

```
1. cd  <work_dir>
2. git clone https://github.com/sasadangelo/vps
3. cd vps
4. vagrant up
5. sudo vi /etc/hosts
6. Add this line to your /etc/hosts file:
   192.168.100.2   www.mywebiste.com
```

To run your website open a browser and type the following address in the address bar:

```
www.mywebiste.com
```

The administration panel can be accessed from the following URL:

```
www.mywebiste.co/wp-admin
```

use the following credentials that you can change once accessed.

```
Nome utente o indirizzo email: user
Password: password
```
