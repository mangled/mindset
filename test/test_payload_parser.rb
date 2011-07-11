require File.dirname(__FILE__) + '/helper.rb'

class TestPayloadParser < Test::Unit::TestCase

    def setup
        @event_handler = mock()
        @parser = Mindset::PayloadParser.new(@event_handler)
    end
    
    def test_parse_empty
        @parser.parse([])
    end
    
    def test_parse_single_byte_value
        # Not expected i.e. this is invalid - no content!
        @event_handler.expects(:event).with(0x7F, nil)
        @parser.parse([0x7F])
        
        @event_handler.expects(:event).with(0x16, 45)
        @parser.parse([0x16, 45])
        
        @event_handler.expects(:event).with(0x78, 255)
        @parser.parse([Mindset::Parser_excode_byte, Mindset::Parser_excode_byte, 0x78, 255])
        
        @event_handler.expects(:event).with(0x16, 45)
        @event_handler.expects(:event).with(0x09, 47)
        @parser.parse([0x16, 45, 0x09, 47])
    end
    
    def test_handle_multi_byte_value_raw_signal
        assert_raise_message([RuntimeError], /Invalid length/) { @parser.parse([Mindset::Parser_code_raw_signal, 0x03, 0xFF, 0xFF, 0xFF]) }
        
        @event_handler.expects(:event).with(Mindset::Parser_code_raw_signal, -1)
        @parser.parse([Mindset::Parser_code_raw_signal, 0x02, 0xFF, 0xFF])
        @event_handler.expects(:event).with(Mindset::Parser_code_raw_signal, -32768)
        @parser.parse([Mindset::Parser_code_raw_signal, 0x02, 0x80, 0x00])
        @event_handler.expects(:event).with(Mindset::Parser_code_raw_signal,  1)
        @parser.parse([Mindset::Parser_code_raw_signal, 0x02, 0x00, 0x01])
        @event_handler.expects(:event).with(Mindset::Parser_code_raw_signal,  32767)
        @parser.parse([Mindset::Parser_code_raw_signal, 0x02, 0x7F, 0xFF])
        
        payload = [Mindset::Parser_code_raw_signal, 0x02, 0xFF, 0xFF]
        @event_handler.expects(:event).with(Mindset::Parser_code_raw_signal,  -1)
        @event_handler.expects(:event).with(Mindset::Parser_code_raw_signal,  -1)
        @parser.parse(payload + payload)
    end

    def test_handle_multi_byte_value_eeg_power_int
        assert_raise_message([RuntimeError], /Invalid length/) { @parser.parse([Mindset::Parser_code_asic_eeg_power_int, 0x03, 0xFF, 0xFF, 0xFF]) }
        
        payload = [Mindset::Parser_code_asic_eeg_power_int, 24]
        payload.concat(unpack_to_24_bit(1)) # :delta
        payload.concat(unpack_to_24_bit(2)) # :theta
        payload.concat(unpack_to_24_bit(3)) # :low_alpha
        payload.concat(unpack_to_24_bit(4)) # :high_alpha
        payload.concat(unpack_to_24_bit(5)) # :low_beta
        payload.concat(unpack_to_24_bit(6)) # :high_beta
        payload.concat(unpack_to_24_bit(7)) # :low_gamma
        payload.concat(unpack_to_24_bit(8)) # :mid_gamma
        @event_handler.expects(:event).with(Mindset::Parser_code_asic_eeg_power_int,
            { :delta      => 1, :theta     => 2, :low_alpha => 3,
              :high_alpha => 4, :low_beta  => 5, :high_beta => 6,
              :low_gamma  => 7, :mid_gamma => 8
            }
        )
        @parser.parse(payload)
        
        payload = [Mindset::Parser_code_asic_eeg_power_int, 24]
        payload.concat(unpack_to_24_bit(0xFFFFFF)) # :delta
        payload.concat(unpack_to_24_bit(0xFFFFFF)) # :theta
        payload.concat(unpack_to_24_bit(0xFFFFFF)) # :low_alpha
        payload.concat(unpack_to_24_bit(0xFFFFFF)) # :high_alpha
        payload.concat(unpack_to_24_bit(0x00FFFF)) # :low_beta
        payload.concat(unpack_to_24_bit(0xFFFFFF)) # :high_beta
        payload.concat(unpack_to_24_bit(0xFFFFFF)) # :low_gamma
        payload.concat(unpack_to_24_bit(0x0000FF)) # :mid_gamma
        @event_handler.expects(:event).with(Mindset::Parser_code_asic_eeg_power_int,
            { :delta      => 0xFFFFFF, :theta     => 0xFFFFFF, :low_alpha => 0xFFFFFF,
              :high_alpha => 0xFFFFFF, :low_beta  => 0x00FFFF, :high_beta => 0xFFFFFF,
              :low_gamma  => 0xFFFFFF, :mid_gamma => 0x0000FF
            }
        )
        @parser.parse(payload)
    end
    
    def test_handle_multi_byte_value_eeg_powers
        @event_handler.expects(:event).with(Mindset::Parser_code_eeg_powers, "not parsed in this version")
        @parser.parse([Mindset::Parser_code_eeg_powers, 1])
    end

    def unpack_to_24_bit(value)
        [(value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF]
    end

end
