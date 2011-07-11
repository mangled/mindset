# A "mock" (mindset) device to allow testing of applications without needing
# to have the mindset headset connected.
#
# Note: This design seems ok for the first version. Consider changing it though
# to allow function generation e.g. sine waves
#
module Mindset
    class MockDevice
        # packet_size_bytes sets how much of the content is returned on each call to
        # read, this is a maximum, if the stream contains less than this amount then
        # only the stream length bytes are returned.
        #
        # If repeat_stream is true then the device will repeat sending its contents
        # via read
        def initialize(packet_size_bytes = 1024, repeat_stream = false)
            @packet_size_bytes = packet_size_bytes
            @repeat_stream = repeat_stream
            @stream = []
            @stream_index = 0
        end
        
        # Act like the real device, so code can be kept similar
        def listen(address, channel)
            yield self
        end

        # Returns a "stream" of bytes, this is chunked by up to @packet_size_bytes
        def read
            # Try to fetch @packet_size_bytes from @stream at the current stream index
            send_bytes = @stream[@stream_index, @packet_size_bytes]

            # If we fail to get @packet_size_bytes then try to fetch the remaining from the head of the stream
            if @repeat_stream and (send_bytes.length < @packet_size_bytes)
                # We can only fetch up to the current stream pointer i.e. the current stream content
                # may not be enough to satisfy the full packet size
                bytes_before = @stream[0, [@stream_index, @packet_size_bytes - send_bytes.length].min]
                send_bytes.concat(bytes_before)
            end
            @stream_index += send_bytes.length
            # Only wrap the index if we are repeating
            @stream_index = (@stream_index % @stream.length) if @repeat_stream
            send_bytes
        end

        def queue_event_battery(value)
            assert_8_bit(value)
            add_packet(Parser_code_battery, [value])
            value
        end

        def queue_event_poor_quality(value)
            assert_8_bit(value)
            add_packet(Parser_code_poor_quality, [value])
            value
        end

        def queue_event_attention(value)
            assert_8_bit(value)
            add_packet(Parser_code_attention, [value])
            value
        end

        def queue_event_meditation(value)
            assert_8_bit(value)
            add_packet(Parser_code_meditation, [value])
            value
        end

        def queue_event_raw_marker(value)
            assert_8_bit(value)
            add_packet(Parser_code_raw_marker, [value])
            value
        end

        def queue_event_raw_8_bit_signal(value)
            assert_8_bit(value)
            add_packet(Parser_code_8bitraw_signal, [value])
            value
        end

        def queue_event_raw_16_bit_signal(value)
            assert_16_bit(value)
            add_packet(Parser_code_raw_signal, [(value & 0xFF00) >> 8, value & 0xFF])
            value
        end

        # values is a hash with the following expected key => int 24 values
        # :delta, :theta, :low_alpha, :high_alpha, :low_beta, :high_beta, :low_gamma, :mid_gamma
        def queue_event_asic_eeg_power(powers)
            keys = [:delta, :theta, :low_alpha, :high_alpha, :low_beta, :high_beta, :low_gamma, :mid_gamma]
            payload = []
            keys.each do |key|
                power_value = powers[key]
                assert_24_bit(power_value)
                payload << ((power_value & 0xFF0000) >> 16)
                payload << ((power_value & 0x00FF00) >> 8)
                payload <<  (power_value & 0x0000FF)
            end
            add_packet(Parser_code_asic_eeg_power_int, payload)
            powers
        end

        def add_packet(code, payload)
            # No ext codes for now
            payload_length_with_code = payload.length + 1
            raise("payload too long") if payload_length_with_code >= Parser_sync_byte
            packet = [Parser_sync_byte, Parser_sync_byte, payload_length_with_code]
            packet.concat(make_payload(code, payload))
            packet << Mindset.compute_required_checksum([code].concat(payload))
            @stream.concat(packet)
        end

        # Not using extended codes
        def make_payload(code, payload)
            [code].concat(payload)
        end

        def assert_8_bit(value)
            raise("Not a byte #{value}") if value > 0xFF
        end
        
        def assert_16_bit(value)
            raise("Not a word #{value}") if value > 0xFFFF
        end
        
        def assert_24_bit(value)
            raise("Not an int value #{value}") if value > 0xFFFFFF
        end
    end
end
