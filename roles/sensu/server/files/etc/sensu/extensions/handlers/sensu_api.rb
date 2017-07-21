# Issue common actions against the Sensu API via messages submitted via sensu-client socket.
#
# This extension requires Sensu >= 0.20.0
#
# Here is an example of what the Sensu configuration for sensu_api should
# look like, assuming your Sensu API is running on the
# same machine as the Sensu Server:
#
# {
#   "sensu_api": {
#      "host": "127.0.0.1",
#      "port": 4567,
#      "user": nil,
#      "pass": nil
#   }
# }
#
# Copyright 2016 Blue Box, an IBM Company
# 07/22/2016 - Myles Steinhauser
#
# Released under the same terms as Sensu (the MIT license); see LICENSE for details.

require 'faraday'
require 'json'

module Sensu
  module Extension
    class SensuApi < Handler
      def name
        'sensu_api'
      end

      def description
        'issue requests against the sensu api'
      end

      def options
        return @options if @options
        @options = {
          host: '127.0.0.1',
          port: 4567,
          user: nil,
          pass: nil,
          datacenter: 'unknown',
          request: {
            open_timeout: 3,
            timeout: 3
          }
        }
        if @settings[:sensu_api].is_a?(Hash)
          @options.merge!(@settings[:sensu_api])
        end
        @logger.debug('sensu_api -- merged settings: ' + JSON.dump(options))
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
        @logger.info("sensu_api -- connecting to sensu-api: #{options[:sensu_api]}")
        begin
          @sensu_api = Faraday.new(:url => "http://#{options[:host]}:#{options[:port]}") do |conn|
            conn.request  :basic_auth, options[:user], options[:pass]
            conn.options.timeout = options[:request][:timeout]
            conn.options.open_timeout = options[:request][:timeout]
            # Use the net/http gem implementation
            conn.adapter  :net_http # must be last line before end
          end
        rescue Faraday::ClientError
          @logger.warn('sensu_api -- sensu-api not available')
        else
          @logger.info('sensu_api -- connected to sensu-api!')
        end
      end

      def _stash_exists?(path)
        path = "/stashes/#{path}"
        @logger.debug("checking for stash: #{path}")
        res = @sensu_api.get(path)
        @logger.debug("#{path}: #{res.status} - #{res.body}")
        res.status == 200
      end

      def _stash_get(path)
        path = "/stashes/#{path}"
        @logger.debug("getting stash: #{path}")
        res = @sensu_api.get(path)
        @logger.debug("#{path}: #{res.status} - #{res.body}")
        return res.body
      end

      def _stash_create(path:, reason:"sensu-api handler", expire:86400) # default expire in 24 hours
        stash = {
          path: path,
          expire: expire,
          dc: options[:datacenter],
          content: {
            reason: reason,
            source: "sensu-server sensu-api handler",
            timestamp: Time.now.to_i
          }
        }
        @logger.debug("creating stash: path: /stashes/#{path}, body: #{stash}")
        res = @sensu_api.post do |req|
          req.url '/stashes'
          req.headers['Content-Type'] = 'application/json'
          req.body = stash.to_json
        end
        @logger.debug("/stashes/#{path}: #{res.status} - #{res.body}")
      end

      def _stash_delete(path)
        path = "/stashes/#{path}"
        @logger.debug("deleting stash: #{path}")
        res = @sensu_api.delete("#{path}")
        @logger.debug("#{path}: #{res.status} - #{res.body}")
      end

      def run(event)
        action = event[:check][:action]
        host = event[:check][:host] || event[:client][:name]
        check = event[:check][:name] || nil

        # event type dispatcher
        case action
          when "silence_host"
            _handle_silence("host", "create", host, check, event)
          when "unsilence_host"
            _handle_silence("host", "delete", host, check, event)
          when "silence_check"
            _handle_silence("check", "create", host, check, event)
          when "unsilence_check"
            _handle_silence("check", "delete", host, check, event)
          when "resolve_check"
            _handle_resolve("check", host, check, event)
          when "delete_host"
            _handle_delete("host", host, check, event)
          when "delete_check"
            _handle_delete("check", host, check, event)
          when "host_all_clear"
            _handle_all_clear("host", host, check, event)
          else
            @logger.error("unknown action: #{action}. Known actions: silence_host, unsilence_host, silence_check, unsilence_check, delete_host, delete_check, resolve_check, host_all_clear")
        end
      end

      def _handle_silence(target, op, host, check, event)
        @logger.debug('handle silence: starting')
        case target
          when "host"
            path = "silence/#{host}"
          when "check"
            path = "silence/#{host}/#{check}"
        end

        case op
          when "create"
            reason = event[:check][:reason] || nil
            expire = event[:check][:expire] || nil
            _stash_create(path:path, reason:reason, expire:expire)
          when "delete"
            _stash_delete(path:path)
        end
        @logger.debug('handle silence: completed')
      end

      def _handle_resolve(host, check, event)
        @logger.debug('handle resolve: starting')
        payload = {
          client: host,
          check: check
        }
        @logger.debug("resolving check: #{payload}")
        res = @sensu_api.post do |req|
          req.url '/resolve'
          req.headers['Content-Type'] = 'application/json'
          req.body = payload.to_json
        end
        @logger.debug('handle resolve: completed')
        return res.body
      end

      def _handle_all_clear(target, host, check, event)
        @logger.debug('handle all clear: starting')
        if target != "host"
          @logger.error("handle all clear: only host is supported for now")
        end

        unsilence = event[:check][:unsilence] || false

        # get all events for host
        res = @sensu_api.get("/events/#{host}")

        # loop over all found events and resolve each, possibly removing stashes
        res.body.each do |current_check|
          _handle_resolve("check", host, current_check, event)
          if unsilence
            _handle_silence("check", "delete", host, current_check, nil)
          end
        end
        @logger.debug('handle all clear: completed')
        return res.body
      end

      def _handle_delete(target, host, check, event)
        @logger.debug('handle delete: starting')
        case target
          when "host"
            path = "clients/#{host}"
          when "check"
            path = "events/#{host}/#{check}"
        end

        res = @sensu_api.delete("#{path}")
        @logger.debug('handle delete: completed')
        return res.body
      end
    end
  end
end
