# General "utility" methods
module Mindset
    
    # Calculate the required checksum for payload
    def Mindset.compute_required_checksum(payload)
        payload_sum = payload.inject {|sum, n| sum + n }
        (payload_sum & 0xFF) ^ 0xFF
    end


    # The reverse of compute_required_checksum
    def Mindset.compute_actual_checksum(payload_sum)
        ((payload_sum ^ 0xFF) & 0xFF)
    end

    def Mindset.to_int24(data) # MSB first
        ((data[0] << 16) | (data[1] << 8) | data[2]).to_i
    end

    # Single big-endian 16-bit two's-compliment signed value (high-order byte followed by low-order byte)
    def Mindset.s16_to_int(data) # MSB first
        value = (data[0] << 8) | data[1]
        value = -((value ^ 0xFFFF) + 1) if value > 0x7FFF # 2's compliment
        value.to_i
    end

    # Helper, joins a BufferedStream to a parser
    class StreamParser
        def StreamParser.parse(stream, parser)
            buffered_stream = BufferedStream.new(stream)
            while true
                parser.new_byte(buffered_stream.read_byte)
            end
        end
    end

end
