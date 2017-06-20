# {{ ansible_managed }}

require 'spec_helper'

{% for pkg in yama_utils.dependencies %}
describe package('{{ pkg }}') do
  it { should be_installed }
end
{% endfor %}

describe package('yama-utils') do
  it { should be_installed }
end
