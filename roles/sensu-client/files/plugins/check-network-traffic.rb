#!/opt/sensu/embedded/bin/ruby
#
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'

class CheckNetworkStats < Sensu::Plugin::Check::CLI

  linkspeed = `ethtool eth0 | grep Speed`

  if linkspeed.include? "10000Mb"
    linkwarn = 9000
    linkcrit = 12000
  else
    linkwarn = 900
    linkcrit = 1200
  end

  option :warn,
    :short => '-w WARN',
    :proc => proc {|a| a.to_i },
    :default => linkwarn
  option :crit,
    :short => '-c CRIT',
    :proc => proc {|a| a.to_i },
    :default => linkcrit
  option :rxmcswarn,
    :short => '-pw WARN',
    :proc => proc {|a| a.to_i },
    :default => 9000
  option :rxmcscrit,
    :short => '-pc CRIT',
    :proc => proc {|a| a.to_i },
    :default => 10000
  option :iface,
    :short => '-i IFACE',
    :default => "eth0"

  def run
    iface = config[:iface]
    line = %x{sar -n DEV 5 1}.lines.find { |x| x =~ /Average/ && x =~/\s#{iface}\s/ }
    stats = line.split
    unless stats.empty?
      stats.shift
      nic = stats.shift
      stats.map! { |x| x.to_f }
      rxpck, txpck, rxkB, txkB, rxcmp, txcmp, rxmcs = stats

      msg = "\nIngress kB/s=#{rxkB} \nEgress kB/s=#{txkB} \nIngress multicast packets per second=#{rxmcs}"
      message msg

      warning if rxkB >= config[:warn] or rxkB <= -config[:warn]
      warning if txkB >= config[:warn] or txkB <= -config[:warn]
      warning if rxmcs >= config[:rxmcswarn] or rxmcs <= -config[:rxmcswarn]
      critical if rxkB >= config[:crit] or rxkB <= -config[:crit]
      critical if txkB >= config[:crit] or txkB <= -config[:crit]
      critical if rxmcs >= config[:rxmcscrit] or rxmcs <= -config[:rxmcscrit]

      exit
    end
  end
end
