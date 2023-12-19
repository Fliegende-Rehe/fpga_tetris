library ieee;
use ieee.std_logic_1164.all;  -- Standard logic package
use ieee.numeric_std.all;     -- Numeric operations

-- Entity declaration for Debounce circuit
entity Debounce is
  port (
    i_Clk    : in std_logic;    -- Clock input
    i_Switch : in std_logic;    -- Raw switch input
    o_Switch : out std_logic    -- Debounced switch output
  );
end entity Debounce;

-- Architecture declaration
architecture RTL of Debounce is
  -- Constant defining debounce period (10 ms for a 25 MHz clock)
  constant c_DEBOUNCE_LIMIT : integer := 250000;

  -- Internal signals for counting and state holding
  signal r_Count : integer range 0 to c_DEBOUNCE_LIMIT := 0;
  signal r_State : std_logic := '0';
begin
  -- Debouncing process
  p_Debounce : process (i_Clk)
  begin
    if rising_edge(i_Clk) then  -- Trigger on the rising edge of the clock
      -- Check if switch state has changed and count is below the limit
      if (i_Switch /= r_State) and (r_Count < c_DEBOUNCE_LIMIT) then
        r_Count <= r_Count + 1;  -- Increment counter

      -- Reset count and update state when debounce limit is reached
      elsif r_Count = c_DEBOUNCE_LIMIT then
        r_State <= i_Switch;
        r_Count <= 0;

      -- Reset count if switch state is stable
      else
        r_Count <= 0;
      end if;
    end if;
  end process p_Debounce;

  -- Output assignment
  o_Switch <= r_State;  -- Assign internal state to output
end architecture RTL;
