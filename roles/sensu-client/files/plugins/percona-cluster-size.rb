#!/usr/bin/env /opt/sensu/embedded/bin/ruby
#
# Percona Cluster Size Plugin
# ===
#
# This plugin checks the number of servers in the Percona cluster and warns you according to specified limits
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'

class CheckPerconaClusterSize < Sensu::Plugin::Check::CLI

  option  :user,
          :description => "MySQL User",
          :short => '-u USER',
          :long => '--user USER',
          :default => 'root'

  option  :password,
          :description => "MySQL Password",
          :short => '-p PASS',
          :long => '--password PASS'

  option  :hostname,
          :description => "Hostname to login to",
          :short => '-h HOST',
          :long => '--hostname HOST',
          :default => 'localhost'

  option  :min_expected,
          :description => "Minimum number of servers expected in the cluster",
          :short => '-e NUMBER',
          :long => '--expected NUMBER',
          :default => 2

  option :defaults_file,
         :description => "mysql defaults file",
         :short => '-d DEFAULTS_FILE',
         :long => '--defaults-file DEFAULTS_FILE'

 option :criticality,
        :description => "Set sensu alert level, default is critical",
        :short => '-z CRITICALITY',
        :long => '--criticality CRITICALITY',
        :default => 'critical'

  def switch_on_criticality(msg)
    if config[:criticality] == 'warning'
      warning msg
    else
      critical msg
    end
  end

  def run
    if config[:defaults_file]
      db_cluster_size = `mysql --defaults-file=#{config[:defaults_file]} -e "SHOW STATUS WHERE Variable_name like 'wsrep_cluster_size' AND Value >= #{config[:min_expected]};" | grep 'wsrep_cluster_size' | awk '{print $2}'`
    else
     db_cluster_size = `mysql -u #{config[:user]} -p#{config[:password]} -h #{config[:hostname]} -e "SHOW STATUS WHERE Variable_name like 'wsrep_cluster_size' AND Value >= #{config[:min_expected]};" | grep 'wsrep_cluster_size' | awk '{print $2}'`
    end

   ok "Expected to find #{config[:min_expected]} or more nodes and found #{db_cluster_size}" if db_cluster_size.to_i >= config[:min_expected].to_i
   switch_on_criticality("Expected to find #{config[:min_expected]} or more nodes, found #{db_cluster_size}") if db_cluster_size.to_i < config[:min_expected].to_i
  end
end
