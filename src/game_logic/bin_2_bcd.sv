module bin_2_bcd
#( 
  parameter BIN_WIDTH = 8,    // Input binary width (default is 8 bits)
  parameter BCD_WIDTH = 3    // Output BCD width (default is 3 digits) (Binary-Coded Decimal)
)
(
  input        [BIN_WIDTH-1:0]      bin_i,  // Binary input
  output logic [BCD_WIDTH-1:0][3:0] bcd_o  // BCD output
);

always_comb
  begin
    bcd_o = '0;  // Initialize BCD output to zero

    for( int b = BIN_WIDTH - 1; b >= 0; b-- )
      begin
        for( int bcd = 0; bcd < BCD_WIDTH; bcd++ )
          begin
            // Check if BCD digit is greater than or equal to 5, then add 3 to it
            if( bcd_o[ bcd ] >= 4'd5 )
              bcd_o[ bcd ] += 4'd3;
          end

        for( int bcd = BCD_WIDTH - 1; bcd >= 0; bcd-- )
          begin
            // Shift the BCD digit left by one position
            bcd_o[ bcd ]    = bcd_o[ bcd ] << 1;

            // Set the least significant bit of the BCD digit based on the binary input
            if( bcd == 0 )
              bcd_o[ bcd ][0] = bin_i[ b ];
            else
              bcd_o[ bcd ][0] = bcd_o[ bcd - 1 ][3]; // Carry over from the previous BCD digit
          end
      end
  end
endmodule
