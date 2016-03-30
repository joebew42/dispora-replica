# -*- mode: ruby -*-
# vi: set ft=ruby :

def pod_count
  ENV["pod_count"] && ENV["pod_count"].to_i || 2
end

Vagrant.configure("2") do |config|

  if Vagrant.has_plugin?('vagrant-puppet-install')
    config.puppet_install.puppet_version = '3.7.3'
  end

  # Ubuntu Server 14.04 LTS
  config.vm.box = "fgrehm/trusty64-lxc"
  config.vm.provision :shell, inline: "apt-get update -y --fix-missing"

  # Ubuntu Server 12.04 LTS
  # config.vm.box = "puppetlabs/ubuntu-12.04-64-puppet"
  # config.vm.provision :shell, inline: "apt-get update -y --fix-missing"

  # CentOS 7
  # *** Not yet supported! ***
  # See the issue: https://github.com/joebew42/diaspora-replica/issues/9
  # config.vm.box = "puppetlabs/centos-7.0-64-puppet"
  # config.vm.provision :shell, inline: "yum -y update"

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "puppet/manifests"
    puppet.module_path = "puppet/modules"
    puppet.manifest_file  = "site.pp"
    puppet.options = "--verbose"
  end

  (1..pod_count).each do |number|
    config.vm.define "pod#{number}" do |dev|
      dev.vm.hostname = "pod#{number}.diaspora.local"
      dev.vm.network :private_network, ip: "192.168.11.#{4+number*2}"
      dev.vm.synced_folder "src/", "/home/vagrant/diaspora_src/", create: true
      dev.vm.provider "virtualbox" do |vb|
        vb.memory = 2048
      end

      dev.vm.provision :hosts, :sync_hosts => true
    end
  end

  config.vm.define "development" do |dev|
    dev.vm.hostname = "development.diaspora.local"
    dev.vm.synced_folder "src/", "/home/vagrant/diaspora_src/", create: true
    dev.vm.network :private_network, ip: "192.168.11.2", lxc__bridge_name: "vlxcbr1"
  end

  config.vm.define "production" do |prod|
    prod.vm.hostname = "production.diaspora.local"
    prod.vm.network :private_network, ip: "192.168.11.4"
    prod.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
    end
  end

  if Vagrant.has_plugin?('vagrant-group')
    config.group.groups = {
      "testfarm" => (1..pod_count).map {|i| "pod#{i}"},
    }
  end
end
