require 'rubygems'
require 'state_machine'
require 'mindset/constants'
require 'mindset/buffered_stream'

module Mindset

    class ByteParser
    
        attr_reader :payload
    
        def initialize(payload_parser)
            @payload_parser = payload_parser
            super()
        end
    
        state_machine :state, :initial => :waiting_for_sync_byte do
    
            after_transition :waiting_for_payload_length => :waiting_for_payload,   :do => :reset_payload
            after_transition :waiting_for_checksum       => :waiting_for_sync_byte, :do => :analyze_payload
    
            event :new_byte do
                transition :waiting_for_sync_byte        => :waiting_for_second_sync_byte, :if => :sync_byte?
                transition :waiting_for_second_sync_byte => :waiting_for_payload_length,   :if => :sync_byte?
                transition :waiting_for_second_sync_byte => :waiting_for_sync_byte,        :if => :non_sync_byte?
                transition :waiting_for_payload_length   => :waiting_for_sync_byte,        :if => :sync_byte_or_higher?
                transition :waiting_for_payload_length   => :waiting_for_payload,          :unless => :sync_byte_or_higher?
                transition :waiting_for_payload          => same,                          :unless => :payload_complete
                transition :waiting_for_payload          => :waiting_for_checksum,         :if => :payload_complete?
                transition :waiting_for_checksum         => :waiting_for_sync_byte
            end
        end
        
        def new_byte(*args)
            @byte = args[0]
            raise("not a byte: #{@byte}") if @byte > 255
            super
            self
        end
        
        def reset_payload
            @payload = []
            @pay_load_length = @byte
            @pay_load_sum = 0
        end
        
        def received_payload
            @payload << @byte
            @pay_load_sum = (@pay_load_sum + @byte) & 0xFF
        end
        
        def analyze_payload
            if @byte == Mindset.compute_actual_checksum(@pay_load_sum)
                @payload_parser.parse(@payload)
            end
        end
    
        def sync_byte?
            @byte == Parser_sync_byte
        end
        
        def non_sync_byte?
            @byte != Parser_sync_byte
        end
        
        def sync_byte_or_higher?
            @byte >= Parser_sync_byte
        end
        
        def payload_complete
            received_payload()
            payload_complete?
        end
    
        def payload_complete?
            @payload.length >= @pay_load_length
        end
    end

end
