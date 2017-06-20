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

describe package('apache2') do
  it { should be_installed }
end

describe service('apache2') do
  it { should be_enabled }
end

describe file('/etc/apache2/sites-available/file_mirror.conf') do
  it { should be_file }
end

describe file('/etc/apache2/sites-enabled/file_mirror.conf') do
  it { should be_symlink }
end

describe port('{{ file_mirror.apache.port }}') do
  it { should be_listening }
end

describe iptables do
  it { should have_rule('-p tcp -m tcp --dport {{ file_mirror.apache.port }} -j ACCEPT') }
end
