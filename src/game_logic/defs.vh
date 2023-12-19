`ifndef TETRIS_DEFS
`define TETRIS_DEFS 

typedef enum { EV_LEFT, 
               EV_RIGHT, 
               EV_DOWN,
               EV_ROTATE,
               EV_NEW_GAME } user_event_t;

typedef enum { MOVE_DOWN,
               MOVE_LEFT,
               MOVE_RIGHT,
               MOVE_ROTATE,
               MOVE_APPEAR } move_t;


// ******* Tetris Settings *******
`define EV_NONE 3'b000 // Assuming user_event_t is a 3-bit signal

`define  FIELD_COL_CNT           10
`define  FIELD_ROW_CNT           20
`define  FIELD_COL_CNT_WIDTH     $clog2( `FIELD_COL_CNT )
`define  FIELD_ROW_CNT_WIDTH     $clog2( `FIELD_ROW_CNT )

`define FIELD_EXT_COL_CNT       ( `FIELD_COL_CNT + 2 )
`define FIELD_EXT_ROW_CNT       ( `FIELD_ROW_CNT + 2 )

`define TETRIS_COLORS_CNT       8
`define TETRIS_COLORS_WIDTH     $clog2( `TETRIS_COLORS_CNT )

typedef struct packed {
  logic        [3:0][0:3][0:3]                 data;
  logic        [`TETRIS_COLORS_WIDTH-1:0]      color;
  logic        [1:0]                           rotation;
  logic signed [`FIELD_COL_CNT_WIDTH:0]        x;
  logic signed [`FIELD_ROW_CNT_WIDTH:0]        y;
} block_info_t;

typedef struct packed {
  logic [`FIELD_ROW_CNT-1:0][`FIELD_COL_CNT-1:0][`TETRIS_COLORS_WIDTH-1:0] field;
  logic [5:0][3:0] score;
  logic [5:0][3:0] lines;
  logic [5:0][3:0] level;
  
  block_info_t     next_block;
  logic            next_block_draw_en;

  logic            game_over_state;
} game_data_t;


// ******* Colors *******
`define COLOR_BACKGROUND  24'h80_80_80

`define COLOR_BORDERS     24'hFF_FF_FF

`define COLOR_BRICKS_0    24'hFF_FF_FF
`define COLOR_BRICKS_1    24'h76_C5_DA 
`define COLOR_BRICKS_2    24'hC9_92_C9
`define COLOR_BRICKS_3    24'h75_A3_D0 
`define COLOR_BRICKS_4    24'hCC_99_33 
`define COLOR_BRICKS_5    24'h87_C3_7F 
`define COLOR_BRICKS_6    24'hDE_7F_72 
`define COLOR_BRICKS_7    24'h8A_8A_B0 

`define COLOR_TEXT        24'hFF_D7_00 // gold

`define COLOR_HEAD        24'hFA_94_54 // some sort of orange

`define COLOR_GAME_OVER   24'h8A_07_07 // blooooody red

`endif
