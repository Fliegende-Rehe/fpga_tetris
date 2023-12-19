// Include definitions file for constants and data types
`include "defs.vh"

// Module definition for drawing a field in a game (e.g., Tetris)
module draw_field
#( 
  parameter PIX_WIDTH = 12 // Parameter for pixel width
)
(
  input clk_i, // Clock input

  input [PIX_WIDTH-1:0] pix_x_i, // Current pixel's X-coordinate
  input [PIX_WIDTH-1:0] pix_y_i, // Current pixel's Y-coordinate
  
  input game_data_t game_data_i, // Input game data structure

  output [23:0] vga_data_o, // Output VGA data (color)
  output vga_data_en_o // Output enable signal for VGA data
);

// Constants for brick and border dimensions, and field start positions
localparam BRICK_X = 30;
localparam BRICK_Y = 30;
localparam BORDER_X = 2;
localparam BORDER_Y = 2;
localparam START_MAIN_FIELD_X = 300;
localparam START_MAIN_FIELD_Y = 200;

// Variables for main field calculations
logic [$clog2(`FIELD_COL_CNT)-1:0] main_field_col_num;
logic [$clog2(`FIELD_ROW_CNT)-1:0] main_field_row_num;
logic main_field_in_field;
logic main_field_in_brick;
logic [PIX_WIDTH-1:0] main_field_end_x;
logic [PIX_WIDTH-1:0] main_field_end_y;

// Instance of draw_field_helper for main game field
draw_field_helper
#( 
  .PIX_WIDTH ( PIX_WIDTH ), 

  .BRICK_X ( BRICK_X ),
  .BRICK_Y ( BRICK_Y ),

  .BRICK_X_CNT ( `FIELD_COL_CNT ),
  .BRICK_Y_CNT ( `FIELD_ROW_CNT ),

  .BORDER_X ( BORDER_X ),
  .BORDER_Y ( BORDER_Y )
) main_field (
  .clk_i ( clk_i ),

  .start_x_i ( START_MAIN_FIELD_X ),
  .start_y_i ( START_MAIN_FIELD_Y ),

  .end_x_o ( main_field_end_x ),
  .end_y_o ( main_field_end_y ),

  // Current pixel values
  .pix_x_i ( pix_x_i ),
  .pix_y_i ( pix_y_i ),

  .in_field_o ( main_field_in_field ),
  .in_brick_o ( main_field_in_brick ),

  .brick_col_num_o ( main_field_col_num ),
  .brick_row_num_o ( main_field_row_num )
);

// Constants for Next Block Preview (NBP)
localparam NBP_BRICK_CNT = 6;
logic [PIX_WIDTH-1:0] nbp_field_start_x;
logic [PIX_WIDTH-1:0] nbp_field_start_y;

// Assign initial positions for NBP field
assign nbp_field_start_x = 'd670;
assign nbp_field_start_y = START_MAIN_FIELD_Y;

// Variables for NBP field calculations
logic [$clog2(NBP_BRICK_CNT)-1:0]  nbp_field_col_num;
logic [$clog2(NBP_BRICK_CNT)-1:0]  nbp_field_row_num;
logic nbp_field_in_field;
logic nbp_field_in_brick;

// Instance of draw_field_helper for Next Block Preview (NBP) field
draw_field_helper
#( 
  .PIX_WIDTH ( PIX_WIDTH ), 

  .BRICK_X ( BRICK_X ),
  .BRICK_Y ( BRICK_Y ),

  .BRICK_X_CNT ( NBP_BRICK_CNT ),
  .BRICK_Y_CNT ( NBP_BRICK_CNT ),

  .BORDER_X ( BORDER_X ),
  .BORDER_Y ( BORDER_Y )
) draw_nbp_field (
  .clk_i ( clk_i ),

  .start_x_i ( nbp_field_start_x ),
  .start_y_i ( nbp_field_start_y ),

  .end_x_o ( ),
  .end_y_o ( ),

  // Current pixel values
  .pix_x_i ( pix_x_i ),
  .pix_y_i ( pix_y_i ),

  .in_field_o ( nbp_field_in_field ),
  .in_brick_o ( nbp_field_in_brick ),

  .brick_col_num_o ( nbp_field_col_num ),
  .brick_row_num_o ( nbp_field_row_num )
);

// Definition of a 3D array to represent the Next Block Preview (NBP) field
logic [NBP_BRICK_CNT-1:0][NBP_BRICK_CNT-1:0][`TETRIS_COLORS_CNT-1:0] nbp_field;

// Definition of a 2D array for storing the data of the next block
logic [0:3][0:3] nbp_block_data;

// Assign the data of the next block from game_data_i to nbp_block_data based on its rotation
assign nbp_block_data = game_data_i.next_block.data[ game_data_i.next_block.rotation ];

// Combinational logic to update the NBP field based on the next block data
always_comb
  begin
    for( int i = 0; i < NBP_BRICK_CNT; i++ )
      begin
        for( int j = 0; j < NBP_BRICK_CNT; j++ )
          begin
            if( ( i == 0 ) || ( j == 0 ) ||
                ( i == ( NBP_BRICK_CNT - 1 ) ) || ( j == ( NBP_BRICK_CNT - 1 ) ) )
              begin
                // If the current position is at the border, set it to 'd0 (no color)
                nbp_field[i][j] = 'd0;
              end
            else
              begin
                // If the current position is within the block and the next block draw is enabled,
                // set the color of the NBP field to the color of the next block, otherwise set it to 'd0
                if( nbp_block_data[i-1][j-1] && game_data_i.next_block_draw_en ) 
                  nbp_field[i][j] = game_data_i.next_block.color;  
                else
                  nbp_field[i][j] = 'd0;
              end
          end
      end
  end

// Definition of VGA data signal
logic [23:0] vga_data;

// Definition of an array to map Tetris colors to VGA colors
logic [`TETRIS_COLORS_CNT-1:0][23:0] vga_colors_pos;

// Assign VGA color values for each Tetris color
assign vga_colors_pos[0] = `COLOR_BRICKS_0;
assign vga_colors_pos[1] = `COLOR_BRICKS_1;
assign vga_colors_pos[2] = `COLOR_BRICKS_2;
assign vga_colors_pos[3] = `COLOR_BRICKS_3;
assign vga_colors_pos[4] = `COLOR_BRICKS_4;
assign vga_colors_pos[5] = `COLOR_BRICKS_5;
assign vga_colors_pos[6] = `COLOR_BRICKS_6;
assign vga_colors_pos[7] = `COLOR_BRICKS_7;

// Combinational logic to determine the VGA data based on game state
always_comb
  begin
    vga_data = `COLOR_BORDERS;
    
    if( main_field_in_field )
      begin
        if( main_field_in_brick )
          begin
            // If the current pixel is within the main field and a brick, set VGA data to the color of the brick
            vga_data = vga_colors_pos[ game_data_i.field[ main_field_row_num ][ main_field_col_num ] ]; 
          end
      end
    else
      if( nbp_field_in_field )
        begin
          if( nbp_field_in_brick )
            begin
              // If the current pixel is within the NBP field and a brick, set VGA data to the color of the NBP brick
              vga_data = vga_colors_pos[ nbp_field[ nbp_field_row_num ][ nbp_field_col_num ] ]; 
            end
        end
  end

// Assign the calculated VGA data and enable signal to the module outputs
assign vga_data_o = vga_data;
assign vga_data_en_o = main_field_in_field || nbp_field_in_field;

endmodule
