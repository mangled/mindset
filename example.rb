# This pulls all the code together - You will need to plug-in your own
# device address and correct channel
#
# TODO: Explain how to do this!
#
require File.dirname(__FILE__) + '/lib/mindset'

find_mindset = false
use_mock_mindset = true

if find_mindset
    # Discover your mindset - It must be in pairing mode
    puts Mindset::Device.scan
else
    address = "00:13:EF:00:4B:46"
    channel = 3 # Give some help
        
    device = if use_mock_mindset
        mock = Mindset::MockDevice.new(1024, true)
        mock.queue_event_attention(22)
        mock
    else
        Mindset::Device.new()
    end

    # Create the stream parser and payload parser (with the default logger)
    parser = Mindset::ByteParser.new(Mindset::PayloadParser.new(Mindset::EventLogger.new))

    # Parse the stream
    device.listen(address, channel) do |device|
        Mindset::StreamParser.parse(device, parser)
    end
end
