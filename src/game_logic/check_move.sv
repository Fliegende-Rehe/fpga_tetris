// Include necessary definitions
include "defs.vh"

module check_move(
  input                                                    clk_i,          // Clock input
  input                                                    run_i,          // Run signal input

  input  move_t                                            req_move_i,     // Requested move input
  input  block_info_t                                      block_i,        // Block information input
  input  [`FIELD_EXT_ROW_CNT-1:0][`FIELD_EXT_COL_CNT-1:0]  field_i,     // Field input

  output logic                                             done_o,          // Done output signal
  output logic                                             can_move_o,      // Can move output signal
  output logic signed [1:0]                                move_x_o,        // X-axis movement output
  output logic signed [1:0]                                move_y_o         // Y-axis movement output
);

logic signed [2:0] cur_block_i;
logic signed [2:0] cur_block_j;
logic              check_en;

logic              last_brick;

// Determine if it's the last brick
assign last_brick = ( cur_block_i == 'd3 ) && ( cur_block_j == 'd3 );

// Clocked always block for enabling checking
always_ff @( posedge clk_i )
  if( run_i )
    check_en <= 1'b1;
  else
    if( last_brick )
      check_en <= 1'b0;

// Clocked always block for initializing block position
always_ff @( posedge clk_i )
  if( run_i )
    begin
      cur_block_i <= '0;
      cur_block_j <= '0;
    end
  else
    if( check_en )
      begin
        if( cur_block_j == 'd3 )
          begin
            cur_block_i <= cur_block_i + 1'd1;
            cur_block_j <= 'd0;
          end
        else
          begin
            cur_block_j <= cur_block_j + 1'd1;
          end
      end

// Clocked always block for setting 'done_o' signal
always_ff @( posedge clk_i )
  if( run_i )
    begin
      done_o <= 1'b0;
    end
  else
    if( done_o )
      done_o <= 1'b0;
    else
      begin
        if( check_en )
          begin
            if( last_brick )
              done_o <= 1'b1;
          end
      end

logic signed [`FIELD_COL_CNT_WIDTH:0] check_field_col;
logic signed [`FIELD_ROW_CNT_WIDTH:0] check_field_row;

logic signed [1:0] x_move;
logic signed [1:0] y_move;

// Calculate the new block position based on requested move
assign check_field_col = block_i.x + cur_block_j + x_move;
assign check_field_row = block_i.y + cur_block_i + y_move;

// Assign movement values based on requested move
assign move_x_o = x_move;
assign move_y_o = y_move;

// Clocked always block for handling requested moves
always_ff @( posedge clk_i )
  if( run_i )
    begin
      case( req_move_i )
        MOVE_LEFT:
          begin
            x_move <= -1;
            y_move <= 0;
          end
        MOVE_RIGHT:
          begin
            x_move <= 1;
            y_move <= 0;
          end
        MOVE_DOWN:
          begin
            x_move <= 0;
            y_move <= 1;
          end
        MOVE_ROTATE:
          begin
            x_move <= 0;
            y_move <= 0;
          end
        MOVE_APPEAR:
          begin
            x_move <= 0;
            y_move <= 0;
          end
        default:
          begin
            x_move <= 0;
            y_move <= 0;
          end
      endcase
    end

logic [0:3][0:3] check_data;

// Clocked always block for checking data based on requested move
always_ff @( posedge clk_i )
  begin
    if( run_i )
      check_data <= ( req_move_i == MOVE_ROTATE ) ? ( block_i.data[ block_i.rotation + 1'd1 ] ):
                                                    ( block_i.data[ block_i.rotation        ] );
  end

// Clocked always block for determining if a move is valid
always_ff @( posedge clk_i )
  if( run_i ) 
    begin
      can_move_o <= 1'b1;
    end
  else
    if( check_en )
      begin
        if( check_data[ cur_block_i ][ cur_block_j ] )
          begin
            if( ( check_field_row < 0 ) || ( check_field_col < 0 ) || field_i[ check_field_row ][ check_field_col ] )
              can_move_o <= 1'b0;
          end
      end

endmodule
