require 'spec_helper'

describe command('apache2ctl -M') do
{% if oauth2_proxy.apache.ssl.enabled %}
  its(:stdout) { should contain('ssl_module') }	#OIP002
{% endif %}
{% if oauth2_proxy.apache_status %}
  its(:stdout) { should contain('status_module') }	#OIP003
{% endif %}
  its(:stdout) { should contain('headers_module') }	#OIP004
  its(:stdout) { should contain('proxy_http_module') }	#OIP005
end

{% if oauth2_proxy.apache.ssl.enabled %}
describe file('/etc/ssl/private/{{ oauth2_proxy.vhost_name }}.key') do
  it { should be_mode 640 }	#OIP007
  it { should be_owned_by 'root' }	#OIP008
  it { should be_grouped_into 'ssl-key' }	#OIP009
  it { should be_file }	#OIP010
end
describe file('/etc/ssl/certs/{{ oauth2_proxy.vhost_name }}.crt') do
  it { should be_file }	#OIP011
end
{% endif %}

describe file('/etc/apache2/sites-available/{{ oauth2_proxy.vhost_name }}.conf') do
  it { should be_file }	#OIP012
  its(:content) { should contain('<VirtualHost').before(':{{ oauth2_proxy.apache.port }}>') }	#OIP013
end

describe file('/etc/apache2/sites-enabled/{{ oauth2_proxy.vhost_name }}.conf') do
  it { should be_file }	#OIP014
end

describe file('/var/www/html/index.html') do
  it { should be_file }	#OIP021
end

{% for item in oauth2_proxy.firewall %}
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
