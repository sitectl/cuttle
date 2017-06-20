# {{ ansible_managed }}

require 'spec_helper'

describe package('debmirror') do
  it { should be_installed }
end

describe package('apache2') do
  it { should be_installed }
end

describe service('apache2') do
  it { should be_enabled }
end

describe file('{{ apt_mirror.path }}/keys') do
  it { should be_directory }
end

describe file('/etc/apache2/sites-available/apt_mirror.conf') do
  it { should be_file }
end

describe file('/etc/apache2/sites-enabled/apt_mirror.conf') do
  it { should be_symlink }
end

describe port('{{ apt_mirror.apache.port }}') do
  it { should be_listening }
end

describe iptables do
  it { should have_rule('-p tcp -m tcp --dport {{ apt_mirror.apache.port }} -j ACCEPT') }
end
