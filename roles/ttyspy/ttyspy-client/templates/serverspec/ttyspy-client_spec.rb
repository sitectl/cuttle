# {{ ansible_managed }}
require 'spec_helper'

describe package('ttyspy-client') do
  it { should be_installed }
end

describe service('ttyspyd') do
  it { should be_enabled }
end

describe file('/etc/ttyspy.conf') do
  it { should be_mode 644 }
  it { should be_owned_by 'ttyspy' }
  it { should be_grouped_into 'ttyspy' }
  it { should be_file }
end

describe file('/etc/ttyspy/client') do
  it { should be_mode 750 }
  it { should be_owned_by 'ttyspy' }
  it { should be_grouped_into 'ttyspy' }
  it { should be_directory }
end

describe file('/etc/init/ttyspyd.conf') do
  it { should be_mode 644 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_file }
end
