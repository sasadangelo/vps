# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

backup_options=""

if !ENV['BACKUP_FILE'].nil?
    backup_file=ENV['BACKUP_FILE']
    backup_options = "-r #{backup_file}"
end

Vagrant.configure("2") do |config|
    config.vm.hostname = 'vps-wordpress'
    config.vm.box = "ubuntu/xenial64"
    config.vm.network "private_network", ip: "192.168.100.2"

    config.vm.network "forwarded_port", guest: 80, host: 8888
    config.vm.network "forwarded_port", guest: 3306, host: 8889
    config.vm.provision "shell", path: "provision.sh", args: "#{backup_options}"
end
