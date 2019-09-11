# Wordpress for Virtual Private Server (VPS)

Do you need a Wordpress website to run on a Virtual Private Server (VPS) or in your locale machine? Do you have a Wordpress website and you need a local copy for test purpose? Wordpress for VPS help you to create easily a running wordpress website on your local machine or remote VPS.

Prerequisites for this project is [Vagrant](https://www.vagrantup.com/) that can be used to deploy your Wordpress stack in local on a remote VPS. For a local installation you need [Virtual Box](https://www.virtualbox.org/) installed on your local machine.

Once all prerequisites are up and running run the following commands.

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
