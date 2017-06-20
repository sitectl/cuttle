#! /usr/bin/env ruby
#
#   check-dir-new-files
#
# DESCRIPTION:
#   Checks the number of specific files in a directory
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux, BSD
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   Copyright 2014 Sonian, Inc. and contributors. <support@sensuapp.org>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'fileutils'
require 'time'

class DirCount < Sensu::Plugin::Check::CLI
  BASE_DIR = '/var/cache/sensu/check-dir-new-files'
  
  option :directory,
         description: 'Directory to count files in',
         short: '-d DIR',
         long: '--dir DIR',
		 default: '/var/crash'

  option :filename_pattern,
         description: 'filename patten to match',
         short: '-p PATTERN',
         long: '--pattern PATTERN',
		 default: '*.crash'

  option :criticality,
         description: "Set sensu alert level, default is critical",
         short: '-z CRITICALITY',
         long: '--criticality CRITICALITY',
         default: 'critical'

  def getLastCheckTime()
    begin
        @last_check_time = 0
        @state_file = File.join(BASE_DIR,config[:directory].gsub('/','_'),config[:filename_pattern])
        File.open(@state_file, "r") do |file|
            file.flock(File::LOCK_SH)
            @last_check_time = file.readline.to_i
        end
    rescue
        return
    end
  end
  
  def setLastCheckTime()
    begin
        FileUtils.mkdir_p(File.dirname(@state_file))
        File.open(@state_file, File::RDWR|File::CREAT, 0644) do |file|
            file.flock(File::LOCK_EX)
            file.truncate(0)
            file.write(Time.now.to_i)
        end
    rescue
        return
    end
  end

  def run
    
	getLastCheckTime()
	
	file_count = 0
	
    begin
        Dir.chdir(config[:directory])
        Dir.glob(config[:filename_pattern]).each {|file| file_count += 1 if File.mtime(file) >= Time.at(@last_check_time)}
    rescue Exception => e
	    puts e
        unknown "Error listing files in #{config[:directory]}"
    end
	
	setLastCheckTime()
	
	msg = "#{file_count} new file(s) like #{config[:filename_pattern]} created at #{config[:directory]}."
	
	ok msg if file_count == 0
	warning msg if config[:criticality] == "warning"
	critical msg

  end
end

