# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # Configuración de la caja base
  config.vm.box = "ubuntu/jammy64"

  # Configuración de red y hostname
  config.vm.hostname = "ubuntu-devops"

  # Forwarding de puertos
  config.vm.network "forwarded_port", guest: 8080, host: 8080

  # Sincronización de carpetas
  config.vm.synced_folder ".", "/Puppet"

  # Recursos de la VM
  config.vm.provider "virtualbox" do |vb|
    vb.name = "ubuntu-devops"
    vb.memory = 2048
    vb.cpus = 2
  end

  # Provisioning usando un script externo
  config.vm.provision "shell", path: "provision.sh"
end