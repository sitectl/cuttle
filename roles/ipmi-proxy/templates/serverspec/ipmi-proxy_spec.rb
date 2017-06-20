require 'spec_helper'

describe 'Linux kernel parameters' do
  context linux_kernel_parameter('net.ipv4.ip_forward') do
    its(:value) { should eq 1 }	#IPP001
  end
end

describe file('/etc/bluebox') do
  it { should be_mode 755 }	#IPP002
  it { should be_directory }	#IPP003
end

describe file('/var/lib/ipmi-proxy') do
  it { should be_mode 755 }	#IPP004
  it { should be_directory }	#IPP005
end

describe file('/etc/bluebox/ipmi-proxy.conf') do
  it { should be_mode 644 }	#IPP006
  it { should be_owned_by 'root' }	#IPP007
  it { should be_grouped_into 'root' }	#IPP008
  it { should be_file }	#IPP009
end

describe file('/usr/local/lib/ipmi-proxy') do
  it { should be_mode 755 }	#IPP010
  it { should be_directory }	#IPP011
end

describe file('/etc/sudoers.d/www-data') do
  it { should be_mode 440 }	#IPP012
  it { should be_owned_by 'root' }	#IPP013
  it { should be_grouped_into 'root' }	#IPP014
  it { should be_file }	#IPP015
end

describe file('/etc/apache2/sites-available/ipmi-proxy.conf') do
  it { should be_mode 644 }	#IPP016
  it { should be_owned_by 'root' }	#IPP017
  it { should be_grouped_into 'root' }	#IPP018
  it { should be_file }	#IPP019
  its(:content) { should contain('<VirtualHost').before(':{{ ipmi_proxy.apache.port }}>') }	#IPP020
end

describe file('/etc/apache2/sites-enabled/ipmi-proxy.conf') do
  it { should be_file }	#IPP021
end

describe command('apache2ctl -M') do
  its(:stdout) { should contain ('ssl_module') }	#IPP022
  its(:stdout) { should contain ('cgi_module') }	#IPP023
  its(:stdout) { should contain ('cache_socache_module') }	#IPP024
end

describe package('apache2') do
  it { should be_installed }
end

describe service('apache2') do
  it { should be_enabled }
end
