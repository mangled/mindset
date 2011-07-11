require 'logger'

module Mindset

    # An example event handler to pass into the PayloadParser
    class EventLogger

        def initialize(out = STDOUT)
            @log = Logger.new(out)
        end

        # PayloadParser expects an event handler to have this method
        def event(code, value)
            case code
            when Parser_code_asic_eeg_power_int
                @log.info("#{code_s(code)}")
                value.each do |signal, value|
                    @log.info("#{signal} -> #{value}")    
                end
            when Parser_code_attention, Parser_code_meditation
                @log.info("#{code_s(code)} -> #{value} (#{esense_s(value)})")
            else
                if code == Parser_code_poor_quality and value == 200
                    @log.info("#{code_s(code)} -> #{value} (not touching skin)")
                else
                    @log.info("#{code_s(code)} -> #{value}")
                end
            end
        end

        def code_s(code)
            case code
            when Parser_code_battery
                'Parser_code_battery'
            when Parser_code_poor_quality
                'Parser_code_poor_quality'
            when Parser_code_attention
                'Parser_code_attention'
            when Parser_code_meditation
                'Parser_code_meditation'
            when Parser_code_raw_marker
                'Parser_code_raw_marker'
            when Parser_code_raw_signal
                'Parser_code_raw_signal'
            when Parser_code_asic_eeg_power_int
                'Parser_code_asic_eeg_power_int'
            else
                'Unknown'
            end
        end

        def esense_s(value)
            case value
            when 0
                "Can't classify"
            when 1..20
                "Strongly Lowered"
            when 21..40
                "Reduced"
            when 41..60
                "Neutral"
            when 61..80
                "Slightly Elevated"
            else
                "Elevated"
            end
        end
        
    end
end
