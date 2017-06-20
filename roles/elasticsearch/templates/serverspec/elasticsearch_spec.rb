require 'spec_helper'

describe package('elasticsearch') do
  it { should be_installed.by('apt') }	#ELS001
end

describe file('/etc/security/limits.conf') do
{% if elasticsearch.max_open_files is defined %}
  its(:content) { should contain('elasticsearch     -    nofile    {{ elasticsearch.max_open_files }}') }	#ELS002
{% endif %}
{% if elasticsearch.max_locked_memory is defined %}
  its(:content) { should contain('elasticsearch     -    memlock   {{ elasticsearch.max_locked_memory }}') }	#ELS003
{% endif %}
end

files = ['su','common-session', 'common-session-noninteractive', 'sudo']
files.each do |file|
  describe file("/etc/pam.d/#{ file }") do
    it { should be_file }	#ELS004
    its(:content) { should contain('session    required   pam_limits.so') }	#ELS005
  end
end

describe file('/etc/init.d/elasticsearch') do
  it { should be_file }	#ELS006
end

describe file('/etc/elasticsearch/elasticsearch.yml') do
  it { should be_mode 644 }	#ELS008
  it { should be_file }	#ELS009
end

describe file('/etc/default/elasticsearch') do
  it { should be_mode 644 }	#ELS010
  it { should be_file }	#ELS011
end

{% for item in elasticsearch.firewall %}
describe port('{{ item.port }}') do
  it { should be_listening }	#ELS012
end
{% endfor %}

describe package('elasticsearch-curator') do
  it { should be_installed.by('pip') }	#ELS013
end

describe file('/usr/bin/curator') do
  it { should be_file }	#ELS014
  it { should be_linked_to '/usr/local/bin/curator' }	#ELS015
end

describe package('elasticsearch') do
  it { should be_installed }
end

describe service('elasticsearch') do
  it { should be_enabled }
end
