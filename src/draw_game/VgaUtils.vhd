library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package VgaUtils is
  -- Colors const
  constant COLOR_WHITE  : std_logic_vector := "111";
  constant COLOR_YELLOW : std_logic_vector := "110";
  constant COLOR_PURPLE : std_logic_vector := "101";
  constant COLOR_RED    : std_logic_vector := "100";
  constant COLOR_WATER  : std_logic_vector := "011";
  constant COLOR_GREEN  : std_logic_vector := "010";
  constant COLOR_BLUE   : std_logic_vector := "001";
  constant COLOR_BLACK  : std_logic_vector := "000";

  -- Values for 640x480 resolution
  constant HSYNC_END   : integer := 95;
  constant HDATA_BEGIN : integer := 143;
  constant HDATA_END   : integer := 783;
  constant HLINE_END   : integer := 799;

  constant VSYNC_END   : integer := 1;
  constant VDATA_BEGIN : integer := 34;
  constant VDATA_END   : integer := 514;
  constant VLINE_END   : integer := 524;
end package;
