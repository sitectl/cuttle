# {{ ansible_managed }}

require 'spec_helper'

describe iptables do
  it { should have_rule('-p tcp -m tcp --dport {{ netdata_dashboard.apache.port }} -j ACCEPT') }
end
