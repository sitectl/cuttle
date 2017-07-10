#!/opt/sensu/embedded/bin/ruby
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

require 'sensu-plugin/check/cli'
require 'socket'

#
# Netif Metrics
#
class NetIFMetrics < Sensu::Plugin::Check::CLI
  option :interfaces,
         description: 'list of interfaces to check',
         long: '--interfaces [eth0,eth1]',
         default: 'eth0'
  option :warn,
         short: '-w Mbps',
         default: 250,
         proc: proc(&:to_i),
         description: 'Warning Mbps, default: 250'
  option :crit,
         short: '-c Mbps',
         default: 500,
         proc: proc(&:to_i),
         description: 'Critical Mbps, default: 500'
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
          rx_mbps = ( stats[2].to_f * 8 ) / 1000
          tx_mbps = ( stats[3].to_f * 8 ) / 1000
          if rx_mbps > config[:crit] || tx_mbps > config[:crit]
            status = "#{nic} #{rx_mbps} rx_mbps or #{tx_mbps} tx_mbps  is too high"
            critical status
          elsif rx_mbps > config[:warn] || tx_mbps > config[:warn]
            status = "#{nic} #{rx_mbps} rx_mbps or #{tx_mbps} tx_mbps  is pretty high"
            warning status
          end
        end
      end
    end
    exit
  end
end
