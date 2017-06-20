# {{ ansible_managed }}

require 'spec_helper'

describe package('ttyspy-server') do
  it { should be_installed }
end

describe service('ttyspy-receiver') do
  it { should be_enabled }
end

describe file('{{ ttyspy.server.transcript_path }}') do
  it { should be_mode 755 }
  it { should be_owned_by 'ttyspy' }
  it { should be_grouped_into 'ttyspy' }
  it { should be_directory }
end

describe file('/etc/ttyspy/server') do
  it { should be_mode 750 }
  it { should be_owned_by 'ttyspy' }
  it { should be_grouped_into 'ttyspy' }
  it { should be_directory }
end

describe port('{{ ttyspy.server.port }}') do
  it { should be_listening }
end

describe file('/etc/ttyspy/compression.py') do
  it { should be_mode 744 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_file }
end

describe file('/etc/cron.daily/ttyspy_compression') do
  it { should be_mode 755 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  it { should be_file }
end
