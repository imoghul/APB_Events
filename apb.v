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
    
    reg [3:0] pendingA, pendingB, pendingC;
    reg pending;
    reg [31:0] addr_to_send,addr;
    assign apb_paddr_o = addr;
    
    reg [1:0] sv;
    reg [1:0] next_state;
    
    reg psel_o,penable_o;
    assign apb_psel_o = psel_o;
    assign apb_penable_o = penable_o;
    
    reg[31:0] pwdata_o,pendings;
    assign apb_pwdata_o = pwdata_o;
    
    reg pready_i;
    
    assign apb_pwrite_o = 1;
    
    always @(posedge clk)
        pready_i = apb_pready_i;
    
    // pending counter block
    always @(event_a_i,event_b_i,event_c_i, negedge reset) begin
        if (reset) begin
            pendingA = 0;
            pendingB = 0;
            pendingC = 0;
        end
        else begin
            pendingA = event_a_i ? pendingA+1:pendingA;
            
            pendingB = event_b_i ? pendingB+1:pendingB;
            
            pendingC = event_c_i ? pendingC+1:pendingC;
            
        end
    end
    // state transition
    always @(posedge clk or negedge reset)
        if (reset) begin
            sv <= STATE_IDLE;
            next_state <= 0;
            psel_o <= 0;
            pready_i <= 0;
            pwdata_o <= 0;
            pendings <= 0;
        end
        else sv <= next_state;
    
    // fsm
    always @* begin
        case (sv)
            STATE_IDLE : begin
                psel_o = 0;
                penable_o = 0;
                addr = 0;
                pwdata_o = 0 ;
                next_state = |(pendingA | pendingB | pendingC) ? STATE_SETUP : STATE_IDLE;
            end
            STATE_SETUP : begin
                psel_o = 1;
                if (pendingA) begin
                    addr_to_send = EVENT_A_ADDR;
                    pendingA = pendingA - 1;
                end
                else if (pendingB) begin
                    addr_to_send = EVENT_B_ADDR;
                    pendingB = pendingB-1;
                end
                else if (|pendingC) begin
                    addr_to_send = EVENT_C_ADDR;
                    pendingC = pendingC-1;
                end
                else begin
                    addr_to_send = 0;
                    pendingA = 0;
                    pendingB = 0;
                    pendingC = 0;
                end
                pendings = pendingA+pendingB+pendingC;
                next_state = STATE_ACCESS;
                
                
            end
            STATE_ACCESS : begin
                penable_o = 1;
                addr = addr_to_send;
                pwdata_o = pendings;
                next_state = pready_i ? STATE_IDLE : STATE_ACCESS;
            end
            default: next_state = STATE_IDLE;
        endcase
    end
    
    
endmodule
