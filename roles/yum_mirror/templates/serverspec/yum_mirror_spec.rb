# {{ ansible_managed }}

require 'spec_helper'

describe package('yum') do
  it { should be_installed }
end

describe package('yum-utils') do
  it { should be_installed }
end

describe package('createrepo') do
  it { should be_installed }
end

describe package('apache2') do
  it { should be_installed }
end

describe service('apache2') do
  it { should be_enabled }
end

describe file('/etc/yum/yum.conf') do
  it { should be_file }
end

describe file('/etc/cron.d/yum_mirror') do
  it { should be_file }
end

describe file('{{ yum_mirror.path }}/mirror') do
  it { should be_directory }
end

describe file('{{ yum_mirror.path }}/keys') do
  it { should be_directory }
end

{% for key, value in yum_mirror.repositories.iteritems() %}
{% if value.key_url is defined %}
describe file('{{ yum_mirror.path }}/keys/{{ key }}.key') do
  it { should be_file }
end
{% endif %}
{% endfor %}

describe file('/etc/apache2/sites-available/yum_mirror.conf') do
  it { should be_file }
end

describe file('/etc/apache2/sites-enabled/yum_mirror.conf') do
  it { should be_symlink }
end

describe port('{{ yum_mirror.apache.port }}') do
  it { should be_listening }
end

describe iptables do
  it { should have_rule('-p tcp -m tcp --dport {{ yum_mirror.apache.port }} -j ACCEPT') }
end
