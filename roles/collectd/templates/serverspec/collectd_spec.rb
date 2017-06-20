# {{ ansible_managed }}

require 'spec_helper'

describe package('collectd') do
  it { should be_installed }
end

describe service('collectd') do
  it { should be_enabled }
end
