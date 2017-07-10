#!/usr/bin/env /opt/sensu/embedded/bin/ruby
#
# Check Kernel boot options
# ===
#
# This plugin checks that the running kernel has been booted with the specified
# kernel options
#
# Copyright 2014 Dustin Lundquist <dlundquist@bluebox.net>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'timeout'
require 'socket'

class CheckKernelOptions < Sensu::Plugin::Check::CLI

  def run
    kernel_cmd_line = File::open('/proc/cmdline', 'r'){ |io| io.read }

    [
        'consoleblank=0',
        /console=ttyS\d+,115200n8/
    ].each do |option|
        warning "Kernel booted without #{option}" unless kernel_cmd_line.match(option)
    end

    ok "Kernel boot options appear good"
  end

end
