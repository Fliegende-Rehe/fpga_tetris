`include "./game_logic/defs.vh"

module tetris_top(
    input         clk,  // Main clock input
    input         rst,  // Reset input

    // User input buttons
    input         btn_left,
    input         btn_right,
    input         btn_up,
    input         btn_down,
    input         btn_new_game,

    // VGA Output
    output        vga_hs,
    output        vga_vs,
    output        vga_de,
    output [7:0]  vga_r,
    output [7:0]  vga_g,
    output [7:0]  vga_b
);

    // Internal signals for inter-module communication
    user_event_t user_event;
    logic        user_event_ready;
    logic        user_event_rd_req;
    
    game_data_t  game_data;

    // Instantiate user_input module
    user_input user_input_inst(
        .rst_i(rst),
        .main_logic_clk_i(clk),

        .btn_left_i(btn_left),
        .btn_right_i(btn_right),
        .btn_up_i(btn_up),
        .btn_down_i(btn_down),
        .btn_new_game_i(btn_new_game),

        .user_event_rd_req_i(user_event_rd_req),
        .user_event_o(user_event),
        .user_event_ready_o(user_event_ready)
    );

    // Instantiate main_game_logic module
    main_game_logic main_game_logic_inst(
        .clk_i(clk),
        .rst_i(rst),

        .user_event_i(user_event),
        .user_event_ready_i(user_event_ready),
        .user_event_rd_req_o(user_event_rd_req),
        
        .game_data_o(game_data)
    );

    // Instantiate draw_tetris module
    draw_tetris draw_tetris_inst(
        .clk_vga_i(clk),

        .game_data_i(game_data),

        .vga_hs_o(vga_hs),
        .vga_vs_o(vga_vs),
        .vga_de_o(vga_de),
        .vga_r_o(vga_r),
        .vga_g_o(vga_g),
        .vga_b_o(vga_b)
    );

endmodule
