# {{ ansible_managed }}

require 'spec_helper'

describe package('uchiwa') do
  it { should be_installed }
end

describe service('uchiwa') do
  it { should be_enabled }
end

describe service('sensu-api') do
  it { should be_enabled }
end

describe service('sensu-server') do
  it { should be_enabled }
end

describe port("{{ sensu.api.port }}") do
  it { should be_listening }
end

describe port("{{ sensu.dashboard.port }}") do
  it { should be_listening }
end
