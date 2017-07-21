#!/opt/sensu/embedded/bin/ruby
#
#   check-serverspec
#
# DESCRIPTION:
#   Runs http://serverspec.org/ spec tests against your servers.
#   Fails with a warning or a critical if tests are failing, depending
#     on the severity level set.
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
#   gem: socket
#   gem: serverspec
#
# USAGE:
#   Run entire suite of testd
#   check-serverspec -d /etc/my_tests_dir
#
#   Run only one set of tests
#   check-serverspec -d /etc/my_tests_dir -t spec/test_one
#
#   Run with a warning severity level
#   check-serverspec -d /etc/my_tests_dir -s warning
#
# NOTES:
#   Critical severity level is set as the default 
#
# LICENSE:
#   Copyright 2014 Sonian, Inc. and contributors. <support@sensuapp.org>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'json'
require 'socket'
require 'serverspec'


class CheckServerspec < Sensu::Plugin::Check::CLI
  option :tests_dir,
         short: '-d /tmp/dir',
         long: '--tests-dir /tmp/dir',
         required: true

  option :spec_tests,
         short: '-t spec/test',
         long: '--spec-tests spec/test',
         default: nil

  option :severity,
         short: '-s severity',
         long: '--severity severity',
         default: 'critical'

  def run
    serverspec_results = `cd #{config[:tests_dir]} ; /opt/sensu/embedded/bin/rspec #{config[:spec_tests]} --format json`
    parsed = JSON.parse(serverspec_results)
    num_failures = parsed['summary_line'].split[2]

    failures = []
    parsed['examples'].each do |serverspec_test|
      test_name = serverspec_test['file_path'].split('/')[-1]
      output = serverspec_test['full_description'].gsub!(/\"/, '')

      if serverspec_test['status'] != 'passed'
        failures << "#{serverspec_test['status'].upcase}: #{test_name}:#{serverspec_test['line_number']}, #{serverspec_test['full_description']}"
      end
    end
    str_failures = failures.join("\n")

    if num_failures != '0'
      if config[:severity] == 'warning'
        warning [parsed['summary_line'], '', str_failures].join("\n")
      else
        critical [parsed['summary_line'], '', str_failures].join("\n")
      end
    else
      ok parsed['summary_line']
    end
  end
end

