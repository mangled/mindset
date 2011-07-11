module Mindset

    class PayloadParser
        def initialize(event_handler = nil)
            @event_handler = event_handler
        end
        
        def parse(payload)
            while(!payload.empty?)
                length = payload.length
                payload = payload.drop_while {|byte| byte == Parser_excode_byte }
                extended_code_level = length - payload.length
                code = payload.shift
                if code >= 0x80
                    handle_multi_byte_value(extended_code_level, code, payload.shift(payload.shift))
                else
                    handle_single_byte_value(code, payload.shift(1))
                end
            end
        end
        
        def handle_single_byte_value(code, value)
            code = Parser_code_raw_signal if code == Parser_code_8bitraw_signal
            @event_handler.event(code, value[0]) if @event_handler
        end
    
        def handle_multi_byte_value(extended_code_level, code, data)
            return unless @event_handler
            case code
            when Parser_code_raw_signal
                raise("Invalid length") if data.length != 2
                @event_handler.event(code, Mindset.s16_to_int(data))
            when Parser_code_eeg_powers
                # No documentation from Neurosky at the time of writing
                @event_handler.event(code, "not parsed in this version")
            when Parser_code_asic_eeg_power_int
                raise("Invalid length") if data.length != (3 * 8)
                powers = {
                    :delta      => Mindset.to_int24(data.shift(3)),
                    :theta      => Mindset.to_int24(data.shift(3)),
                    :low_alpha  => Mindset.to_int24(data.shift(3)),
                    :high_alpha => Mindset.to_int24(data.shift(3)),
                    :low_beta   => Mindset.to_int24(data.shift(3)),
                    :high_beta  => Mindset.to_int24(data.shift(3)),
                    :low_gamma  => Mindset.to_int24(data.shift(3)),
                    :mid_gamma  => Mindset.to_int24(data.shift(3))
                }
                raise("logic error") unless data.empty?
                @event_handler.event(code, powers)
            end
        end
    end
end
