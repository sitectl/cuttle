# {{ ansible_managed }}

require 'spec_helper'

describe user('logstash') do
  it { should exist }	#LST001
  it { should belong_to_group 'logstash' }	#LST002
  it { should have_home_directory '/var/lib/logstash' }	#LST003
  it { should have_login_shell '/sbin/nologin' }	#LST004
end

describe file('/opt/logstash/') do
  it { should be_mode 775 }	#LST005
  it { should be_owned_by 'logstash' }	#LST006
  it { should be_grouped_into 'logstash' }	#LST007
  it { should be_directory }	#LST008
end

describe file('/var/log/logstash') do
  it { should be_mode 750 }	#LST009
  it { should be_owned_by 'logstash' }	#LST010
  it { should be_grouped_into 'logstash' }	#LST011
  it { should be_directory }	#LST012
end

describe file('/var/log/logstash/logstash.log') do
  it { should be_mode 644 }	#LST013
  it { should be_owned_by 'logstash' }	#LST014
  it { should be_grouped_into 'logstash' }	#LST015
  it { should be_file } #LST016
end

describe file('/var/log/logstash/logstash.err') do
  it { should be_mode 644 }	#LST017
  it { should be_file }	#LST018
end

describe file('/var/log/logstash/logstash.stdout') do
  it { should be_mode 644}	#LST019
  it { should be_file }	#LST020
end

describe file('/etc/default/logstash') do
  it { should be_file }	#LST021
end

describe file('/etc/logstash/conf.d/pipeline.conf') do
  it { should be_file } #LST022
end

describe file('/etc/logstash/patterns') do
  it { should be_mode 755 }	#LST023
  it { should be_directory }	#LST024
end

{% for pattern in logstash.patterns %}
describe file('/etc/logstash/patterns/{{ pattern }}' ) do
  it { should be_exist }	#LST025
end
{% endfor %}

describe file('/etc/ssl/private/logstash.key') do
  it { should be_mode 640 }	#LST026
  it { should be_owned_by 'root' }	#LST027
  it { should be_grouped_into 'ssl-key' }	#LST028
  it { should be_file }	#LST029
end

describe file('/etc/ssl/certs/logstash.crt') do
  it { should be_file }	#LST030
end

describe package('logstash') do
  it { should be_installed }
end

describe service('logstash') do
  it { should be_enabled }
end

describe file('/etc/logrotate.d/logstash') do
  it { should be_mode 644 }	#LST032
  it { should be_file }	#LST033
end

{% for rule in logstash.firewall %}
describe port("{{ rule.port }}") do
  it { should be_listening }
end
{% endfor %}
