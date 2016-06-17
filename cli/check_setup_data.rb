#!/usr/bin/env ruby

require_relative './../app/lib/setup_data_checker'

def fail; 1; end

def show_use(message = '')
  STDERR.puts
  STDERR.puts 'USE: check_setup_data.rb PATH'
  STDERR.puts
  STDERR.puts 'Checks PATH is suitable to create a cyber-dojo volume from.'
  STDERR.puts
  STDERR.puts "   ERROR: #{message}" if message != ''
  STDERR.puts
end

path = ARGV[0]

if path.nil?
  show_use
  exit fail
end

if !File.directory?(path)
  show_use "#{path} not found"
  exit fail
end

checker = SetupDataChecker.new(path)
count = 0
checker.check.each do |filename, messages|
  count += messages.size
  messages.each { |message| STDERR.puts filename + ': ' + message }
end

exit count