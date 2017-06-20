require 'spec_helper'

describe package('flapjack') do
  it { should be_installed }
end

describe package('flapjack-admin') do
  it { should be_installed }
end

describe file('/etc/flapjack') do
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
  it { should be_directory }
end

describe file('/etc/flapjack/flapjack_config.yaml') do
  it { should be_file }
end

describe service('flapjack') do
  it { should be_enabled }
end

describe service('redis-flapjack') do
  it { should be_enabled }
end

{% if flapjack.receivers.httpbroker.enabled %}
describe service('flapjack-httpbroker') do
  it { should be_enabled }
end
{% endif %}

{% for item in flapjack.firewall %}
describe port('{{ item.port }}') do
  it { should be_listening }
end
{% endfor %}
