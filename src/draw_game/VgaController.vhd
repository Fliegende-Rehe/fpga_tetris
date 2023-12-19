library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.VgaUtils.all;

-- VGA Controller Entity
-- This entity controls the VGA signal output based on the input clock and RGB input.
entity VgaController is
  port (
    clk     : in std_logic;             -- Input clock
    rgb_in  : in std_logic_vector(2 downto 0); -- RGB input
    rgb_out : out std_logic_vector(2 downto 0); -- RGB output
    hsync   : out std_logic;            -- Horizontal sync signal
    vsync   : out std_logic;            -- Vertical sync signal
    hpos    : out integer;              -- Horizontal position
    vpos    : out integer               -- Vertical position
  );
end VgaController;

architecture rtl of VgaController is
  -- Horizontal and Vertical counters
  signal hcount : integer range 0 to HLINE_END := 0;
  signal vcount : integer range 0 to VLINE_END := 0;

  -- Control signals for resetting counters and outputting data
  signal should_reset_vcount : boolean;
  signal should_reset_hcount : boolean;
  signal should_output_data  : boolean;

begin
  -- Control signal logic
  should_reset_vcount <= vcount = VLINE_END;
  should_reset_hcount <= hcount = HLINE_END;
  should_output_data  <= (hcount >= HDATA_BEGIN) and (hcount < HDATA_END) and
                          (vcount >= VDATA_BEGIN) and (vcount < VDATA_END);

  -- Output signal logic
  hsync   <= '1' when hcount > HSYNC_END else '0';
  vsync   <= '1' when vcount > VSYNC_END else '0';
  rgb_out <= rgb_in when should_output_data else (others => '0');
  hpos    <= hcount;
  vpos    <= vcount;

  -- Horizontal counter process
  -- Increments the horizontal counter on each clock cycle, resets at end of line
  process (clk)
  begin
    if rising_edge(clk) then
      if should_reset_hcount then
        hcount <= 0;
      else
        hcount <= hcount + 1;
      end if;
    end if;
  end process;

  -- Vertical counter process
  -- Increments the vertical counter when horizontal counter resets, resets at end of frame
  process (clk)
  begin
    if rising_edge(clk) and should_reset_hcount then
      if should_reset_vcount then
        vcount <= 0;
      else
        vcount <= vcount + 1;
      end if;
    end if;
  end process;
end architecture;
