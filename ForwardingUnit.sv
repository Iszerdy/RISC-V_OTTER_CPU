`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly San Luis Obispo
// Engineer: Diego Curiel
// Create Date: 02/09/2023 11:30:51 AM
// Module Name: BCG
//////////////////////////////////////////////////////////////////////////////////
// forwarding_unit
// Detects data hazards and generates forwarding controls
module ForwardingUnit(
    input  logic [4:0] DE_EX_rs1,
    input  logic [4:0] DE_EX_rs2,
    input  logic [4:0] EX_MEM_rd,
    input  logic [4:0] MEM_WB_rd,
    input  logic       EX_MEM_RegWrite,
    input  logic       MEM_WB_RegWrite,
    output logic  [1:0] forwardA, // 00 = from regfile (ID/EX), 01 = from WB, 10 = from MEM
    output logic  [1:0] forwardB
);
    always_comb begin
        forwardA = 2'b00;
        forwardB = 2'b00;

        // Forward to EX.rs1
        if (EX_MEM_RegWrite && (EX_MEM_rd != 5'd0) && (EX_MEM_rd == DE_EX_rs1))
            forwardA = 2'b10;
        else if (MEM_WB_RegWrite && (MEM_WB_rd != 5'd0) && (MEM_WB_rd == DE_EX_rs1))
            forwardA = 2'b01;

        // Forward to EX.rs2
        if (EX_MEM_RegWrite && (EX_MEM_rd != 5'd0) && (EX_MEM_rd == DE_EX_rs2))
            forwardB = 2'b10;
        else if (MEM_WB_RegWrite && (MEM_WB_rd != 5'd0) && (MEM_WB_rd == DE_EX_rs2))
            forwardB = 2'b01;
    end
endmodule

