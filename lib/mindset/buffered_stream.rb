module Mindset
    # Buffers a stream source. Used to insert a buffer between the source Device
    # and the sink.
    class BufferedStream
        def initialize(source)
            @source = source
            @buffer = []
        end
    
        def read_byte
            while (@buffer.length == 0)
                read = @source.read
                raise "stream has dried up" if read.length == 0
                @buffer = @buffer.concat(read)
            end
            value = @buffer.shift.to_i
            raise("#{value} is not a byte") if (value > 0xFF)
            value
        end
    end
end
