# Sends events to Flapjack HTTP Broker for notification routing. See http://flapjack.io/
#
# This extension requires Flapjack >= 0.8.7 and Sensu >= 0.20.0
#
# In order for Flapjack to keep its entities up to date, it is necssary to set
# metric to "true" for each check that is using the flapjack handler extension.
#
# Here is an example of what the Sensu configuration for flapjack_http should
# look like, assuming your Flapjack's HTTP Broker is running on the
# same machine as the Sensu server:
#
# {
#   "flapjack_http": {
#      "uri": "http://sensu.example.com:3090"
#   }
# }
#
# Copyright 2015 Blue Box, an IBM Company
# 12/11/2015 - Myles Steinhauser
#
# Released under the same terms as Sensu (the MIT license); see LICENSE for details.

require 'faraday'
require 'multi_json'
require 'timeout'
require 'net/http/persistent'
require 'net/http'

module Sensu
  module Extension
    class FlapjackHttp < Bridge
      def name
        'flapjack_http'
      end

      def description
        'sends sensu events to the flapjack http broker'
      end

      def options
        return @options if @options
        @options = {
          uri: 'http://127.0.0.1:3090',
          sensu_api: {
             uri: 'http://127.0.0.1:4567',
             user: nil,
             pass: nil
          },
          ttl: 30, # seconds before event enters unknown state
          # default: "http_proxy" environment variable
          ## https://github.com/lostisland/faraday/blob/3579225fd18c770dd2dc5d020d74b72701e4e647/lib/faraday/options.rb#L216
          # proxy: {
          # },
          ## https://github.com/lostisland/faraday/blob/3579225fd18c770dd2dc5d020d74b72701e4e647/lib/faraday/options.rb#L204-L205
          # ssl: {
          # },
          service_owner: 'default',
          default_send: true,
          default_send_metric: false,
          default_send_check: true,
          occurrences: 1,
          interval: 30,
          refresh: 1800,
          request: {
            open_timeout: 3,
            timeout: 3
          }
        }
        if @settings[:flapjack_http].is_a?(Hash)
          @options.merge!(@settings[:flapjack_http])
        end
        @logger.debug('flapjack_http -- merged settings: ' + MultiJson.dump(options))
        @options
      end

      def definition
        {
          type: 'extension',
          name: name,
          mutator: 'ruby_hash'
        }
      end

      def post_init
        @logger.debug('flapjack_http -- connecting with settings: ' + MultiJson.dump(options))
        begin
          @flapjack = Faraday.new(:url => options[:uri],
                              :ssl => options[:ssl],
                              :proxy => options[:proxy],
                              :request => options[:request]) do |faraday|
            # Use the net/http/persistent gem implementation
            faraday.adapter  :net_http_persistent
          end
        rescue Faraday::ClientError
          @logger.warn('flapjack_http -- http broker not available on ' + options[:uri])
        else
          @logger.info('flapjack_http -- connected to: ' + options[:uri])
        end

        @logger.info("flapjack_http -- connecting to sensu-api: #{options[:sensu_api][:user]}@#{options[:sensu_api][:uri]}")
        begin
          @sensu_api = Faraday.new(:url => options[:sensu_api][:uri]) do |faraday|
            faraday.request  :basic_auth, options[:sensu_api][:user], options[:sensu_api][:pass]
            # Use the net/http/persistent gem implementation
            faraday.adapter  :net_http
          end
        rescue Faraday::ClientError
          @logger.warn('flapjack_http -- sensu-api not available')
        else
          @logger.info('flapjack_http -- connected to sensu-api!')
        end
      end

      def _tag_service_owners(event)
        tags = []
        unless (event[:client].has_key? :service_owner or event[:check].has_key? :service_owner)
          tags << 'service_owner:' + options[:service_owner]
          return tags
        end

        if event[:client][:service_owner]
          Array(event[:client][:service_owner]).each { |service_owner|
            tags << 'service_owner:' + service_owner
          }
        end

        if event[:check][:service_owner]
          Array(event[:check][:service_owner]).each { |service_owner|
            tags << 'service_owner:' + service_owner
          }
        end

        return tags
      end

      def _get_tags(event, client, check)
        tags = []
        tags.concat(_tag_service_owners(event))
        tags.concat(client[:tags]) if client[:tags].is_a?(Array)
        tags.concat(check[:tags]) if check[:tags].is_a?(Array)
        tags << client[:environment] unless client[:environment].nil?
        unless check[:subscribers].nil? || check[:subscribers].empty? # rubocop:disable UnlessElse
          tags.concat(client[:subscriptions] - (client[:subscriptions] - check[:subscribers]))
        else
          tags.concat(client[:subscriptions])
        end
        return tags
      end

      def _get_details(event, client, check, tags)
         details = ['Address:' + client[:address]]
         details << 'Tags:' + tags.join(',')
         details << "Raw Output: #{check[:output]}" if check[:notification]
         return details
      end

      def _build_flapjack_event(event)
        client = event[:client]
        check = event[:check]

        tags = _get_tags(event, client, check)
        details = _get_details(event, client, check, tags)

        flapjack_event = {
          entity: client[:name],
          check: check[:name],
          type: 'service',
          state: Sensu::SEVERITIES[check[:status]] || 'unknown',
          summary: check[:notification] || check[:output],
          details: details.join(' '),
          time: check[:executed],
          tags: tags,
          ttl: event[:ttl] ? event[:ttl] : options[:ttl]
        }

        return flapjack_event
      end

      def send_event(event)
        begin
          flapjack_event = _build_flapjack_event(event)

          @flapjack.post do |req|
            req.url '/state'
            req.headers['Content-Type'] = 'application/json'
            req.body = MultiJson.dump(flapjack_event)
          end

          @logger.debug("flapjack_http -- sent an event to the flapjack http broker")
        rescue Faraday::TimeoutError => e
          @logger.warn("flapjack_http -- timeout when sending event to http broker at #{options[:uri]}: #{e}")
        rescue Faraday::ClientError => e 
          @logger.warn("flapjack_http -- client error when sending event to http broker at #{options[:uri]}: #{e}")
        rescue StandardError => e
          @logger.error("flapjack_http -- error sending event to http broker at #{options[:uri]}: #{e}")
        end
      end

      def run(event)
        if event[:check][:status] == 0 # always forward ok alerts
          @logger.debug('alert ok, forwarding')
          send_event(event)
        elsif filter(event) # only returns true for events which pass
          send_event(event)
        else
          @logger.debug("NOT sending event: #{event[:client][:name]}/#{event[:check][:name]}")
        end
        yield
      end

      # Filters yield events that should not be handled.
      def filter(event)
        @logger.debug('filtering event:')
        @logger.debug(event)
        unless filter_send_event(event)
          @logger.debug('event type should not be sent')
          return false
        end
        unless filter_disabled(event)
          @logger.debug('event is disabled')
          return false
	end
        unless filter_repeated(event)
          @logger.debug('event has not repeated enough')
          return false
	end
        unless filter_silenced(event)
          @logger.debug('event should be silenced')
          return false
	end
        unless filter_dependencies(event)
          @logger.debug('event has alerting dependencies')
          return false
	end
	return true
      end

      def filter_send_event(event)
        # Only send event if that type is enabled.
        # Merge order: options[:default_send] < options[:default_send_[:type]]
        case event[:check][:type]
        when 'metric'
          alert = options[:default_send_metric]
        when 'check'
          alert = options[:default_send_check]
        else
          alert = options[:default_send]
        end
        unless alert
          @logger.debug("event should not be sent: #{event[:client][:name]}/#{event[:check][:name]}")
        end
        return alert
      end

      def filter_disabled(event)
        alert = true
        if event[:check].key?(:alert)
          if event[:check][:alert] == false
            @logger.debug('alert disabled')
            alert = false
          end
        end
	return alert
      end

      def filter_repeated(event)
        alert = true
        occurrences = (event[:check][:occurrences] || options[:occurrences]).to_i
        interval = (event[:check][:interval] || options[:interval]).to_i
        refresh = (event[:check][:refresh] || options[:refresh]).to_i
        if event[:occurrences] < occurrences
          alert = false
        end
        if event[:occurrences] > occurrences && event[:action] == 'create'
          number = refresh.fdiv(interval).to_i
          unless number == 0 || (event[:occurrences] - occurrences) % number == 0
            @logger.debug("only handling every #{number} occurrences")
            alert = false
          end
        end
        return alert
      end

      def stash_exists?(path)
        path = "/stashes#{path}"
        @logger.debug("checking for stash at: #{path}")
        res = @sensu_api.get(path)
        @logger.debug("#{path} : #{res.status} - #{res.body}")
        res.status == 200
      end

      def filter_silenced(event)
	alert = true
        stashes = {
          "client" => "/silence/#{event[:client][:name]}",
          "client_check" => "/silence/#{event[:client][:name]}/#{event[:check][:name]}",
          "all_check" => "/silence/all/#{event[:check][:name]}"
        }
        stashes.each do |scope, path|
          if alert
            begin
              Timeout.timeout(5) do
                if stash_exists?(path)
                  @logger.debug("#{scope} alerts silenced")
                  alert = false
                end
              end
            rescue Errno::ECONNREFUSED
              @logger.error('connection refused attempting to query the sensu api for a stash')
            rescue Timeout::Error
              @logger.error('timed out while attempting to query the sensu api for a stash')
            end
          end
        end
        return alert
      end

      def event_exists?(client, check)
        path = '/events/' + client + '/' + check
        @logger.debug("checking for dependency at: #{path}")
        res = @sensu_api.get(path)
        @logger.debug("#{path} : #{res.status} - #{res.body}")
        res.status == 200
      end

      def filter_dependencies(event)
        alert = true
        @logger.debug("filter dependencies")
        deps = event[:check].fetch(:dependencies, [].freeze)
        @logger.debug("dependencies: #{deps}")
        Array(deps).each do |dependency|
          begin
            @logger.debug("dependency: #{dependency}")
            Timeout.timeout(2) do
              check, client = dependency.split("/").reverse
              if event_exists?(client || event[:client][:name], check)
                @logger.debug("check dependency event exists")
                alert = false
              end
            end
          rescue Errno::ECONNREFUSED
            @logger.error("connection refused while attempting to query the sensu api for an events")
          rescue Timeout::Error
            @logger.error("timed out while attempting to query the sensu api for an event")
          end
        end
        return alert
      end

    end
  end
end
