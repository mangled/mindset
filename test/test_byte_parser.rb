require File.dirname(__FILE__) + '/helper.rb'

class TestByteParser < Test::Unit::TestCase

    def setup
        @payload_parser = mock()
        @parser = Mindset::ByteParser.new(@payload_parser)
    end
    
    def test_not_a_byte
        assert_raise_message([RuntimeError], /not a byte: 256/) { @parser.new_byte(256) }
    end
    
    def test_initial_state
        assert_equal("waiting_for_sync_byte", @parser.state, "initial state")
    end
    
    def test_waiting_for_sync_byte
        @parser.state = "waiting_for_sync_byte"
        for byte in 0..255
            assert_equal("waiting_for_sync_byte", @parser.new_byte(byte).state) if byte != Mindset::Parser_sync_byte
        end
        assert_equal("waiting_for_second_sync_byte", @parser.new_byte(Mindset::Parser_sync_byte).state)
    end
    
    def test_waiting_for_second_sync_byte
        for byte in 0..255
            @parser.state = "waiting_for_second_sync_byte"
            assert_equal("waiting_for_sync_byte", @parser.new_byte(byte).state) if byte != Mindset::Parser_sync_byte
        end

        @parser.state = "waiting_for_second_sync_byte"
        assert_equal("waiting_for_payload_length", @parser.new_byte(Mindset::Parser_sync_byte).state)
    end

    def test_waiting_for_payload_length
        for byte in 0..(Mindset::Parser_sync_byte - 1)
            @parser.state = "waiting_for_payload_length"
            assert_equal("waiting_for_payload", @parser.new_byte(byte).state)
        end
        for byte in Mindset::Parser_sync_byte..255
            @parser.state = "waiting_for_payload_length"
            assert_equal("waiting_for_sync_byte", @parser.new_byte(byte).state)
        end
    end
    
    def test_waiting_for_payload
        set_payload(@parser, [170])
        set_payload(@parser, [170, 1, 2, 3, 88, 44, 1, 170])
    end

    def test_waiting_for_checksum
        payload = [170, 1, 2, 3, 88, 44, 1, 170]
        set_payload(@parser, payload)
        assert_equal("waiting_for_sync_byte", @parser.new_byte(Mindset.compute_required_checksum(payload) + 1).state)

        set_payload(@parser, payload)
        @payload_parser.expects(:parse).with(payload)
        assert_equal("waiting_for_sync_byte", @parser.new_byte(Mindset.compute_required_checksum(payload)).state)
    end
    
    def test_mock_device
        # A quick double check that the mock device and the parser "agree" with each other
        device = Mindset::MockDevice.new()
        device.queue_event_meditation(88)
        device.queue_event_raw_16_bit_signal(256)
        
        @payload_parser.expects(:parse).with([Mindset::Parser_code_meditation, 88])
        @payload_parser.expects(:parse).with([Mindset::Parser_code_raw_signal, 1, 0])
        
        bytes =  device.read # default of 1024 should pull whole stream
        bytes.each {|byte| @parser.new_byte(byte) }
        
        assert("waiting_for_sync_byte", @parser.state)
    end

    def set_payload(parser, payload)
        parser.state = "waiting_for_payload_length"
        parser.new_byte(payload.length)
        payload.each {|byte| parser.new_byte(byte) }
        assert_equal("waiting_for_checksum", parser.state)
        assert_equal(payload.length, parser.payload.length)
        assert_equal(payload, parser.payload)
    end

end
