require File.dirname(__FILE__) + '/helper.rb'

class TestBufferedStream < Test::Unit::TestCase

    class Stream
        def initialize(content, shift)
            @content = content
            @shift = shift
        end
        
        def read
            @content.shift(@shift)
        end
    end

    def test_empty_stream
        buffer = Mindset::BufferedStream.new(Stream.new([], 1))
        assert_raise_message([RuntimeError], /stream has dried up/) { buffer.read_byte }
    end

    def test_read
        buffer = Mindset::BufferedStream.new(Stream.new([256], 1))
        assert_raise_message([RuntimeError], /256 is not a byte/) { buffer.read_byte }
        
        buffer = Mindset::BufferedStream.new(Stream.new([1, 2, 3], 1))
        assert(1, buffer.read_byte)
        assert(2, buffer.read_byte)
        assert(3, buffer.read_byte)
        assert_raise_message([RuntimeError], /stream has dried up/) { buffer.read_byte }
        
        buffer = Mindset::BufferedStream.new(Stream.new([1, 2, 3], 3))
        assert(1, buffer.read_byte)
        assert(2, buffer.read_byte)
        assert(3, buffer.read_byte)
        assert_raise_message([RuntimeError], /stream has dried up/) { buffer.read_byte }
    end

end
