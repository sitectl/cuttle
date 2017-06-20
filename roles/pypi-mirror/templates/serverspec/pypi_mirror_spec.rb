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

describe virtualenv('{{ pypi_mirror.virtualenv }}') do
  it { should be_virtualenv }
  its(:pip_freeze) { should include('devpi') }
end

describe file("{{ pypi_mirror.mirror_location }}") do
  it { should be_directory }
  it { should be_owned_by 'mirror' }
end

describe service('pypi_mirror') do
  it { should be_enabled }
end

describe port({{ pypi_mirror.port }}) do
  it { should be_listening.on('{{ pypi_mirror.ip }}').with('tcp') }
end

describe package('apache2') do
  it { should be_installed }
end

describe service('apache2') do
  it { should be_enabled }
end

describe port({{ pypi_mirror.apache.port }}) do
  it { should be_listening }
end

describe file('/etc/apache2/sites-available/pypi_mirror.conf') do
  it { should be_file }
end

describe file('/etc/apache2/sites-enabled/pypi_mirror.conf') do
  it { should be_symlink }
end
