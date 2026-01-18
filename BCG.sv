`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly San Luis Obispo
// Engineer: Diego Curiel
// Create Date: 02/09/2023 11:30:51 AM
// Module Name: BCG
//////////////////////////////////////////////////////////////////////////////////



module Modified_BCG(
    input logic [31:0] RS1,
    input logic [31:0] RS2,
    input logic [31:0] ir,
    
    output logic [1:0]PC_SEL
    );
    
    logic br_eq;
    logic br_lt;
    logic br_ltu;
    
    logic [2:0] func3;
    assign func3 = ir[14:12];
    
    logic [6:0] opcode;
    assign opcode = ir[6:0];

    assign br_eq = RS1 == RS2;
    assign br_lt = $signed(RS1) < $signed(RS2);
    assign br_ltu = RS1 < RS2;
    
    
        always_comb begin
            if (opcode == 7'b1100011) begin                   // BEQ, BGE, BGEU, BLT, BLTU, BNE, ( PSEUDO: BEQZ, BGEZ, BGT, BGTU, BGTZ, BLE, BLEU, BLEZ, BLTZ, BNEZ )
                PC_SEL = 2'b00;
                // DEFAULTS FOR ALL B-TYPES

                case (func3)
                    3'b000: begin 
                        if (br_eq) PC_SEL = 2'b10;           // BEQ
                        else PC_SEL = 2'b00; 
                    end
                        
                    3'b101: begin 
                        if (!br_lt) PC_SEL = 2'b10;  // BGE
                        else PC_SEL = 2'b00;
                    end
                                                
                    3'b111: begin 
                        if (!br_ltu) PC_SEL = 2'b10; // BGEU
                        else PC_SEL = 2'b00;
                    end
                        
                    3'b100: begin 
                        if (br_lt) PC_SEL = 2'b10;           // BLT
                        else PC_SEL = 2'b00;
                    end
                                                
                    3'b110: begin 
                        if (br_ltu) PC_SEL = 2'b10;          // BLTU
                        else PC_SEL = 2'b00;
                    end
                        
                    3'b001: begin 
                        if (!br_eq) PC_SEL = 2'b10;      // BNE
                        else PC_SEL = 2'b00;
                    end
                               
                    default: begin 
                        PC_SEL = 'b0;
                    end
                        
                    endcase 
               
            end
            else if (opcode == 7'b1101111) PC_SEL = 2'b11;       // JAL
                                
            else if (opcode == 7'b1100111) PC_SEL = 2'b01;       // JALR
            
            else PC_SEL = 2'b00;
       end
                
endmodule
