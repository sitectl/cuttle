require 'spec_helper'

describe user('redis') do
  it { should exist }	#RED001
  it { should belong_to_group 'adm' }	#RED002
  it { should have_home_directory '/usr/share/redis' }	#RED003
  it { should have_login_shell '/bin/false' }	#RED004
end

describe file('/var/log/redis') do
  it { should be_mode 775 }	#RED005
  it { should be_owned_by 'redis' }	#RED006
  it { should be_directory }	#RED007
end

describe file('/etc/init.d/redis-server') do
  it { should be_mode 755 }	#RED008
  it { should be_file }	#RED009
end

describe package('redis-server') do
  it { should be_installed.by('apt') }	#RED010
end

describe service('redis-server') do
  it { should be_enabled }
end
