module apb (input wire clk,
            input wire reset,
            input wire event_a_i,
            input wire event_b_i,
            input wire event_c_i,
            output wire apb_psel_o,
            output wire apb_penable_o,
            output wire [31:0] apb_paddr_o,
            output wire apb_pwrite_o,
            output wire [31:0] apb_pwdata_o,
            input wire apb_pready_i);
    
    localparam EVENT_A_ADDR = 32'hABBA_0000;
    localparam EVENT_B_ADDR = 32'hBAFF_0000;
    localparam EVENT_C_ADDR = 32'hCAFE_0000;
    
    localparam STATE_IDLE = 2'b00;
    localparam STATE_SETUP = 2'b01;
    localparam STATE_ACCESS = 2'b10;
    
    reg [1:0] sv,next_state;

    wire state_setup,state_access;
    assign state_setup = sv == STATE_SETUP;
    assign state_access = sv == STATE_ACCESS;

    assign apb_psel_o = state_setup | state_access;
    assign apb_penable_o = state_access;
    assign apb_pwrite_o  = state_access;
    

    reg [3:0] pendingA,pendingB,pendingC;

    // counting pendings
    always @(posedge clk or negedge reset)
        if(reset) begin
            pendingA = 0;
            pendingB = 0;
            pendingC = 0;
        end
        else begin 
            // pendingA = event_a_i ? 1:pendingA;
            // pendingB = event_b_i ? 1:pendingB;
            // pendingC = event_c_i ? 1:pendingC;
            if(event_a_i) begin
                
            end
        end

    
    // state transition
    always @(posedge clk or negedge reset)
        if (reset) begin
            sv <= STATE_IDLE;
            next_state <= 0;
        end
        else sv <= next_state;
    
    // fsm
    always @* begin
        case (sv)
            STATE_IDLE : begin
                if(event_a_i | event_b_i | event_c_i | pendingA | pendingB | pendingC) 
                    next_state = STATE_SETUP;
                else 
                    next_state = STATE_IDLE;
            end
            STATE_SETUP : begin
                
                next_state = STATE_ACCESS;
                
                
            end
            STATE_ACCESS : begin
                
            end
            default: next_state = STATE_IDLE;
        endcase
    end
    
    
endmodule

