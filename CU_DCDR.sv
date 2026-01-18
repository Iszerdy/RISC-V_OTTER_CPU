`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: California Polytechnic University, San Luis Obispo
// Engineer: Diego Renato Curiel
// Create Date: 02/23/2023 09:39:49 AM
// Module Name: CU_DCDR
//////////////////////////////////////////////////////////////////////////////////


module CU_DCDR(
    input logic [31:0] IR,    
    //input logic [31:0] ex_IR,
    input logic BR_EQ,
    input logic BR_LT,
    input logic BR_LTU,
    output logic regWrite,
    output logic memWrite,
    output logic memRead2,
    output logic [3:0] ALU_FUN,
    output logic ALU_SRCA,
    output logic [1:0] ALU_SRCB,
    output logic [1:0] RF_WR_SEL,
    output logic [1:0] PC_SOURCE
    );
    
    logic [6:0] opcode;
    logic [2:0] funct3;
    assign funct3 = IR[14:12];
    assign opcode = IR[6:0];
    
    always_comb begin
        ALU_FUN = 0;
        ALU_SRCA = 0;
        ALU_SRCB = 0;
        PC_SOURCE = 0;
        RF_WR_SEL = 0;
        regWrite = 0;
        memWrite = 0;
        memRead2 = 0;
        
        case (opcode)
            7'b0010111: begin   // AUIPC
                ALU_FUN = 4'b0000;
                ALU_SRCA = 1'b1;
                ALU_SRCB = 2'b11;
                RF_WR_SEL = 2'b11;
                PC_SOURCE = 2'b0;
                regWrite = 1;      //maybe?
                memWrite = 0;
                memRead2 = 0;
            end     
            7'b1101111: begin   // JAL
                ALU_FUN = 0;
                ALU_SRCA = 0;
                ALU_SRCB = 0;
                PC_SOURCE = 2'b11;
                RF_WR_SEL = 0;
                regWrite = 1;
                memWrite = 0;
                memRead2 = 0;
            end
            7'b1100111: begin  // JALR
                ALU_FUN = 4'b0000;
                ALU_SRCA = 0;
                ALU_SRCB = 1;
                PC_SOURCE = 2'b01;
                RF_WR_SEL = 2'b0;
                regWrite = 1;
                memWrite = 0;
                memRead2 = 0;
            end
            7'b0100011: begin    // Store Instructions
                ALU_FUN = 4'b0000;
                ALU_SRCA = 1'b0;
                ALU_SRCB = 2'b10;
                RF_WR_SEL = 2'b0;
                PC_SOURCE = 2'b0;
                regWrite = 0;      // 1?
                memWrite = 1;
                memRead2 = 0;
            end
            7'b0000011: begin // Load Instructions
                ALU_FUN = 4'b0000;
                ALU_SRCA = 1'b0;
                ALU_SRCB = 2'b01;
                RF_WR_SEL = 2'b10;
                regWrite = 1;
                memWrite = 0;
                memRead2 = 1;
            end
            7'b0110111: begin  // LUI
                ALU_SRCA = 1;
                ALU_SRCB = 0;
                ALU_FUN = 4'b1001;
                RF_WR_SEL = 2'b11;
                regWrite = 1;
            end
            7'b0010011: begin // I-Type
                //set constants for all I-type instructions
                RF_WR_SEL = 2'b11;
                ALU_SRCA = 1'b0;
                ALU_SRCB = 2'b01; 
                regWrite = 1;
                memWrite = 0;
                memRead2 = 0;
                //Nested case statement
                //dependent on the function 3 bits
                case (funct3)
                    3'b000: begin ALU_FUN = 4'b0000; end
                    3'b001: begin ALU_FUN = 4'b0001; end
                    3'b010: begin ALU_FUN = 4'b0010; end
                    3'b011: begin ALU_FUN = 4'b0011; end
                    3'b100: begin ALU_FUN = 4'b0100; end
                    3'b101: begin
                        //nested case statement
                        //dependent on the 30th bit for 
                        //instructions that have the same opcode and 
                        //fucntion 3 bits
                        case(IR[30])
                            1'b0: begin ALU_FUN = 4'b0101; end
                            1'b1: begin ALU_FUN = 4'b1101; end
                            default: begin end
                        endcase
                    end
                    3'b110: begin ALU_FUN = 4'b0110; end
                    3'b111: begin ALU_FUN = 4'b0111; end
                endcase
            end
            7'b0110011: begin // R-Type
                //set constants for all R-types;
                //ALU_FUN is just the concatenation of
                //the 30th bit and the function 3 bits
                RF_WR_SEL = 2'b11;
                ALU_SRCA = 0;
                ALU_SRCB = 0;
                PC_SOURCE = 0;
                regWrite = 1;
                memWrite = 0;
                memRead2 = 0;
                        case (funct3)
                            3'b000: begin
                                case (IR[30])
                                    0: ALU_FUN = 4'b0000;
                                    1: ALU_FUN = 4'b1000;
                                    default: begin
                                    end
                                endcase
                            end
                            3'b001: begin ALU_FUN = 4'b0001; end
                            3'b010: begin ALU_FUN = 4'b0010; end
                            3'b011: begin ALU_FUN = 4'b0011; end                                                        
                            3'b100: begin ALU_FUN = 4'b0100; end
                            3'b101: begin
                                case (IR[30])
                                    0: begin ALU_FUN = 4'b0101; end
                                    1: begin ALU_FUN = 4'b1101; end
                                    default: begin end
                                endcase
                            end   
                            3'b110: begin ALU_FUN = 4'b0110; end
                            3'b111: begin ALU_FUN = 4'b0111; end
                            default: begin end
                                
                        endcase
            end
            7'b1100011: begin   //B-Type
                ALU_FUN = 4'b0;
                ALU_SRCA = 1'b0;
                ALU_SRCB = 2'b0;
                RF_WR_SEL = 2'b0;
                regWrite = 0;
                memWrite = 0;
                memRead2 = 0;
                PC_SOURCE = 0;
                case (funct3)
                    3'b000: begin
                        if (BR_EQ)
                            PC_SOURCE = 2'b10;
                        else 
                            PC_SOURCE = 2'b00;
                    end
                    3'b001: begin
                        if (!BR_EQ == 0)
                            PC_SOURCE = 2'b10;
                        else
                            PC_SOURCE = 2'b00;
                    end   
                    3'b100: begin
                        if (BR_LT)
                            PC_SOURCE = 2'b10;
                        else
                            PC_SOURCE = 2'b00;
                    end                 
                    3'b101: begin
                       // if (BR_EQ | !BR_LT)
                        if (!BR_LT)
                            PC_SOURCE = 2'b10;
                        else
                            PC_SOURCE = 2'b00;
                    end
                    3'b110: begin
                        if (BR_LTU)
                            PC_SOURCE = 2'b10;
                        else
                            PC_SOURCE = 2'b00;
                        end                       
                    3'b111: begin
                        //if (BR_EQ | !BR_LTU)
                        if (!BR_LTU)
                            PC_SOURCE = 2'b10;
                        else
                            PC_SOURCE = 2'b00;
                        end
                    default: begin
                        PC_SOURCE = 2'b00;
                    end
                endcase 
            end
        endcase
    end
endmodule       