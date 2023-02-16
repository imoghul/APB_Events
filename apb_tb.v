module apb_tb; reg rst, clock; reg event_a_i; reg event_b_i; reg event_c_i; wire apb_psel_o; wire apb_penable_o; wire [31:0] apb_paddr_o; wire apb_pwrite_o; wire [31:0] apb_pwdata_o; reg pready_i; reg apb_pready_i; apb DUT (.reset(rst), .clk(clock), .event_a_i(event_a_i), .event_b_i(event_b_i), .event_c_i(event_c_i), .apb_psel_o(apb_psel_o), .apb_penable_o(apb_penable_o), .apb_paddr_o(apb_paddr_o), .apb_pwrite_o(apb_pwrite_o), .apb_pwdata_o(apb_pwdata_o), .apb_pready_i(apb_pready_i));

// assign apb_pready_i = pready_i;

// free-running clock
initial clock = 0;
always #5 clock = ~clock;
assign en = 1;
initial begin
    
    $dumpfile("apb_tb.vcd");
    $dumpvars(0, DUT);
    
end
// active low synchronous reset
initial begin
    rst = 1;
    event_a_i = 0;
    event_b_i = 0;
    event_c_i = 0;
    pready_i = 0;
    #10 rst = 0;
    #5 event_a_i = 1;
    #10 {event_a_i,event_b_i} = 2'b01;
    #10 event_b_i = 0;
    #10 pready_i = 1;
    #10 event_b_i = 1;
    pready_i = 0;
    #10 {event_b_i,event_c_i} = 2'b01;
    #10 event_c_i = 0;
    #10 pready_i = 1;
    #10 pready_i = 0;
    #40 pready_i = 1;
    #10 pready_i = 0;
    #50 pready_i = 1;
    #10 pready_i = 0;
end

always @ pready_i begin
    apb_pready_i = pready_i;
end
initial begin
    #250 $finish;
end

endmodule
