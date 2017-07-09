require 'spec_helper'

describe command('apache2ctl -M') do
{% if auth_basic.ssl.enabled %}
  its(:stdout) { should contain('ssl_module') }	#OIP002
{% endif %}
{% if auth_basic.apache_status %}
  its(:stdout) { should contain('status_module') }	#OIP003
{% endif %}
  its(:stdout) { should contain('headers_module') }	#OIP004
  its(:stdout) { should contain('proxy_http_module') }	#OIP005
end

{% if auth_basic.ssl.enabled %}
describe file('/etc/ssl/private/{{ auth_basic.vhost_name }}.key') do
  it { should be_mode 640 }	#OIP007
  it { should be_owned_by 'root' }	#OIP008
  it { should be_grouped_into 'ssl-key' }	#OIP009
  it { should be_file }	#OIP010
end
describe file('/etc/ssl/certs/{{ auth_basic.vhost_name }}.pem') do
  it { should be_file }	#OIP011
end
{% endif %}

describe file('/etc/apache2/sites-available/{{ auth_basic.vhost_name }}.conf') do
  it { should be_file }	#OIP012
  its(:content) { should contain('<VirtualHost').before(':{{ auth_basic.listen_port }}>') }	#OIP013
end

describe file('/etc/apache2/sites-enabled/{{ auth_basic.vhost_name }}.conf') do
  it { should be_file }	#OIP014
end

{% for user in auth_basic.users %}
describe file('/etc/apache2/openid_admin_passwd') do
  it { should be_file }	#OIP018
  its(:content) { should contain('{{ user.username }}') }	#OIP019
  its(:content) { should_not contain /({{ user.username }}:.{0,15})$/}	#OIP020
end
{% endfor %}

describe file('/var/www/html/index.html') do
  it { should be_file }	#OIP021
end

{% for item in auth_basic.firewall %}
describe port('{{ item.port }}') do
  it { should be_listening }	#OIP022
end
{% endfor %}

describe package('apache2') do
  it { should be_installed }
end

describe service('apache2') do
  it { should be_enabled }
end
