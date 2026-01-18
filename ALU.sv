`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly San Luis Obispo
// Module Name: ALU
//////////////////////////////////////////////////////////////////////////////////

module ALU(
    input logic [31:0] SRC_A,
    input logic [31:0] SRC_B,
    input logic [3:0] ALU_FUN,
    
    output logic [31:0] RESULT
    );
    
    always_comb begin
        
        case (ALU_FUN)
            4'b0000: RESULT = ($signed(SRC_A) + $signed(SRC_B));                  //ADD
            
            4'b1000: RESULT = $signed(SRC_A) - $signed(SRC_B);                    //SUB
            
            4'b0110: RESULT = SRC_A | SRC_B;                                     //OR
            
            4'b0111: RESULT = SRC_A & SRC_B;                                      //AND
            
            4'b0100: RESULT = SRC_A ^ SRC_B;                                      //XOR
            
            4'b0101: RESULT = SRC_A >> SRC_B[4:0];                                //SRL
            
            4'b0001: RESULT = SRC_A << SRC_B[4:0];                                //SLL
            
            4'b1101: RESULT = $signed(SRC_A) >>> $signed(SRC_B[4:0]);                               //SRA
            
            4'b0010: if ($signed(SRC_A) < $signed(SRC_B))                             //SLT
                        RESULT = 1;
                     else
                        RESULT = 0;
            
            4'b0011: if (SRC_A < SRC_B)                                               //SLTU
                        RESULT = 1;
                     else
                        RESULT = 0;
                        
            4'b1001: RESULT = SRC_A;                                             //LUI-COPY
            
            default: RESULT = 32'hDEADDEAD;                                     //Default
            
        endcase
            
    end
    

endmodule
