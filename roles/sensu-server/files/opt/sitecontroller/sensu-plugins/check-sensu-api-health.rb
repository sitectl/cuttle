#! /usr/bin/env ruby
#
#   sensu-api-health
#
# DESCRIPTION:
#   Check health of sensu-api and consumption of keepalives and results.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: json
#   gem: uri
#
# USAGE:
#  #YELLOW
#
# NOTES:
#
# LICENSE:
#   Copyright 2016 Myles Steinhauser <msteinha@us.ibm.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'net/http'
require 'net/https'
require 'json'
require 'uri'

class SensuApiHealthCheck < Sensu::Plugin::Check::CLI
  option :host,
         short: '-h HOST',
         long: '--host HOST',
         description: 'Your sensu-api endpoint',
         required: true,
         default: 'localhost'

  option :port,
         short: '-P PORT',
         long: '--port PORT',
         description: 'Your sensu-api port',
         required: true,
         default: 4567

  option :username,
         short: '-u USERNAME',
         long: '--username USERNAME',
         description: 'Your sensu-api username',
         required: false
  option :password,
         short: '-p PASSWORD',
         long: '--password PASSWORD',
         description: 'Your sensu-api password',
         required: false

  option :https,
         short: '-s',
         long: '--secure',
         description: 'Use HTTPS instead of HTTP',
         default: false,
         required: false

  option :results,
         short: '-r results',
         long: '--results results',
         description: 'Number of results allowed to be queued.',
         required: false,
         default: 1000

  option :keepalives,
         short: '-k keepalives',
         long: '--keepalives keepalives',
         description: 'Number of keepalives allowed to be queued.',
         required: false,
         default: 10

  def json_valid?(str)
    begin
      JSON.parse(str)
      return true
    rescue
      return false
    end
  end

  def run
    endpoint = config[:https] ? "https://#{config[:host]}:#{config[:port]}" : "http://#{config[:host]}:#{config[:port]}"
    url      = URI.parse(endpoint)

    begin
      # res = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https', verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      res = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https') do |http|
        req = Net::HTTP::Get.new('/info')
        req.basic_auth config[:username], config[:password] if config[:username] && config[:password]
        http.request(req)
      end
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError, Net::HTTPBadResponse,
           Net::HTTPHeaderSyntaxError, Net::ProtocolError, Errno::ECONNREFUSED => e
      critical e
    resuce Net::HTTPUnauthorized
      critical "Unauthorized to check sensu-api health!"
    end

    if json_valid?(res.body)
      json = JSON.parse(res.body)
      if json['transport']['keepalives']['messages'] > Integer(config[:keepalives])
        critical "Sensu not processing keepalives fast enough! #{json['transport']['keepalives']['messages']} keepalives queued, #{config[:keepalives]} acceptable."
      end
      if json['transport']['results']['messages'] > Integer(config[:results])
        critical "Sensu not processing results fast enough! #{json['transport']['results']['messages']} results queued, #{config[:results]} acceptable."
      end
    else
      critical 'Response contains invalid JSON'
    end

    ok
  end
end

