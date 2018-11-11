# -*- mode: ruby -*-
# vi: set ft=ruby :

DEV_BOX_NAME = "gsengun/hashi-dev-box"
DEV_BOX_VERSION = "18.05.14"

ROOT_FOLDER = "/home/vagrant/go/src/github.com/play-with-docker/"

Vagrant.configure("2") do |config|
  config.vm.box = DEV_BOX_NAME
  config.vm.box_version = DEV_BOX_VERSION

  config.vm.network "private_network", ip: "192.168.34.10"

  config.vm.synced_folder ".", ROOT_FOLDER

  config.vm.provision "shell", inline: "echo 'cd #{ROOT_FOLDER}' >> ~/.bashrc && exit", privileged: false

  config.vm.provision "shell", inline: "#{ROOT_FOLDER}/deploy/scripts/setup-local.sh && exit", privileged: true
  config.vm.provision "shell", inline: "#{ROOT_FOLDER}/deploy/scripts/run-app-local.sh", privileged: false

  config.vm.provider "virtualbox" do |vb|
    # Customize the amount of memory on the VM:
    vb.memory = "4096"
    vb.cpus = "2"
  end  #
end
