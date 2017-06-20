# {{ ansible_managed }}

require 'spec_helper'

{% for pkg in yubiauthd.dependencies %}
describe package('{{ pkg }}') do
  it { should be_installed }
end
{% endfor %}

describe package('yubiauthd') do
  it { should be_installed }
end

describe service('yubiauthd') do
  it { should be_enabled }
end

describe file('/etc/yubiauthd.conf') do
  it { should be_mode 640 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_file }
end

describe file('/etc/init/yubiauthd.conf') do
  it { should be_mode 644 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_file }
end

describe file('/var/lib/yubiauthd.sqlite') do
  it { should be_mode 600 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_file }
end

{% if groups['bastion'][1] is defined %}
describe port('{{ yubiauthd.sync_port }}') do
  it { should be_listening }
end
{% endif %}
