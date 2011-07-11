$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

$:.unshift File.dirname(__FILE__) + "/../ext/mindset_device" unless
  $:.include?(File.dirname(__FILE__) + "/../ext/mindset_device") ||
  $:.include?(File.expand_path(File.dirname(__FILE__) + "/../ext/mindset_device"))

begin
  require "mindset_device.so"
rescue LoadError
  puts "warning: mindset_device.so not found"
end

require 'mindset/constants'
require 'mindset/buffered_stream'
require 'mindset/byte_parser'
require 'mindset/payload_parser'
require 'mindset/event_logger'
require 'mindset/mock_device'
require 'mindset/utilities'
