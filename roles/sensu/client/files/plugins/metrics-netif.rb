#! /usr/bin/env ruby
#
#   netif-metrics
#
# DESCRIPTION:
#   Network interface throughput
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   Copyright 2014 Sonian, Inc. and contributors. <support@sensuapp.org>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'socket'

#
# Netif Metrics
#
class NetIFMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}"
  option :interfaces,
         description: 'list of interfaces to check',
         long: '--interfaces [eth0,eth1]',
         default: 'eth0'
  option :interval,
         descrption: 'how many seconds to collect data for',
         long: '--interval 1',
         default: 1

  def run
    `sar -n DEV #{config[:interval]} 1 | grep Average | grep -v IFACE`.each_line do |line|  # rubocop:disable Style/Next
      stats = line.split(/\s+/)
      unless stats.empty?
        stats.shift
        nic = stats.shift
        if config[:interfaces].include? nic 
          output "#{config[:scheme]}.#{nic}.rx_kb_per_sec", stats[2].to_f * 8 if stats[3]
          output "#{config[:scheme]}.#{nic}.tx_kb_per_sec", stats[3].to_f * 8 if stats[3]
        end
      end
    end

    exit
  end
end

