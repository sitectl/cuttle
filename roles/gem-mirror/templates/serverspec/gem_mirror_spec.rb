# {{ ansible_managed }}

require 'spec_helper'

describe user('mirror') do
  it { should exist }
  it { should have_home_directory '/nonexistent' }
  it { should have_login_shell '/bin/false' }
end

['proxy_http', 'rewrite', 'headers'].each do |file|
  describe file("/etc/apache2/mods-available/#{file}.load") do
    it { should exist }
  end
  describe file("/etc/apache2/mods-enabled/#{file}.load") do
    it { should be_symlink }
  end
end

describe file('{{ gem_mirror.mirror_location }}') do
  it { should be_directory }
  it { should be_owned_by 'mirror' }
end

describe service('gem_mirror') do
  it { should be_enabled }
end

describe port('{{ gem_mirror.port }}') do
  it { should be_listening.on('{{ gem_mirror.host }}').with('tcp') }
end

describe port('{{ gem_mirror.apache.port }}') do
  it { should be_listening }
end

describe package('apache2') do
  it { should be_installed }
end

describe service('apache2') do
  it { should be_enabled }
end

describe file('{{ gem_mirror.config_location }}/config.ru') do
  it { should be_file }
end

describe file('/etc/apache2/sites-available/gem_mirror.conf') do
  it { should be_file }
end

describe file('/etc/apache2/sites-enabled/gem_mirror.conf') do
  it { should be_symlink }
end

describe iptables do
  it { should have_rule('-p tcp -m tcp --dport {{ gem_mirror.apache.port }} -j ACCEPT') }
end
