// Include definitions file for constants and data types
`include "defs.vh"

// Main game logic module for a Tetris-like game
module main_game_logic
(
  input clk_i,  // System clock input
  input rst_i,  // System reset input

  // User event inputs and control signals
  input user_event_t user_event_i,
  input user_event_ready_i,
  output user_event_rd_req_o,
  
  // Game data output structure
  output game_data_t game_data_o
);

// Declare internal signals and structures

// Game field matrix with and without colors
logic [`FIELD_EXT_ROW_CNT-1:0][`FIELD_EXT_COL_CNT-1:0] field;
logic [`FIELD_EXT_ROW_CNT-1:0][`FIELD_EXT_COL_CNT-1:0][`TETRIS_COLORS_WIDTH-1:0] field_with_color;
logic [`FIELD_EXT_ROW_CNT-1:0][`FIELD_EXT_COL_CNT-1:0][`TETRIS_COLORS_WIDTH-1:0] field_clean;
logic [`FIELD_EXT_ROW_CNT-1:0][`FIELD_EXT_COL_CNT-1:0][`TETRIS_COLORS_WIDTH-1:0] field_shifted;

// Current block information and control
logic [`FIELD_EXT_ROW_CNT-1:0][`FIELD_EXT_COL_CNT-1:0][`TETRIS_COLORS_WIDTH-1:0] field_with_cur_block;
logic [0:3][0:3] cur_block_data;
block_info_t next_block;
block_info_t cur_block;
logic cur_block_draw_en;

// System event signal for internal game events
logic sys_event;

// Signals for move checking and execution
logic check_move_run;
logic check_move_done;
logic can_move;
logic signed [1:0] move_x;
logic signed [1:0] move_y;

// Request and execution of block moves
move_t req_move;
move_t next_req_move;

// Line completion checking
logic [`FIELD_ROW_CNT-1:0] full_row;
logic [$clog2(`FIELD_ROW_CNT)-1:0] full_row_num;
logic check_lines_first_tick;

// State machine for game logic
enum int unsigned { IDLE_S, NEW_GAME_S, GEN_NEW_BLOCK_S, WAIT_EVENT_S, CHECK_MOVE_S, MAKE_MOVE_S, APPEND_BLOCK_S, CHECK_LINES_S, GAME_OVER_S } state, next_state; 

// always_comb block for initializing the 'field_clean' matrix
always_comb
  begin
    field_clean = '0; // Reset the field to zero

    // Iterate over rows and columns to define the game boundaries
    for( int row = 0; row < `FIELD_EXT_ROW_CNT; row++ )
      begin
        for( int col = 0; col < `FIELD_EXT_COL_CNT; col++ )
          begin
            // Set boundary cells to '1' (left, right, and bottom edges of the field)
            if( ( col == 0 ) || ( col == ( `FIELD_EXT_COL_CNT - 1 ) ) || ( row == ( `FIELD_EXT_ROW_CNT - 1 ) ) )
              field_clean[row][col] = 'd1;
          end
      end
  end

// always_ff block for updating 'field_with_color' based on game state
always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    field_with_color <= '0; // Reset field_with_color on system reset
  else
    begin
      // Update field_with_color based on the current game state
      case( state )
        NEW_GAME_S:     field_with_color <= field_clean;            // Initialize field for a new game
        APPEND_BLOCK_S: field_with_color <= field_with_cur_block;   // Update field with current block's position
        CHECK_LINES_S:  field_with_color <= field_shifted;          // Update field after line clearing
      endcase
    end

// always_comb block for updating the basic 'field' matrix from 'field_with_color'
always_comb
  begin
    // Iterate over the extended field matrix
    for( int row = 0; row < `FIELD_EXT_ROW_CNT; row++ )
      begin
        for( int col = 0; col < `FIELD_EXT_COL_CNT; col++ )
          begin
            // Update the basic field matrix based on whether each cell in field_with_color is non-zero
            field[ row ][ col ] = ( field_with_color[ row ][ col ] != 'd0 );
          end
      end
  end

// always_comb block for detecting full rows
always_comb
  begin
    // Iterate over each row in the playing field
    for( int row = 0; row < `FIELD_ROW_CNT; row++ )
      begin
        // Check if the entire row is filled (logical AND of all cells in the row)
        full_row[ row ] = &field[ row + 1 ][`FIELD_COL_CNT:1];
      end
  end

// always_comb block to determine the number of the highest full row
always_comb
  begin
    full_row_num = '0; // Initialize the full_row_num to zero

    // Iterate over all rows to find the highest full row
    for( int row = 0; row < `FIELD_ROW_CNT; row++ )
      begin
        if( full_row[ row ] )
          full_row_num = row; // Update full_row_num if the current row is full
      end
  end

// always_comb block to shift the field when a row is cleared
always_comb
  begin
    field_shifted = field_with_color; // Initialize field_shifted with the current field state
    
    // Check if any row is full and needs to be cleared
    if( |full_row )
      begin
        // Iterate over all rows to shift them down
        for( int row = 0; row < `FIELD_ROW_CNT; row++ )
          begin
            if( row <= full_row_num )
              begin
                // Clear the top row and shift other rows down
                if( row == 0 )
                  field_shifted[ 0 + 1 ][`FIELD_COL_CNT:1] = '0;
                else
                  field_shifted[ row + 1 ][`FIELD_COL_CNT:1] = field_with_color[row][`FIELD_COL_CNT:1];
              end
          end
      end
  end

// Assign current block data based on its rotation
assign cur_block_data = cur_block.data[ cur_block.rotation ];

// always_comb block to overlay the current block on the field
always_comb
  begin
    field_with_cur_block = field_with_color; // Initialize with the current field state
    
    // Draw the current block on the field if enabled
    if( cur_block_draw_en )
      begin
        // Iterate over the 4x4 block matrix
        for( int i = 0; i < 4; i++ )
          begin
            for( int j = 0; j < 4; j++ )
              begin
                // Update the field with the block's color where the block exists
                if( cur_block_data[i][j] )
                  field_with_cur_block[ cur_block.y + i ][ cur_block.x + j ] = cur_block.color;
              end
          end
      end
  end

// Assign user event read request output
assign user_event_rd_req_o = user_event_ready_i && ( ( state == IDLE_S ) ||
                                                     ( state == WAIT_EVENT_S ) ||
                                                     ( state == GAME_OVER_S ) );

// always_comb block to determine the next required move based on the game state and user events
always_comb
  begin
    next_req_move = MOVE_DOWN; // Default move is down
    
    // If in WAIT_EVENT state, decide the next move based on the user event
    if( state == WAIT_EVENT_S )
      begin
        if( user_event_ready_i )
          begin
            case( user_event_i ) // Choose move based on user event
              EV_LEFT:   next_req_move = MOVE_LEFT;
              EV_RIGHT:  next_req_move = MOVE_RIGHT;
              EV_DOWN:   next_req_move = MOVE_DOWN;
              EV_ROTATE: next_req_move = MOVE_ROTATE;
              default:   next_req_move = MOVE_DOWN;
            endcase
          end
      end
    else if( state == GEN_NEW_BLOCK_S )
      begin
        next_req_move = MOVE_APPEAR; // If generating new block, set move to appear
      end
  end

// always_ff block for updating the requested move
always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    req_move <= MOVE_DOWN; // Reset requested move on system reset
  else
    if( ( next_state == CHECK_MOVE_S ) && ( state != CHECK_MOVE_S ) )
      req_move <= next_req_move; // Update requested move for move checking

// always_ff block for updating the game state
always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    state <= IDLE_S; // Set state to IDLE on system reset
  else
    state <= next_state; // Update state to the next state


// always_comb block for determining the next state of the game based on the current state and inputs
always_comb
  begin
    next_state = state; // Default to staying in the current state

    // State machine implementation
    case( state )
      IDLE_S:
        begin
          // If in IDLE state, check for new game event to transition to NEW_GAME state
          if( user_event_ready_i && user_event_i == EV_NEW_GAME )
            next_state = NEW_GAME_S;
        end

      NEW_GAME_S:
        begin
          // Transition from NEW_GAME to GEN_NEW_BLOCK state to start generating a new block
          next_state = GEN_NEW_BLOCK_S;
        end

      GEN_NEW_BLOCK_S:
        begin
          // After generating a new block, move to CHECK_MOVE state to check its validity
          next_state = CHECK_MOVE_S;
        end

      WAIT_EVENT_S:
        begin
          // In WAIT_EVENT state, respond to user inputs or system events
          if( user_event_ready_i )
            begin
              // Transition to CHECK_MOVE state for movement commands
              case( user_event_i )
                EV_LEFT, EV_RIGHT, EV_DOWN, EV_ROTATE:
                  next_state = CHECK_MOVE_S;
                EV_NEW_GAME:
                  // Restart the game if new game event is received
                  next_state = NEW_GAME_S;
                default:
                  // Stay in WAIT_EVENT state for other events
                  next_state = WAIT_EVENT_S;
              endcase
            end
          else if( sys_event )
            begin
              // Transition to CHECK_MOVE state on system events
              next_state = CHECK_MOVE_S;
            end
        end

      CHECK_MOVE_S:
        begin
          // If move check is done, proceed to MAKE_MOVE state
          if( check_move_done )
            next_state = MAKE_MOVE_S;
        end

      MAKE_MOVE_S:
        begin
          // Determine the next state based on move validity and type
          if( ( req_move == MOVE_APPEAR && !can_move ) || 
              ( req_move == MOVE_DOWN && !can_move && |field[0][`FIELD_COL_CNT:1] ) )
            next_state = GAME_OVER_S; // Game over if move is invalid or block reaches the top
          else if( req_move == MOVE_DOWN && !can_move )
            next_state = APPEND_BLOCK_S; // Append block and check lines if move down is not possible
          else
            next_state = WAIT_EVENT_S; // Wait for the next event if move is possible
        end

      APPEND_BLOCK_S:
        begin
          // After appending a block, check for complete lines
          next_state = CHECK_LINES_S;
        end

      CHECK_LINES_S:
        begin
          // If no full rows, generate a new block; otherwise, stay to clear lines
          if( !( |full_row ) )
            next_state = GEN_NEW_BLOCK_S;
        end

      GAME_OVER_S:
        begin
          // In GAME_OVER state, wait for new game event to restart
          if( user_event_ready_i && user_event_i == EV_NEW_GAME )
            next_state = NEW_GAME_S;
        end

      default:
        begin
          // Fallback to IDLE state for any undefined states
          next_state = IDLE_S;
        end
    endcase
  end

// always_ff block for managing the current block's state and movement
always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    begin
      // Reset current block and its drawing enable flag on system reset
      cur_block         <= '0;
      cur_block_draw_en <= 1'b0;
    end
  else
    begin
      // Update current block at the generation of a new block
      if( state == GEN_NEW_BLOCK_S )
        begin
          cur_block         <= next_block;
          cur_block_draw_en <= 1'b0; // Disable drawing until the block appears
        end

      // Handle block movement in MAKE_MOVE state
      if( state == MAKE_MOVE_S )
        begin
          if( can_move )
            begin
              // Move current block based on calculated x and y offsets
              cur_block.x    <= cur_block.x + move_x;
              cur_block.y    <= cur_block.y + move_y;
              
              // Enable drawing the block when it appears
              if( req_move == MOVE_APPEAR )
                cur_block_draw_en <= 1'b1;
              
              // Handle block rotation
              if( req_move == MOVE_ROTATE )
                cur_block.rotation <= cur_block.rotation + 1'd1;
            end
        end
    end

// always_comb block for updating the game data output field
always_comb
  begin
    // Iterate over each cell in the field to update game data output
    for( int col = 0; col < `FIELD_COL_CNT; col++ )
      begin
        for( int row = 0; row < `FIELD_ROW_CNT; row++ )
          begin
            game_data_o.field[row][col] = field_with_cur_block[ row + 1 ][ col + 1 ];
          end
      end
  end

// always_comb block for updating game data output state
always_comb
  begin
    // Assign next block and game over state to game data output
    game_data_o.next_block         = next_block;
    game_data_o.next_block_draw_en = ( state != IDLE_S );
    game_data_o.game_over_state    = ( state == GAME_OVER_S );
  end

// Assign statement for initiating move check logic
assign check_move_run = ( state != CHECK_MOVE_S ) && ( next_state == CHECK_MOVE_S );

// Instantiation of the check_move module
check_move check_move(
  .clk_i               ( clk_i             ),
  .run_i               ( check_move_run    ),
  .req_move_i          ( next_req_move     ),
  .block_i             ( cur_block         ),
  .field_i             ( field             ),
  .done_o              ( check_move_done   ),
  .can_move_o          ( can_move          ),
  .move_x_o            ( move_x            ),
  .move_y_o            ( move_y            )
);

// always_ff block for managing the first tick of line checking
always_ff @( posedge clk_i or posedge rst_i )
  if( rst_i )
    check_lines_first_tick <= '0; // Reset on system reset
  else
    // Set first tick flag when transitioning from APPEND_BLOCK to CHECK_LINES state
    check_lines_first_tick <= ( state == APPEND_BLOCK_S ) && ( next_state == CHECK_LINES_S );

// always_comb block for counting disappearing lines
always_comb
  begin
    disappear_lines_cnt = 0; // Reset count to zero

    // Count the number of full rows that need to disappear
    for( int row = 0; row < `FIELD_ROW_CNT; row++ )
      begin
        if( full_row[row] )
          disappear_lines_cnt = disappear_lines_cnt + 1'd1;
      end
  end

// Assign statement for the synchronous reset of the stat module
assign stat_srst = ( state == NEW_GAME_S ) && ( next_state != NEW_GAME_S );


// Instantiation of the tetris_stat module for managing game statistics
tetris_stat stat(
  .clk_i                ( clk_i                  ), // Clock input
  .srst_i               ( stat_srst              ), // Synchronous reset input, active during a new game start
  .disappear_lines_cnt_i( disappear_lines_cnt    ), // Input for the number of lines that have disappeared
  .update_stat_en_i     ( check_lines_first_tick ), // Enable signal for updating statistics
  .score_o              ( game_data_o.score      ), // Output for the current score
  .lines_o              ( game_data_o.lines      ), // Output for the number of lines cleared
  .level_o              ( game_data_o.level      ), // Output for the current level
  .level_changed_o      ( level_changed          )  // Output signal indicating a change in level
);

// Logic signal for enabling the generation of the next block
logic gen_next_block_en;

// Assign gen_next_block_en based on game state
assign gen_next_block_en = ( state == IDLE_S || state == GEN_NEW_BLOCK_S );

// Instantiation of gen_next_block module for generating the next block
gen_next_block gen_next_block(
  .clk_i       ( clk_i             ), // Clock input
  .en_i        ( gen_next_block_en ), // Enable signal for generating the next block
  .next_block_o( next_block        )  // Output for the next block information
);

// Logic signal for synchronous reset of the sys_event module
logic sys_event_srst;

// Assign sys_event_srst based on game state transitions
assign sys_event_srst = ( state == NEW_GAME_S ) && ( next_state != NEW_GAME_S );

// Instantiation of gen_sys_event module for generating system events
gen_sys_event gen_sys_event(
  .clk_i           ( clk_i          ), // Clock input
  .srst_i          ( sys_event_srst ), // Synchronous reset input
  .level_changed_i ( level_changed  ), // Input signal for level change
  .sys_event_o     ( sys_event      )  // Output system event signal
);

// Debug block for printing the game field state
// synthesis translate_off
initial
  begin
    forever
      begin
        @( posedge clk_i );
        // Print the current time and the game field state
        $write("-------%t-------\n", $time());
        for( int row = 0; row < `FIELD_EXT_ROW_CNT; row++ )
          begin
            for( int col = 0; col < `FIELD_EXT_COL_CNT; col++ )
              begin
                // Print '*' for boundaries and the hex value of each cell
                if( ( col == 0 ) || ( col == ( `FIELD_EXT_COL_CNT - 1 ) ) || ( row == ( `FIELD_EXT_ROW_CNT - 1 ) ) )
                  $write( "*" );
                else
                  $write( "%h", field_with_cur_block[ row ][ col ] );
              end
            $write("\n");
          end
      end
  end
// synthesis translate_on

endmodule // End of main_game_logic module

