# {{ ansible_managed }}

require 'spec_helper'

describe user('mysql') do
  it { should exist }	#PER001
  it { should belong_to_group 'mysql' }	#PER002
  it { should have_home_directory '/nonexistent' }	#PER003
  it { should have_login_shell '/bin/false' }	#PER004
end

describe file('/etc/mysql/conf.d') do
  it { should be_mode 755 }	#PER005
  it { should be_owned_by 'mysql' }	#PER006
  it { should be_grouped_into 'mysql' }	#PER007
  it { should be_directory }	#PER008
end

describe file('/etc/mysql/conf.d/bind-inaddr-any.cnf') do
  it { should be_mode 644 }	#PER009
  it { should be_owned_by 'mysql' }	#PER010
  it { should be_grouped_into 'mysql' }	#PER011
  it { should be_file }	#PER012
end

{% if '{{ percona.replication }}' %}
describe file('/etc/mysql/conf.d/replication.cnf') do
  it { should be_mode 644 }	#PER013
  it { should be_file }	#PER014
end
{% endif %}

describe file('/etc/mysql/conf.d/tuning.cnf') do
  it { should be_mode 644 }	#PER015
  it { should be_owned_by 'mysql' }	#PER016
  it { should be_grouped_into 'mysql' }	#PER017
  it { should be_file }	#PER018
end

describe file('/etc/mysql/conf.d/utf8.cnf') do
  it { should be_mode 644 }	#PER019
  it { should be_owned_by 'mysql' }	#PER020
  it { should be_grouped_into 'mysql' }	#PER021
  it { should be_file }	#PER022
end

describe package('percona-xtradb-cluster-galera-{{ percona.galera_version }}') do
  it { should be_installed }	#PER023
end

describe package('percona-xtradb-cluster-client-{{ percona.client_version }}') do
  it { should be_installed }	#PER024
end

describe package('percona-xtradb-cluster-server-{{ percona.server_version }}') do
  it { should be_installed }	#PER025
end

describe package('percona-xtrabackup') do
  it { should be_installed }	#PER026
end

describe package('python-mysqldb') do
  it { should be_installed }	#PER027
end

describe service('mysql') do
  it { should be_enabled }
end

describe file('/var/log/mysql.log') do
  it { should be_mode 640 }	#PER028
  it { should be_owned_by 'mysql' }	#PER029
  it { should be_grouped_into 'adm' }	#PER030
  it { should be_file }	#PER031
end

describe file('/var/log/mysql.err') do
  it { should be_mode 640 }	#PER032
  it { should be_owned_by 'mysql' }	#PER033
  it { should be_grouped_into 'adm' }	#PER034
  it { should be_file }	#PER035
end

describe file('/var/lib/mysql/mysql-error.log') do
  it { should be_mode 660 }	#PER036
  it { should be_owned_by 'mysql' }	#PER037
  it { should be_file }	#PER038
end

describe file('/var/lib/mysql') do
  it { should be_mode 700 }	#PER039
  it { should be_owned_by 'mysql' }	#PER040
  it { should be_grouped_into 'mysql' }	#PER041
  it { should be_directory }	#PER042
end

describe file('/etc/mysql/my.cnf') do
  it { should be_mode 644 }	#PER047
  it { should be_owned_by 'mysql' }	#PER048
  it { should be_grouped_into 'mysql' }	#PER049
  it { should be_file }	#PER050
end
