require 'spec_helper'

describe package('openjdk-7-jre') do
  it { should be_installed.by('apt') }	#KIB001
end

describe file('/opt/kibana') do
  it { should be_mode 775 }	#KIB010
  it { should be_directory }	#KIB011
  it { should be_owned_by 'root' }	#KIB012
  it { should be_grouped_into 'root' }	#KIB013
end

describe file('/opt/kibana/config/kibana.yml') do
  it { should be_file }	#KIB014
end

describe file('/etc/init.d/kibana') do
  it { should be_file }	#KIB015
end

describe port(5601) do
  it { should be_listening }	#KIB009
end

describe service('kibana') do
  it { should be_enabled }
end
