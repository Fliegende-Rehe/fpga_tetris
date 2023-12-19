module gen_sys_event(
  input  clk_i,              // Clock input
  input  srst_i,             // Synchronous reset input

  input  level_changed_i,    // Input signal to adjust the event period
  
  output sys_event_o         // Output signal for the system event
);

// Define constants for the system event period
localparam SYS_EVENT_PERIOD_MAX  = 'd67_000_000; // Maximum event period
localparam SYS_EVENT_PERIOD_MIN  = 'd10_000_000; // Minimum event period
localparam SYS_EVENT_PERIOD_STEP = 'd4_000_000;  // Step size for period adjustment

// State variables
logic [31:0] sys_counter      = '0;             // Counter for the event period
logic [31:0] sys_event_period = SYS_EVENT_PERIOD_MAX; // Current event period
logic [31:0] next_sys_event_period;             // Next event period after adjustment

logic        counter_eq_period;                // Flag when counter equals the period

// Combinational block to calculate the next system event period
always_comb
  begin
    // If the next period is below the minimum, set it to the minimum
    // Otherwise, decrease it by the step size
    if( ( sys_event_period - SYS_EVENT_PERIOD_STEP ) < SYS_EVENT_PERIOD_MIN )
      next_sys_event_period = SYS_EVENT_PERIOD_MIN;
    else
      next_sys_event_period = sys_event_period - SYS_EVENT_PERIOD_STEP;
  end

// Sequential block to update the system event period
always_ff @( posedge clk_i )
  if( srst_i )
    sys_event_period <= SYS_EVENT_PERIOD_MAX; // Reset period to maximum on reset
  else
    if( level_changed_i )
      sys_event_period <= next_sys_event_period; // Update period on level change

// Sequential block to update the system counter
always_ff @( posedge clk_i )
  if( srst_i || level_changed_i || counter_eq_period )
    sys_counter <= 'd0; // Reset counter on reset, level change, or when period matches
  else
    sys_counter <= sys_counter + 1'd1; // Increment counter
  
// Determine if counter matches the system event period
assign counter_eq_period = ( sys_counter == sys_event_period );

// Generate system event output when counter matches the period
assign sys_event_o = counter_eq_period;

endmodule