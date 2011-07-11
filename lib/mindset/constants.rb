module Mindset
    # ARE all of these used?
    Parser_code_battery =           0x01
    Parser_code_poor_quality =      0x02
    Parser_code_attention =         0x04
    Parser_code_meditation =        0x05
    Parser_code_8bitraw_signal =    0x06
    Parser_code_raw_marker =        0x07
    
    Parser_code_raw_signal =         0x80
    Parser_code_eeg_powers =         0x81
    Parser_code_asic_eeg_power_int = 0x83
    
    Parser_state_null =           0x00  # null state
    Parser_state_sync =           0x01  # waiting for sync byte
    Parser_state_sync_check =     0x02  # waiting for second sync byte
    Parser_state_payload_length = 0x03  # waiting for payload[] length
    Parser_state_payload =        0x04  # waiting for next payload[] byte
    Parser_state_chksum =         0x05  # waiting for chksum byte
    Parser_state_wait_high =      0x06  # waiting for high byte
    Parser_state_wait_low =       0x07  # high r'cvd.  expecting low part
    Parser_sync_byte =            0xaa  # syncronization byte
    Parser_excode_byte =          0x55  # extended code level byte
end