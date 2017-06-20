#!/usr/bin/env /opt/sensu/embedded/bin/ruby
#
# Check Rabbitmq Cluster
# ===
#
# Purpose: to check the health of the rabbitmq cluster.
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'

class CheckRabbitCluster < Sensu::Plugin::Check::CLI
  option  :expected,
          :description => "Number of servers expected in the cluster",
          :short => '-e NUMBER',
          :long => '--expected NUMBER',
          :default => 2

  option  :criticality,
          :description => "Set sensu alert level, default is critical",
          :short => '-z CRITICALITY',
          :long => '--criticality CRITICALITY',
          :default => 'critical'

  def switch_on_criticality()
    if config[:criticality] == 'warning'
      warning
    else
      critical
    end
  end

  def run
    cmd = "/usr/sbin/rabbitmqctl -q cluster_status | awk '/disc/,/\},/' | awk '/@/ {++nodes} END {print nodes}' | grep #{config[:expected]}"
    system(cmd)

    if $?.exitstatus == 0
      exit
    else
      switch_on_criticality()
    end
  end
end
