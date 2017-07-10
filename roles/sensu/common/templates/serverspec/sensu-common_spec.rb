# {{ ansible_managed }}

require 'spec_helper'

describe package('sensu') do
  it { should be_installed }
end
