# {{ ansible_managed }}

require 'spec_helper'
require 'etc'

{% if not _users.manage_authorized_keys %}
{% for key, value in users.iteritems() %}
describe file(File.join(Etc.getpwnam("{{ key }}").dir, '.ssh/authorized_keys')) do
  its(:sha256sum) { should eq File.read('/etc/serverspec/spec/fixtures/{{ key }}_keys.checksum').strip } #OPS055
end
{% endfor %}
{% else %}
{% for key, value in users.iteritems() %}
describe file('/etc/ssh/authorized_keys/{{ key }}.keys') do
  it { should be_owned_by 'root' }
  it { should be_grouped_into {{ key }} }
  it { should be_mode 640 }
end
{% endfor %}
{% endif %}
