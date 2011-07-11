require File.dirname(__FILE__) + '/helper.rb'

# Tests mainly that the stream repeating logic functions
class TestMockDevice < Test::Unit::TestCase
    
    def test_packing
        [1, 2, 4, 9, 17, 100, 2000].each do |packet_size|
            device = Mindset::MockDevice.new(packet_size, repeat = false)
            assert_stream(device, make_expectations(device), packet_size, repeat)
            
            device = Mindset::MockDevice.new(packet_size, repeat = true)
            assert_stream(device, make_expectations(device), packet_size, repeat)
        end
    end

    def make_expectations(device)
        battery_value = device.queue_event_battery(123)
        poor_quality_value = device.queue_event_poor_quality(34)
        attention_value = device.queue_event_attention(12)
        meditation_value = device.queue_event_meditation(99)
        raw_marker_value = device.queue_event_raw_marker(26)
        signal_8bit_value = device.queue_event_raw_8_bit_signal(23)
        signal_16bit_value = device.queue_event_raw_16_bit_signal(-1)
        
        powers = { :delta => 1, :theta => 2, :low_alpha => 3, :high_alpha => 4, :low_beta => 5, :high_beta => 6, :low_gamma => 7, :mid_gamma => 8}
        device.queue_event_asic_eeg_power(powers)

        expected_bytes = []
        expected_bytes.concat(make_8_bit_expectation(Mindset::Parser_code_battery, battery_value))
        expected_bytes.concat(make_8_bit_expectation(Mindset::Parser_code_poor_quality, poor_quality_value))
        expected_bytes.concat(make_8_bit_expectation(Mindset::Parser_code_attention, attention_value))
        expected_bytes.concat(make_8_bit_expectation(Mindset::Parser_code_meditation, meditation_value))
        expected_bytes.concat(make_8_bit_expectation(Mindset::Parser_code_raw_marker, raw_marker_value))
        expected_bytes.concat(make_8_bit_expectation(Mindset::Parser_code_8bitraw_signal, signal_8bit_value))
        expected_bytes.concat(make_16_bit_expectation(Mindset::Parser_code_raw_signal, signal_16bit_value))
        expected_bytes.concat(make_asic_eeg_power_expectation(powers))
        expected_bytes
    end

    def make_8_bit_expectation(code, value)
        [
            Mindset::Parser_sync_byte,
            Mindset::Parser_sync_byte,
            2,
            code,
            value,
            Mindset.compute_required_checksum([code, value])
        ]
    end
    
    def make_16_bit_expectation(code, value)
        packed_values = [(value & 0xFF00) >> 8, (value & 0xFF)]
        [
            Mindset::Parser_sync_byte,
            Mindset::Parser_sync_byte,
            3,
            code,
            packed_values[0],
            packed_values[1],
            Mindset.compute_required_checksum([code].concat(packed_values))
        ]
    end
    
    def make_asic_eeg_power_expectation(values)
        # Ordering is important
        keys = [:delta, :theta, :low_alpha, :high_alpha, :low_beta, :high_beta, :low_gamma, :mid_gamma]
        powers = keys.collect{|key| [(values[key] & 0xFF0000) >> 16, (values[key] & 0xFF00) >> 8, values[key] & 0xFF]}
        packed_values = []
        powers.each {|power| packed_values.concat(power) }
        [
            Mindset::Parser_sync_byte,
            Mindset::Parser_sync_byte,
            25,
            Mindset::Parser_code_asic_eeg_power_int
        ].concat(packed_values) << Mindset.compute_required_checksum([Mindset::Parser_code_asic_eeg_power_int].concat(packed_values))
    end

    def assert_stream(device, expected_bytes, packet_size, repeat)
        packets_required = expected_bytes.length / packet_size
        packets_required += 1 if packets_required * packet_size < expected_bytes.length

        if repeat
            for packet in 0..(3 * packets_required)
                bytes = device.read
                if expected_bytes.length < packet_size
                    assert(expected_bytes.length >= bytes.length)
                else
                    assert_equal(packet_size, bytes.length)
                end
                assert_equal(expected_bytes[0, packet_size], bytes, "packet size #{packet_size}")
                if expected_bytes.respond_to?(:rotate)
                    expected_bytes.rotate(packet_size)
                else
                    expected_bytes.concat(expected_bytes.shift(packet_size))
                end
            end
        else
            for packet in 0..packets_required
                bytes = device.read
                assert(packet_size >= bytes.length)
                assert_equal(expected_bytes.shift(bytes.length), bytes)
            end
            assert_equal([], device.read)
            assert_equal([], device.read)
        end
    end
    
end
