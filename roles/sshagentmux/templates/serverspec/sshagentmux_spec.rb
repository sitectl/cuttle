# {{ ansible_managed }}

require 'spec_helper'

describe package('sqlite3') do
  it { should be_installed } #SAM001
end

describe file('{{ sshagentmux.virtualenv_path }}') do
  it { should be_directory }	#SAM002
end

describe file('/etc/init/authorization_proxy.conf') do
  it { should be_mode 644}	#SAM005
end

describe service('authorization_proxy') do
  it { should be_enabled }
end
