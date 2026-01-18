`timescale 1ns / 1ps

module Memory (
    input logic MEM_CLK,
    input logic MEM_RDEN2,      
    input logic MEM_WE2,     
    input logic [31:0] MEM_ADDR2,        
    input logic [31:0] MEM_DIN2,      
    output logic [31:0] MEM_DOUT2       
);

    logic [31:0] mem [0:1023];

    logic [9:0] wordAddr;
    assign wordAddr = MEM_ADDR2[31:2];

    always_ff @(posedge MEM_CLK) begin
        if (MEM_WE2) begin
            mem[wordAddr] <= MEM_DIN2;
        end
    end

    always_comb begin
        if (MEM_RDEN2)
            MEM_DOUT2 = mem[wordAddr];
        else
            MEM_DOUT2 = 32'b0;
    end

endmodule

 
