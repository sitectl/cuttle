# {{ ansible_managed }}

require 'spec_helper'

describe package('ursula-monitoring-sensu') do
  it { should be_installed }
end

describe service('sensu-client') do
  it { should be_enabled }
end
