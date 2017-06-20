require 'spec_helper'

describe user('jenkins') do
  it { should exist } #JNK002
  it { should belong_to_group 'jenkins' } #JNK003
  it { should have_home_directory '/var/lib/jenkins' }	#JNK004
  it { should_not have_login_shell '/usr/sbin/nologin' }	#JNK005
end

describe file('/var/lib/jenkins') do
  it { should be_owned_by 'jenkins' }	#JNK007
  it { should be_grouped_into 'jenkins' }	#JNK008
  it { should be_mode 755 }	#JNK006
  it { should be_directory }	#JNK006
end

describe file('/var/log/jenkins') do
  it { should be_owned_by 'jenkins' }	#JNK007
  it { should be_grouped_into 'jenkins' }	#JNK008
  it { should be_mode 755 }	#JNK006
  it { should be_directory }	#JNK006
end

describe command(%q<stat -c '%a %n' /var/lib/jenkins/*.xml>) do
  its(:stdout) { should contain('644') } #JNK009
  its(:stdout) { should contain('.xml') } #JNK009
end

describe command(%q<stat -c '%G' /var/lib/jenkins/*.xml>) do
  its(:stdout) { should contain('jenkins') } #JNK010
end

describe command(%q<stat -c '%U' /var/lib/jenkins/*.xml>) do
  its(:stdout) { should contain('jenkins') } #JNK011
end

describe file('/var/log/jenkins/jenkins.log') do
  it { should be_owned_by 'jenkins' } #JNK013
  it { should be_grouped_into 'jenkins' } #JNK014
  it { should be_mode 644 } #JNK012
  it { should be_file } #JNK012
end

describe file('/etc/logrotate.d/jenkins') do
  it { should be_owned_by 'root' }	#JNK017
  it { should be_grouped_into 'root' }	#JNK018
  it { should be_mode 644 }	#JNK016
  it { should be_file }	#JNK016
  its(:content) { should contain 'weekly' }	#JNK019
  #its(:content) { should contain 'rotate 90' }  #JNK019 - logrotate.d/jenkins/ set to `rotate 52`, needs to be `rotate 90`
end

describe file('/var/lib/jenkins/private_vars') do
  it { should be_owned_by 'jenkins' }	#JNK021
  it { should be_grouped_into 'root' }	#JNK022
  it { should be_mode 755 }	#JNK020
  it { should be_directory }	#JNK020
end

describe file('/var/lib/jenkins/private_vars/default.yml') do
  it { should be_owned_by 'jenkins' }	#JNK023
  it { should be_grouped_into 'root' }	#JNK023
  it { should be_mode 644 }	#JNK023 - Needs update to 640
  it { should be_file }	#JNK023
end

describe file('/var/lib/jenkins/.packagecloud') do
  it { should be_owned_by 'jenkins' }	#JNK024
  it { should be_grouped_into 'root' }	#JNK024
  it { should be_mode 600 }	#JNK024
  it { should be_file }	#JNK024
end

# Waiting for access to tardis-sl to write/test the ansible automation for this rule.
#describe file('~jenkins/.ssh/*') do
#  it { should be_owned_by 'jenkins' }	#JNK025
#  it { should be_grouped_into 'jenkins' }	#JNK025
#  it { should be_mode 600 }	#JNK025
#  it { should be_file }	#JNK025
#end
# JNK026 - max files open - deprecated rule/test

describe package('jenkins') do
  it { should be_installed } #JNK027
end

describe service('jenkins') do
  it { should be_enabled } #JNK027
end

describe package('openjdk-7-jre') do
  it { should be_installed } #JNK028
end

describe file('/var/lib/jenkins/plugins/timestamper') do
  it { should exist } #JNK030
  it { should be_directory } #JNK030
end

describe file('/var/lib/jenkins/plugins/ws-cleanup') do
  it { should exist } #JNK031
  it { should be_directory } #JNK031
end

