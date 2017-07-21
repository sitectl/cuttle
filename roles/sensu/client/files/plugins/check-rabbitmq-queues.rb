#!/usr/bin/env /opt/sensu/embedded/bin/ruby
#
# Check Rabbitmq Queues
# ===
#
# Purpose: to check the size or number of rabbitmq queues.
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'

class CheckRabbitCluster < Sensu::Plugin::Check::CLI
  option  :warning,
          :description => "Minimum number of messages in the queue before alerting warning",
          :short => '-w NUMBER',
          :long => '--warn NUMBER'

  option  :critical,
          :description => "Minimum number of messages in the queue before alerting critical",
          :short => '-c NUMBER',
          :long => '--crit NUMBER'

  option  :ignore,
          :description => "Comma-separated list of queues to ignore in our check",
          :short => '-i QUEUE,QUEUE,...',
          :long => '--ignore QUEUE,QUEUE,...',
          :default => nil

  option  :type,
          :description => "Type of check to perform",
          :short => '-t TYPE',
          :long => '--type TYPE',
          :valid => %w[length number],
          :default => 'length'

  option  :timeout,
          :description => "timeout in seconds when querying rabbit",
          :short => '-m SECONDS',
          :long => '--timeout SECONDS',
          :default => 3

  def set_defaults
    if config[:type] == 'length'
      config[:warning] = 5 unless !config[:warning].nil?
      config[:critical] = 20 unless !config[:critical].nil?
    else
      config[:warning] = 200 unless !config[:warning].nil?
      config[:critical] = 400 unless !config[:critical].nil?
    end
  end

  def run

    set_defaults

    ignored_queues = []
    ignored_queues = config[:ignore].split(',') unless config[:ignore] == nil

    count = 0
    cmd = "/usr/bin/timeout -s 9 #{config[:timeout]}s /usr/sbin/rabbitmqctl list_queues -p /"
    process = IO.popen(cmd) do |io|
      while line = io.gets
        line.chomp!
        lineparts = line.split(/\s+/)

        if /^Listing queues/ =~ line || /^\.\.\.done/ =~ line || ignored_queues.include?(lineparts[0])
          next
        end

        if config[:type] == 'number'
          count += 1
        else
          count += lineparts[1].to_i
        end
      end
    end
    critical "Listing queues is timing out" if $?.to_i == 137
    critical "Error checking rabbit queues" if $?.to_i > 0

    # Queue size checking
    queue_count = count.to_i
    msg = "Queues not empty"
    msg = "Number of queues" if config[:type] == 'number'

    if queue_count > 0
      if queue_count > config[:critical].to_i
        critical "CRITICAL: #{msg}: #{queue_count}"
      elsif queue_count > config[:warning].to_i
        warning "WARNING: #{msg}: #{queue_count}"
      end
    end
    exit
  end
end
