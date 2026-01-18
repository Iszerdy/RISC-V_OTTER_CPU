`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: California Polytechnic University, San Luis Obispo
// Module Name: PC
//////////////////////////////////////////////////////////////////////////////////


module PC(
    input logic CLK,
    input logic RST,
    input logic PC_WRITE,
    input logic [31:0] PC_IN,
    output logic [31:0] PC_OUT
    );
    
    always_ff @ (posedge CLK) begin         
        if (RST == 1)                            
            PC_OUT <= 0;  
    
        else if (PC_WRITE == 1)                        
            begin                                   
            PC_OUT <= PC_IN;
            end
                    
    end


endmodule
