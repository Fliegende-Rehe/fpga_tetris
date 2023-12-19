`include "defs.vh"

// Module for processing user inputs with debouncing
module user_input(
    input               rst_i,                // Reset input
    input               main_logic_clk_i,     // Main logic clock

    // Button inputs
    input               btn_left_i,
    input               btn_right_i,
    input               btn_up_i,
    input               btn_down_i,
    input               btn_new_game_i,

    input               user_event_rd_req_i,  // Read request for user event
    output user_event_t user_event_o,         // User event output
    output              user_event_ready_o    // User event ready signal
);

// Debounced button signals
wire debounced_left, debounced_right, debounced_up, debounced_down, debounced_new_game;

// Instantiate debounce modules for each button
Debounce debounce_left (.i_Clk(main_logic_clk_i), .i_Switch(btn_left_i), .o_Switch(debounced_left));
Debounce debounce_right(.i_Clk(main_logic_clk_i), .i_Switch(btn_right_i), .o_Switch(debounced_right));
Debounce debounce_up   (.i_Clk(main_logic_clk_i), .i_Switch(btn_up_i), .o_Switch(debounced_up));
Debounce debounce_down (.i_Clk(main_logic_clk_i), .i_Switch(btn_down_i), .o_Switch(debounced_down));
Debounce debounce_new_game(.i_Clk(main_logic_clk_i), .i_Switch(btn_new_game_i), .o_Switch(debounced_new_game));

// Event writing logic
user_event_t wr_event;
logic        wr_event_val;

// Process button events and assign corresponding user event
always_comb begin
    wr_event_val = 1'b0;  // Default to no event
    wr_event = EV_NONE;   // Default event

    if (debounced_new_game) begin
        wr_event = EV_NEW_GAME;
    end else if (debounced_up) begin
        wr_event = EV_ROTATE;
    end else if (debounced_left) begin
        wr_event = EV_LEFT;
    end else if (debounced_right) begin
        wr_event = EV_RIGHT;
    end else if (debounced_down) begin
        wr_event = EV_DOWN;
    end
    
    // Set event valid flag if any event is triggered
    wr_event_val = (wr_event != EV_NONE);
end

endmodule
