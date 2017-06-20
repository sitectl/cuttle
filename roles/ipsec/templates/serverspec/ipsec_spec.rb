require 'spec_helper'

describe package({{ ipsec.implementation.package }}) do
  it { should be_installed.by('apt') }	#IPS001
end

describe 'Linux kernel parameters' do
  items = ['all','default']
  context linux_kernel_parameter('net.ipv4.ip_forward') do
    its(:value) { should eq 1 }	#IPS002
  end
  items.each do |item|
    context linux_kernel_parameter("net.ipv4.conf.#{ item }.accept_redirects") do
      its(:value) { should eq 0 }	#IPS003
    end
    context linux_kernel_parameter("net.ipv4.conf.#{ item }.send_redirects") do
      its(:value) { should eq 0 }	#IPS004
    end
  end
end

describe file('/etc/ipsec.conf') do
  it { should be_mode 644 }	#IPS005
  it { should be_owned_by 'root' }	#IPS006
  it { should be_grouped_into 'root' }	#IPS007
  it { should be_file }	#IPS008
end

describe file('/etc/ipsec.d/connections.conf') do
  it { should be_mode 644 }	#IPS009
  it { should be_owned_by 'root' }	#IPS010
  it { should be_grouped_into 'root' }	#IPS011
  it { should be_file }	#IPS012
end

describe file('/etc/ipsec.secrets') do
  it { should be_mode 600 }	#IPS013
  it { should be_owned_by 'root' }	#IPS014
  it { should be_grouped_into 'root' }	#IPS015
  it { should be_file }	#IPS016
  its(:content) { should_not contain /(PSK "\w{0,15}")$/ }	#IPS017
end

describe port(500) do
  it { should be_listening.with('udp') }	#IPS018
end

describe port(4500) do
  it { should be_listening.with('udp') }	#IPS019
end

describe package({{ ipsec.implementation.package }}) do
  it { should be_installed }
end

describe service({{ ipsec.implementation.package }}) do
  it { should be_enabled }
end

{% if ipsec.nat_rules %}
describe file('/etc/ufw/before.rules') do
  it { should be_mode 640 }	#IPS021
  it { should be_owned_by 'root' }	#IPS022
  it { should be_grouped_into 'root' }	#IPS023
  it { should be_file }	#IPS024
  its(:content) { should contain /^({{ ipsec.nat_rules }})/ }	#IPS025
end
{% endif %}
