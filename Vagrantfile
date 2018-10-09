# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure("2") do |config|
    config.vm.hostname = 'vps-wordpress'
    config.vm.box = "ubuntu/trusty64"
    config.vm.network "private_network", ip: "192.168.100.3"

    config.vm.network "forwarded_port", guest: 80, host: 8080
    config.vm.network "forwarded_port", guest: 3306, host: 8081
    config.vm.provision "shell", path: "provision.sh"
end
