require 'spec_helper'

describe user('grafana') do
  it { should exist }	#GFN001
  it { should belong_to_group 'adm' }	#GFN002
  it { should have_home_directory '/usr/share/grafana' }	#GFN003
  it { should have_login_shell '/bin/false' }	#GFN004
end

describe file('/var/log/grafana') do
  it { should be_owned_by 'grafana' }	#GFN005
  it { should be_grouped_into 'adm' }	#GFN006
  it { should be_directory }	#GFN007
end

describe file('/usr/share/grafana/packages') do
  it { should be_owned_by 'grafana' }	#GFN008
  it { should be_directory }	#GFN009
end

describe file('/etc/init.d/grafana-server') do
  it { should be_mode 755 }	#GFN010
  it { should be_file }	#GFN011
end

describe file('/etc/grafana/grafana.ini') do
  it { should be_file }	#GFN012
  its(:content) { should_not contain /(password = \w{0,15})$/ }	#GFN013
end

{% for item in grafana.firewall %}
describe port('{{ item.port }}') do
  it { should be_listening }	#GFN014
end
{% endfor %}

describe service('grafana-server') do
  it { should be_enabled }
end
