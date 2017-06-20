# {{ ansible_managed }}

require 'spec_helper'

describe package('dnsmasq') do
  it { should be_installed }
end

describe service('dnsmasq') do
  it { should be_enabled }
end
