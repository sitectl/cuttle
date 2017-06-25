#! /usr/bin/env ruby
#metrics for elk-stats prediction

require 'sensu-plugin/metric/cli'
require 'socket'
require 'json'

class ELKPrediction < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to  prepend to .$parent.$child',
         long: '--scheme SCHEME',
         default: Socket.gethostname.to_s
  option :days,
         description: 'Days to predict ahead of time.',
         long: '--days-ahead DAYS',
         default: 90
  option :hosts,
         description: 'Number of hosts to predict size with.',
         long: '--hosts',
         default: 50
  option :retention,
         description: 'Retention rate set in Elasticsearch configuration.',
         long: '--retention RETENTION',
         default: 270
         

  def run
    timestamp = Time.now.to_i
    filename = "/opt/sitecontroller/elk-stats-output/stats-summary-%s.json" % timestamp
    statement = "/usr/bin/python /opt/sitecontroller/scripts/elk-stats.py -d %s -n %s -f %s -r %s" \
        % [config[:days], config[:hosts], filename, config[:retention]]
    result = `#{statement}`
    file = File.read(filename)
    data_hash = JSON.parse(file)
    projection = data_hash["Current Projected Size"]
    desired_host_projection = data_hash["Desired-Host Projected Size"]
    hosts_sustainable = data_hash["Max Hosts Sustainable"]
    days_remaining = data_hash["Days Remaining Until Max Capacity Reached"]
    last_index_size = data_hash["Last Index Size"]
    last_num_all_msg = data_hash["Last Number of All Messages in a Day"]
    last_debug_ratio = data_hash["Last Debug Ratio"]
    last_host_count = data_hash["Last Host Count"]

    output [config[:scheme], 'projection'].join('.'), projection, timestamp
    output [config[:scheme], 'desired_host_projection'].join('.'), desired_host_projection, timestamp
    output [config[:scheme], 'hosts_sustainable'].join('.'), hosts_sustainable, timestamp
    output [config[:scheme], 'days_remaining'].join('.'), days_remaining, timestamp
    output [config[:scheme], 'last_index_size'].join('.'), last_index_size, timestamp
    output [config[:scheme], 'last_num_all_msg'].join('.'), last_num_all_msg, timestamp
    output [config[:scheme], 'last_debug_ratio'].join('.'), last_debug_ratio, timestamp
    output [config[:scheme], 'last_host_count'].join('.'), last_host_count, timestamp
    exit
  end
end
