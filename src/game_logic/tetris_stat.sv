module tetris_stat(
  input clk_i,                             // Clock input
  input srst_i,                            // Synchronous reset, active high
  input [2:0] disappear_lines_cnt_i,       // Count of lines disappearing
  input update_stat_en_i,                  // Enable updating statistics
  output logic [5:0][3:0] score_o,         // 6-digit BCD score output
  output logic [5:0][3:0] lines_o,         // 6-digit BCD lines output
  output logic [5:0][3:0] level_o,         // 6-digit BCD level output
  output logic level_changed_o             // Level change indicator
);

// SCORE calculation and management
localparam SCORE_DIGITS = 4;
localparam MAX_SCORE = 9999;  // Maximum score in hundreds
localparam SCORE_WIDTH = $clog2(MAX_SCORE + 1);

// Score increment values for different line clears
logic [4:0][3:0] add_score = {4'd15, 4'd7, 4'd3, 4'd1, 4'd0};

// Current and next score variables
logic [SCORE_WIDTH-1:0] score;
logic [SCORE_WIDTH:0]   next_score;
logic [SCORE_DIGITS-1:0][3:0] score_bcd; // BCD representation of the score

// Calculate the next score
always_comb begin
  next_score = score + add_score[disappear_lines_cnt_i];
  next_score = (next_score > MAX_SCORE) ? MAX_SCORE : next_score;
end

// Update the score on clock edge
always_ff @(posedge clk_i) begin
  if(srst_i)
    score <= 0;
  else if(update_stat_en_i)
    score <= next_score[SCORE_WIDTH-1:0]; 
end

// Convert binary score to BCD
bin_2_bcd #( .BIN_WIDTH(SCORE_WIDTH), .BCD_WIDTH(SCORE_DIGITS) )
  bcd_score ( .bin_i(score), .bcd_o(score_bcd) );

// Assign BCD score to output
always_ff @(posedge clk_i) begin
  score_o <= { score_bcd, 2'b00, 2'b00 }; // 6-digit BCD output, padded with zeros
end

// LINES calculation and management
localparam LINES_DIGITS = 3;
localparam MAX_LINES = 999;  // Maximum line count
localparam LINES_WIDTH = $clog2(MAX_LINES + 1);

// Current and next lines variables
logic [LINES_WIDTH-1:0] lines;
logic [LINES_WIDTH:0]   next_lines;
logic [LINES_DIGITS-1:0][3:0] lines_bcd; // BCD representation of the lines

// Calculate the next lines count
always_comb begin
  next_lines = lines + disappear_lines_cnt_i;
  next_lines = (next_lines > MAX_LINES) ? MAX_LINES : next_lines;
end

// Update lines on clock edge
always_ff @(posedge clk_i) begin
  if(srst_i)
    lines <= 0;
  else if(update_stat_en_i)
    lines <= next_lines[LINES_WIDTH-1:0];
end

// Convert binary lines to BCD
bin_2_bcd #( .BIN_WIDTH(LINES_WIDTH), .BCD_WIDTH(LINES_DIGITS) )
  bcd_lines ( .bin_i(lines), .bcd_o(lines_bcd) );

// Assign BCD lines to output
always_ff @(posedge clk_i) begin
  lines_o <= { 3'b000, lines_bcd }; // 6-digit BCD output, padded with zeros
end

// LEVEL calculation and management
// Extracts the level number from lines cleared
logic [1:0][3:0] level_num;
logic [3:0] prev_level_num;

// Calculate the current level based on lines cleared
always_comb begin
  level_num = lines_bcd[2:1] + 1; // Increment level based on lines cleared

  // Cap the level number at 99
  if(level_num > 99)
    level_num = 99;
end

// Store previous level number for change detection
always_ff @(posedge clk_i) begin
  if(srst_i)
    prev_level_num <= 0;
  else
    prev_level_num <= level_num;
end

// Assign level number to output
always_ff @(posedge clk_i) begin
  level_o <= { 4'b0000, level_num }; // 6-digit BCD output, padded with zeros


// Level change detection
assign level_changed_o = (prev_level_num != level_num);

endmodule
