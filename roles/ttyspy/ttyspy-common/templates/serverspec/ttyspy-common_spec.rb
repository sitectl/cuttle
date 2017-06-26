# {{ ansible_managed }}

require 'spec_helper'

{% for pkg in ttyspy.common.dependencies %}
describe package('{{ pkg }}') do
  it { should be_installed }
end
{% endfor %}

describe file('/etc/ttyspy') do
  it { should be_mode 755 }
  it { should be_owned_by 'ttyspy' }
  it { should be_grouped_into 'ttyspy' }
  it { should be_directory }
end
