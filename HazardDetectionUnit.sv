`timescale 1ns / 1ps


module HazardDetectionUnit(
    input logic [4:0] de_adr1,
    input logic [4:0] de_adr2,
    input logic [6:0] ex_opcode,    // ADDED: Need to check if EX instruction is a LOAD; note, might not be needed, added for debugging
    input logic [4:0] ex_adr1,
    input logic [4:0] ex_adr2,
    input logic [4:0] ex_rd,
    input logic [4:0] mem_rd,
    input logic [4:0] wb_rd,
    input logic [1:0] pc_source,
    input logic mem_regwrite,
    input logic wb_regwrite,
    input logic de_rs1_used,
    input logic de_rs2_used,
    input logic ex_rs1_used,
    input logic ex_rs2_used,

    output logic [1:0] fsel1,
    output logic [1:0] fsel2,
    output logic STALL,
    output logic FLUSH
    );
    
    assign ex_is_load = (ex_opcode == 7'b0000011);  // LOAD opcode

    always_comb begin
        fsel1 = 2'b00;
        fsel2 = 2'b00;

        STALL = 1'b0;
        FLUSH = 1'b0;

        if (mem_rd == ex_adr1 && ex_rs1_used && mem_regwrite) begin
            fsel1 = 2'b01;  // Forward from MEM stage
        end
        else if (wb_rd == ex_adr1 && ex_rs1_used && wb_regwrite) begin
            fsel1 = 2'b10;  // Forward from WB stage
        end
        else begin
            fsel1 = 2'b00;
        end
        
        
        if (mem_rd == ex_adr2 && ex_rs2_used && mem_regwrite) begin
            fsel2 = 2'b01;  // Forward from MEM stage
        end 
        else if (wb_rd == ex_adr2 && ex_rs2_used && wb_regwrite) begin
            fsel2 = 2'b10;  // Forward from WB stage
        end 
        else begin 
            fsel2 = 2'b00;
        end

        // Only stall if EX stage has a LOAD instruction and there's a data dependency
        if ((ex_is_load) && ((de_adr1 == ex_rd && de_rs1_used) || (de_adr2 == ex_rd && de_rs2_used))) begin
            STALL = 1'b1;
        end 
        else begin
            STALL = 1'b0;
        end
        
        // Control Hazards (JAL, JALR, Branches taken)
        if (pc_source != 2'b0) begin    // Branch taken, JAL, or JALR
            FLUSH = 'b1;
        end 
        else begin
            FLUSH = 'b0;
        end
    end

endmodule