# {{ ansible_managed }}

require 'spec_helper'

describe package('apache2') do
  it { should be_installed }
end

describe service('apache2') do
  it { should be_enabled }
end

describe package('lynx-cur') do
  it { should be_installed }
end

['000-default', '000-default.conf', 'default', 'default.conf'].each do |file|
  describe file("/etc/apache/sites-enabled/#{file}") do
    it { should_not exist }
  end
end

describe file('/etc/apache2/ports.conf') do
  it { should be_file }
end

{% for module in apache.modules %}
describe package('{{ module }}') do
  it { should be_installed }
end
{% endfor %}
