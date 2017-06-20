#!/usr/bin/env /opt/sensu/embedded/bin/ruby
#
# Linux network interface metrics
# ====
#
# Simple plugin that fetchs metrics from all interfaces
# on the box using the /sys/class interface.
#
# Use the data with graphite's `nonNegativeDerivative()` function
# to construct per-second graphs for your hosts.
#
# Non `eth` and `bond` ifaces are ignored by default.
#
# Compat
# ------
#
# This plugin uses the `/sys/class/net/<iface>/statistics/{rx,tx}_*`
# files to fetch stats. On older linux boxes without /sys, this same
# info can be fetched from /proc/net/dev but additional parsing
# will be required.
#
# Example:
# --------
#
# $ ./metrics-packets.rb --scheme servers.web01 -i eth
#   servers.web01.eth0.tx_packets 982965    1351112745
#   servers.web01.eth0.rx_packets 1180186   1351112745
#   servers.web01.eth1.tx_packets 273936669 1351112745
#   servers.web01.eth1.rx_packets 563787422 1351112745
#
# Copyright 2012 Joe Miller <https://github.com/joemiller>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'socket'

class LinuxPacketMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.net"
  option :all,
         description: 'Return results for all interfaces',
         short: '-a',
         long: '--all',
         default: false
  option :accept_ifaces,
         description: 'List of interfaces to collect from (default eth,bond)',
         short: '-i IFACE1,IFACE2,...',
         long: '--interfaces IFACE1,IFACE2,...',
         default: 'eth,bond'

  def run
    timestamp = Time.now.to_i

    Dir.glob('/sys/class/net/*').each do |iface_path|
      next if File.file?(iface_path)
      current_iface = File.basename(iface_path)
      accept_ifaces = config[:accept_ifaces].split(',')
      next if current_iface == 'lo'
      next if !config[:all] and !accept_ifaces.any? { |accept_iface| current_iface.start_with?(accept_iface) }

      tx_pkts = File.open(iface_path + '/statistics/tx_packets').read.strip
      rx_pkts = File.open(iface_path + '/statistics/rx_packets').read.strip
      tx_bytes = File.open(iface_path + '/statistics/tx_bytes').read.strip
      rx_bytes = File.open(iface_path + '/statistics/rx_bytes').read.strip
      tx_errors = File.open(iface_path + '/statistics/tx_errors').read.strip
      rx_errors = File.open(iface_path + '/statistics/rx_errors').read.strip
      tx_dropped = File.open(iface_path + '/statistics/tx_dropped').read.strip
      rx_dropped = File.open(iface_path + '/statistics/rx_dropped').read.strip
      output "#{config[:scheme]}.#{current_iface}.tx_packets", tx_pkts, timestamp
      output "#{config[:scheme]}.#{current_iface}.rx_packets", rx_pkts, timestamp
      output "#{config[:scheme]}.#{current_iface}.tx_bytes", tx_bytes, timestamp
      output "#{config[:scheme]}.#{current_iface}.rx_bytes", rx_bytes, timestamp
      output "#{config[:scheme]}.#{current_iface}.tx_errors", tx_errors, timestamp
      output "#{config[:scheme]}.#{current_iface}.rx_errors", rx_errors, timestamp
      output "#{config[:scheme]}.#{current_iface}.tx_dropped", tx_dropped, timestamp
      output "#{config[:scheme]}.#{current_iface}.rx_dropped", rx_dropped, timestamp
    end
    exit
  end
end
