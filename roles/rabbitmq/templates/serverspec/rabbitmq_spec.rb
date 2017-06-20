# {{ ansible_managed }}

require 'spec_helper'

describe user('rabbitmq') do
  it { should exist }	#RMQ001
  it { should belong_to_group 'rabbitmq' }	#RMQ002
  it { should have_home_directory '/var/lib/rabbitmq' }	#RMQ003
  it { should have_login_shell '/bin/false' }	#RMQ004
end

describe file('/etc/rabbitmq/rabbitmq.config') do
  it { should be_mode 600 }	#RMQ005
  it { should be_owned_by 'rabbitmq' }	#RMQ006
  it { should be_grouped_into 'rabbitmq' }	#RMQ007
  it { should be_file }	#RMQ008
  its(:content) { should_not contain /({default_user, <<"guest">>})/ }	#RMQ009
  its(:content) { should_not contain /({default_pass, <<"\w{0,15}">>})$/ }	#RMQ010
end

describe package('rabbitmq-server') do
  it { should be_installed }
end

describe service('rabbitmq-server') do
  it { should be_enabled }
end

{% if '{{ rabbit.ssl }}' %}
describe file('/etc/rabbitmq/ssl') do
  it { should be_mode 755 }	#RMQ011
  it { should be_owned_by 'rabbitmq' }	#RMQ012
  it { should be_grouped_into 'rabbitmq' }	#RMQ013
  it { should be_directory }	#RMQ014
end
describe file('/etc/rabbitmq/ssl/cacert.pem') do
  it { should be_mode 600 }	#RMQ015
  it { should be_owned_by 'rabbitmq' }	#RMQ016
  it { should be_grouped_into 'rabbitmq' }	#RMQ017
  it { should be_file }	#RMQ018
end
describe file('/etc/rabbitmq/ssl/cert.pem') do
  it { should be_mode 600 }	#RMQ019
  it { should be_owned_by 'rabbitmq' }	#RMQ020
  it { should be_grouped_into 'rabbitmq' }	#RMQ021
  it { should be_file }	#RMQ022
end
describe file('/etc/rabbitmq/ssl/key.pem') do
  it { should be_mode 600 }	#RMQ023
  it { should be_owned_by 'rabbitmq' }	#RMQ024
  it { should be_grouped_into 'rabbitmq' }	#RMQ025
  it { should be_file }	#RMQ026
end
{% endif %}
