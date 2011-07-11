require File.dirname(__FILE__) + '/helper.rb'

$:.unshift File.dirname(__FILE__) + "/../ext/mindset_device"
require "mindset_device.so"

# Testing the actual device is not possible - without a headset attached
# so I have to skip unit testing this :-(
class TestMindsetDeviceExtn < Test::Unit::TestCase
    def test_one
        assert(true)
    end
end
