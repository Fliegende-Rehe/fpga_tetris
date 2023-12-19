// Module: draw_field_helper
// This module is responsible for calculating the positions of bricks in a field,
// and determining if a given pixel is inside a brick or the field.
module draw_field_helper
#( 
  // Parameters for pixel and brick dimensions, and count of bricks
  parameter PIX_WIDTH = 12,
  parameter BRICK_X   = 20, // Width of a single brick
  parameter BRICK_Y   = 25, // Height of a single brick
  parameter BRICK_X_CNT = 10, // Number of bricks horizontally
  parameter BRICK_Y_CNT = 20, // Number of bricks vertically
  parameter BORDER_X    = 2, // Horizontal border width
  parameter BORDER_Y    = 2  // Vertical border width
)
(
  // Inputs and Outputs
  input                                  clk_i, // Clock input

  // Starting x and y coordinates for the field
  input  [PIX_WIDTH-1:0]                 start_x_i,
  input  [PIX_WIDTH-1:0]                 start_y_i,

  // Calculated end x and y coordinates for the field
  output [PIX_WIDTH-1:0]                 end_x_o,
  output [PIX_WIDTH-1:0]                 end_y_o,

  // Current pixel coordinates being processed
  input  [PIX_WIDTH-1:0]                 pix_x_i,
  input  [PIX_WIDTH-1:0]                 pix_y_i,

  // Outputs to indicate if the current pixel is within a brick or the field
  output logic                           in_field_o,
  output logic                           in_brick_o,

  // Outputs for the column and row number of the brick
  output logic [$clog2(BRICK_X_CNT)-1:0] brick_col_num_o,
  output logic [$clog2(BRICK_Y_CNT)-1:0] brick_row_num_o
);

// Calculating the end coordinates of the field
assign end_x_o = start_x_i + BORDER_X * ( BRICK_X_CNT + 1 ) + BRICK_X * BRICK_X_CNT - 1;
assign end_y_o = start_y_i + BORDER_Y * ( BRICK_Y_CNT + 1 ) + BRICK_Y * BRICK_Y_CNT - 1;

// Declarations for arrays to store starting and ending pixel coordinates of each column and row
logic [BRICK_X_CNT-1:0][PIX_WIDTH-1:0] col_pix_start;
logic [BRICK_X_CNT-1:0][PIX_WIDTH-1:0] col_pix_end;
logic [BRICK_Y_CNT-1:0][PIX_WIDTH-1:0] row_pix_start;
logic [BRICK_Y_CNT-1:0][PIX_WIDTH-1:0] row_pix_end;

// Generate loops to calculate the start and end coordinates for each brick
genvar g;
generate
  for( g = 0; g < BRICK_X_CNT; g++ )
    begin : g_col_pix
      assign col_pix_start[g] = ( g + 1 ) * BORDER_X + g * BRICK_X;
      assign col_pix_end[g]   = col_pix_start[g] + BRICK_X - 1'd1;
    end
endgenerate

generate
  for( g = 0 ; g < BRICK_Y_CNT; g++ )
    begin : g_row_pix
      assign row_pix_start[g] = ( g + 1 ) * BORDER_Y + g * BRICK_Y;
      assign row_pix_end[g]   = row_pix_start[g] + BRICK_Y - 1'd1;
    end
endgenerate

// Variables for calculating the brick's row and column number
logic [$clog2( BRICK_X_CNT )-1:0] brick_col_num;
logic [$clog2( BRICK_Y_CNT )-1:0] brick_row_num;

// Variables to check if the current pixel is within a brick column or row
logic                             in_brick_col;
logic                             in_brick_row;

// Variables to adjust the pixel coordinates relative to the field
logic [PIX_WIDTH-1:0] in_field_pix_x;
logic [PIX_WIDTH-1:0] in_field_pix_y;

// Adjust the pixel coordinates relative to the start of the field
assign in_field_pix_x = pix_x_i - start_x_i;
assign in_field_pix_y = pix_y_i - start_y_i;

// Combinational logic to determine if the current pixel is within any brick column
always_comb
  begin
    brick_col_num = '0;
    in_brick_col  = 1'b0;

    for( int i = 0; i < BRICK_X_CNT; i++ )
      begin
        if( ( in_field_pix_x >= col_pix_start[i] ) && 
            ( in_field_pix_x <= col_pix_end[i]   ) )
          begin
            brick_col_num = i;
            in_brick_col  = 1'b1;
          end
      end
  end

// Combinational logic to determine if the current pixel is within any brick row
always_comb
  begin
    brick_row_num = '0;
    in_brick_row  = 1'b0;

    for( int i = 0; i < BRICK_Y_CNT; i++ )
      begin
        if( ( in_field_pix_y >= row_pix_start[i] ) && 
            ( in_field_pix_y <= row_pix_end[i] ) )
          begin
            brick_row_num = i;
            in_brick_row  = 1'b1;
          end
      end
  end

// Sequential logic to update output signals on each clock cycle
always_ff @( posedge clk_i )
  begin
    // Determine if the current pixel is within the field boundaries
    in_field_o  <= ( pix_x_i >= start_x_i ) && ( pix_x_i <= end_x_o ) &&
                  ( pix_y_i >= start_y_i ) && ( pix_y_i <= end_y_o );

    // Determine if the current pixel is within a brick
    in_brick_o  <=  in_brick_col && in_brick_row;

    // Update the brick column and row number outputs
    brick_col_num_o <= brick_col_num;
    brick_row_num_o <= brick_row_num;
  end

endmodule
