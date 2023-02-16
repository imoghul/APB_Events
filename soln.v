// --------------------------------------------------------
// Events to APB - RTL
// --------------------------------------------------------

module events_to_apb_soln (
  input   wire         clk,
  input   wire         reset,

  input   wire         event_a_i,
  input   wire         event_b_i,
  input   wire         event_c_i,

  output  wire         apb_psel_o,
  output  wire         apb_penable_o,
  output  wire [31:0]  apb_paddr_o,
  output  wire         apb_pwrite_o,
  output  wire [31:0]  apb_pwdata_o,
  input   wire         apb_pready_i

);

  // --------------------------------------------------------
  // Internal wire and regs
  // --------------------------------------------------------
  localparam ST_IDLE   = 2'b00;
  localparam ST_SETUP  = 2'b01;
  localparam ST_ACCESS = 2'b10;

  localparam EVENT_A_ADDR = 32'hABBA_0000;
  localparam EVENT_B_ADDR = 32'hBAFF_0000;
  localparam EVENT_C_ADDR = 32'hCAFE_0000;

  wire       apb_psel;
  wire       apb_penable;
  wire[31:0] apb_paddr;
  wire       apb_pwrite;
  wire[31:0] apb_pwdata;

  reg [31:0] apb_pwdata_q;

  reg [31:0] paddr_q;
  reg [31:0] nxt_paddr;

  reg [1:0]  state_q;
  reg [1:0]  nxt_state;
  wire       apb_state_setup;
  wire       apb_state_access;

  wire       event_seen;

  reg  [3:0] event_a_count_q;
  wire [3:0] nxt_event_a_count;

  reg  [3:0] event_b_count_q;
  wire [3:0] nxt_event_b_count;

  reg  [3:0] event_c_count_q;
  wire [3:0] nxt_event_c_count;

  wire       event_a_sel;
  wire       event_b_sel;
  wire       event_c_sel;

  assign event_seen = |{event_a_i, event_b_i, event_c_i,
                        event_a_count_q, event_b_count_q, event_c_count_q};

  always @(posedge clk or posedge reset)
    if (reset)
      state_q <= ST_IDLE;
    else
      state_q <= nxt_state;

  // --------------------------------------------------------
  // APB state machine
  // --------------------------------------------------------
  always @(*) begin
    nxt_paddr = paddr_q;
    case (state_q)
      ST_IDLE: begin
        if (event_seen) begin
          nxt_state = ST_SETUP;
          nxt_paddr = (event_a_i | (|event_a_count_q)) ? EVENT_A_ADDR :
                      (event_b_i | (|event_b_count_q)) ? EVENT_B_ADDR :
                                                         EVENT_C_ADDR;
        end else begin
          nxt_state = ST_IDLE;
        end
      end
      ST_SETUP: begin
        nxt_state = ST_ACCESS;
      end
      ST_ACCESS: begin
        if (apb_pready_i)
          nxt_state = ST_IDLE;
        else
          nxt_state = ST_ACCESS;
      end
      default: nxt_state = ST_IDLE;
    endcase
  end

  assign apb_state_setup  = (state_q == ST_SETUP);
  assign apb_state_access = (state_q == ST_ACCESS);

  assign apb_psel    = apb_state_setup | apb_state_access;
  assign apb_penable = apb_state_access;
  assign apb_pwrite  = apb_state_access;

  // --------------------------------------------------------
  // APB Address
  // --------------------------------------------------------
  always @(posedge clk or posedge reset)
    if (reset)
      paddr_q <= EVENT_A_ADDR;
    else
      paddr_q <= nxt_paddr;

  assign apb_paddr = {32{apb_state_access}} & paddr_q;

  assign event_a_sel = apb_state_setup & (paddr_q == EVENT_A_ADDR);
  assign event_b_sel = apb_state_setup & (paddr_q == EVENT_B_ADDR);
  assign event_c_sel = apb_state_setup & (paddr_q == EVENT_C_ADDR);

  // --------------------------------------------------------
  // APB Write Data
  // --------------------------------------------------------
  always @(posedge clk or posedge reset)
    if (reset) begin
      event_a_count_q <= 4'h0;
      event_b_count_q <= 4'h0;
      event_c_count_q <= 4'h0;
    end else begin
      event_a_count_q <= nxt_event_a_count;
      event_b_count_q <= nxt_event_b_count;
      event_c_count_q <= nxt_event_c_count;
    end

  assign nxt_event_a_count = event_a_sel ? {3'h0, event_a_i} :
                              event_a_count_q + {3'h0, event_a_i};

  assign nxt_event_b_count = event_b_sel ? {3'h0, event_b_i} :
                              event_b_count_q + {3'h0, event_b_i};

  assign nxt_event_c_count = event_c_sel ? {3'h0, event_c_i} :
                              event_c_count_q + {3'h0, event_c_i};

  assign apb_pwdata = (event_a_sel) ? (event_a_count_q) :
                      (event_b_sel) ? (event_b_count_q) :
                      (event_c_sel) ? (event_c_count_q) :
                                                    32'h0;
  always @(posedge clk or posedge reset)
    if (reset)
      apb_pwdata_q <= 32'h0;
    else if (apb_state_setup)
      apb_pwdata_q <= apb_pwdata;

  // --------------------------------------------------------
  // Output Assignments
  // --------------------------------------------------------
  assign apb_psel_o     = apb_psel;
  assign apb_penable_o  = apb_penable;
  assign apb_paddr_o    = apb_paddr;
  assign apb_pwrite_o   = apb_pwrite;
  assign apb_pwdata_o   = apb_pwdata_q;


endmodule