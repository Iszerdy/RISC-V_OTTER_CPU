`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: California Polytechnic University, San Luis Obispo
// Engineer: Diego Curiel
// Create Date: 01/31/2023 09:24:40 AM
// Module Name: REG_FILE
// Project Name: OTTER
//////////////////////////////////////////////////////////////////////////////////


        
module REG_FILE(
    input logic CLK,
    input logic EN,
    input logic [4:0] ADR1,
    input logic [4:0] ADR2,
    input logic [4:0] WA,
    input logic [31:0] WD,
    
    output logic [31:0] RS1,
    output logic [31:0] RS2 
    );
    
    logic [31:0] RAM [0:31];                    //Create RAM
    
    initial begin
        int i;
        for (i=0; i<32; i=i+1) begin
            RAM[i] = 0;
        end
    end
    
    
    always_ff @ (negedge CLK) begin           
    
        if ((EN == 1) && (WA != 0))
            RAM[WA] <= WD;
           
        else
            RAM[WA] <= RAM[WA];
            
    end
    
    

    assign RS1 = RAM[ADR1];
    assign RS2 = RAM[ADR2];
    
    
    
    
endmodule