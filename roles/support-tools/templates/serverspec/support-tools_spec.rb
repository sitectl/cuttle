# {{ ansible_managed }}
require 'spec_helper'

{% for item in support_tools.git %}
describe file('{{ item.path }}') do
  it { should be_owned_by '{{ item.owner|default(admin_user) }}' }	#SPT001
  it { should be_directory }	#SPT002
end
{% endfor %}

{% for venv in support_tools.virtualenvs %}
describe file('{{ venv.path }}') do
  it { should be_owned_by '{{ venv.owner }}' }	#SPT003
  it { should be_directory }	#SPT004
end
{% endfor %}

describe file('/usr/sbin/git_pull') do
  it { should be_mode 700 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_file }
end

describe file('/etc/sudoers.d/git_pull') do
  it { should be_mode 700 }	#SPT005
  it { should be_owned_by 'root' }	#SPT006
  it { should be_grouped_into 'root' }	#SPT007
  it { should be_file }	#SPT008
  its(:content) { should contain('blueboxadmin ALL=NOPASSWD: /usr/sbin/git_pull') } #SPT009
end
