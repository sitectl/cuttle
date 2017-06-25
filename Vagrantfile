# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

# INFRA_PLAYBOOK = ENV['INFRA_PLAYBOOK'] || abort("Please specify INFRA_PLAYBOOK env variable")

ANSIBLE_ARGS = ENV['ANSIBLE_ARGS'] ? ENV['ANSIBLE_ARGS'].split() : []

if File.file?('.vagrant/vagrant.yml')
  SETTINGS_FILE = ENV['SETTINGS_FILE'] || '.vagrant/vagrant.yml'
else
  SETTINGS_FILE = ENV['SETTINGS_FILE'] || 'vagrant.yml'
end

SETTINGS = YAML.load_file SETTINGS_FILE

BOX_URL = SETTINGS['default']['box_url'] || 'http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-14.04_chef-provisionerless.box'
BOX_NAME = SETTINGS['default']['box_name'] || 'bento/ubuntu-14.04'


# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.

  # default is a small vm
  config.vm.box = BOX_NAME
  config.vm.box_url = BOX_URL
  config.vm.provider "virtualbox" do |v|
    v.memory = SETTINGS['default']['memory']
    v.cpus = SETTINGS['default']['cpus']
    v.gui = SETTINGS['default']['gui']
  end
  config.ssh.insert_key = false
  config.ssh.forward_agent = true

  SETTINGS['vms'].each do |name,vm|
    config.vm.define name do |c|
      c.vm.hostname = name
      if vm['ip_address'].is_a? String
        ip_addresses = [vm['ip_address']]
      else
        ip_addresses = vm['ip_address']
      end
      ip_addresses.each do |ip|
        c.vm.network :private_network, ip: ip
      end
      if vm.has_key?('memory') || vm.has_key?('cpus')
        c.vm.provider "virtualbox" do |v|
          v.memory = vm['memory'] if vm.has_key?('memory')
          v.cpus = vm['cpus'] if vm.has_key?('cpus')
          if vm.has_key?('gui')
            v.gui = vm['gui']
          end
        end
      end

      # allow vagrant provision to run
      config.vm.provision "fix-no-tty", type: "shell" do |s|
        s.privileged = false
        s.inline = "sudo sed -i '/tty/!s/mesg n/tty -s \\&\\& mesg n/' /root/.profile"
      end
      # performance booster for VMs running on SSDs
      c.vm.provision "shell", inline: "echo noop > /sys/block/sda/queue/scheduler"
      # ensure python is installed please
      c.vm.provision "shell", inline: "apt-get -yqq update && apt-get -yqq install python-dev"
    end
  end

  if SETTINGS.has_key?('ansible')
    config.vm.provision "ansible" do |ansible|
      ansible.playbook = 'site.yml'
      ansible.extra_vars = 'envs/example/defaults.yml'
      ansible.verbose = 'vvvv' if ENV['DEBUG']
      ansible.limit = 'all'
      ansible.raw_arguments = ANSIBLE_ARGS
      ansible.sudo = true
      ansible.groups = SETTINGS['ansible']['groups']
    end
  end

end
