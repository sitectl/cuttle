# {{ ansible_managed }}

require 'spec_helper'

describe package('filebeat') do
  it { should be_installed }
end

describe service('filebeat') do
  it { should be_enabled }
end
