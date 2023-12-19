`include "defs.vh"

module draw_tetris(
    input clk_vga_i,  // Clock input from ClockDivider module
    input game_data_t game_data_i,  // Input structure containing game data

    // VGA interface outputs
    output logic vga_hs_o,  // Horizontal sync signal
    output logic vga_vs_o,  // Vertical sync signal
    output logic vga_de_o,  // Display enable signal
    output logic [7:0] vga_r_o,  // VGA red channel output
    output logic [7:0] vga_g_o,  // VGA green channel output
    output logic [7:0] vga_b_o   // VGA blue channel output
);

localparam PIX_WIDTH = 12;  // Pixel width in bits
logic [23:0] field_vga_data_w;  // Intermediate VGA data from game field
logic field_vga_data_en_w;  // Enable signal for field VGA data
localparam HDATA_BEGIN = 144; // Start of horizontal display data
localparam HDATA_END = 784;   // End of horizontal display data
localparam VDATA_BEGIN = 35;  // Start of vertical display data
localparam VDATA_END = 515;   // End of vertical display data
logic [PIX_WIDTH-1:0] pix_x;  // Current pixel X-coordinate
logic [PIX_WIDTH-1:0] pix_y;  // Current pixel Y-coordinate
logic [23:0] vga_data;  // Final VGA data to output

// Instance of draw_field module
draw_field
#( 
    .PIX_WIDTH ( PIX_WIDTH )
) draw_field (
    .clk_i ( clk_vga_i ),
    .pix_x_i ( pix_x ),
    .pix_y_i ( pix_y ),
    .game_data_i ( game_data_i ),
    .vga_data_o ( field_vga_data_w ),
    .vga_data_en_o ( field_vga_data_en_w )
);

// Logic to determine final VGA data based on field VGA data
always_comb begin
    vga_data = `COLOR_BACKGROUND;  // Default to background color
    if (field_vga_data_en_w)
        vga_data = field_vga_data_w;  // Use field data if available
end

// Instance of VgaController module
logic [2:0] rgb_in;  // RGB input for VgaController
logic [2:0] rgb_out; // RGB output from VgaController
integer hpos;       // Horizontal position from VgaController
integer vpos;       // Vertical position from VgaController

VgaController vga_controller_instance(
    .clk (clk_vga_i),
    .rgb_in (rgb_in),
    .rgb_out (rgb_out),
    .hsync (vga_hs_o),
    .vsync (vga_vs_o),
    .hpos (hpos),
    .vpos (vpos)
);

// Logic for converting 24-bit vga_data to 3-bit rgb_in and updating VGA outputs
always_ff @(posedge clk_vga_i) begin
    rgb_in <= vga_data[23:21];  // Simple example conversion
    pix_x <= hpos;              // Update current pixel X-coordinate
    pix_y <= vpos;              // Update current pixel Y-coordinate
    { vga_r_o, vga_g_o, vga_b_o } <= vga_data;  // Output VGA data
    vga_de_o <= (hpos >= HDATA_BEGIN) && (hpos < HDATA_END) && (vpos >= VDATA_BEGIN) && (vpos < VDATA_END);  // Determine display enable
end

endmodule
