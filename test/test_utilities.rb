require File.dirname(__FILE__) + '/helper.rb'

class TestUtilities < Test::Unit::TestCase

    def test_compute_required_checksum
        for number in 0..256
            payload = []
            checksum = Mindset.compute_required_checksum(payload.fill(0, number){|index| number})
            payload_sum = payload.inject {|sum, n| sum + n }
            assert(checksum, Mindset.compute_actual_checksum(payload_sum))
        end
    end
    
    def test_to_int24
        assert(0, [0, 0, 0])
        assert(0xFF, [0, 0, 0xFF])
        assert(0xFF00, [0, 0xFF, 0])
        assert(0xFF0000, [0xFF, 0, 0])
    end
    
    def test_s16_to_int
        assert(0, [0, 0])
        assert(1, [0, 1])
        assert(-1, [0xFF, 0xFF])
        assert(32767, [0x7F, 0xFF])
        assert(-32768, [0x80, 0x00])
    end
    
    def test_streamparser
        stream = mock()
        parser = mock()

        stream.expects(:read).returns([])

        assert_raise_message([RuntimeError], /stream has dried up/) {
            Mindset::StreamParser.parse(stream, parser)
        }

        stream.expects(:read).returns([111]).then.returns([]).times(2)
        parser.expects(:new_byte).with(111)

        assert_raise_message([RuntimeError], /stream has dried up/) {
            Mindset::StreamParser.parse(stream, parser)
        }
        
        stream.expects(:read).returns([111, 222]).then.returns([]).times(2)
        parser.expects(:new_byte).with(111)
        parser.expects(:new_byte).with(222)

        assert_raise_message([RuntimeError], /stream has dried up/) {
            Mindset::StreamParser.parse(stream, parser)
        }
    end
    
end
