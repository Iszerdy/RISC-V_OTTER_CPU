`timescale 1ns / 1ps 
typedef enum logic [6:0] {
       LUI      = 7'b0110111,
       AUIPC    = 7'b0010111,
       JAL      = 7'b1101111,
       JALR     = 7'b1100111,
       BRANCH   = 7'b1100011,
       LOAD     = 7'b0000011,
       STORE    = 7'b0100011,
       OP_IMM   = 7'b0010011,
       OP       = 7'b0110011,
       SYSTEM   = 7'b1110011
} opcode_t;
 
typedef struct packed{
    opcode_t opcode;
    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    logic [4:0] rd_addr;
    logic rs1_used;
    logic rs2_used;
    logic rd_used;
    logic [3:0] alu_fun;
    logic SRC_A;
    logic [1:0] SRC_B;
    logic memWrite;
    logic memRead2;
    logic regWrite;
    logic [1:0] rf_wr_sel;
    logic [2:0] mem_type;  
    logic [31:0] pc;
    logic [31:0] ir;
    
    logic [31:0] U_immed;
    logic [31:0] I_immed;
    logic [31:0] S_immed;
    logic [31:0] J_type;
    logic [31:0] B_type;

} instr_t;

module OTTER(input CLK,
                input INTR,
                input RESET,
                input [31:0] IOBUS_IN,
                
                output [31:0] IOBUS_OUT,
                output [31:0] IOBUS_ADDR,
                output logic IOBUS_WR 
);  
    logic [31:0] pc, next_pc, jalr_pc, branch_pc, jump_pc;
    logic [31:0] IR;
    logic [31:0] rfIn;
    logic [31:0] dout2;
    
    logic [31:0] aluResult;
    
    logic memRead1;
    logic pcWrite;
    
    logic br_lt, br_eq, br_ltu;
    logic [1:0] pc_sel;
    
    logic de_alu_src_a;
    logic [1:0] de_alu_src_b;
    logic [31:0] de_alu_src_a_out, de_alu_src_b_out;

    logic [3:0] de_alu_fun;
    logic [1:0] de_rf_wr_sel;
    
    logic [1:0] forwardA, forwardB, forwardedA, forwardedB;
    logic rs1_used, rs2_used;
    logic load_use_haz, control_haz, FLUSH;
    logic [1:0] flush_cnt;
    
    
    logic hit, miss, pc_stall, update, hazard_cnt_stall;
    logic[31:0] w0, w1, w2, w3, w4, w5, w6, w7;
           
    logic ex_mem_alu_src_a;
    logic [1:0] ex_mem_alu_src_b;
    logic [31:0] fwd_mux_A;
    logic [31:0] fwd_mux_B;
    
    logic [31:0] ex_mem_rs1, ex_mem_rs2;
    logic [31:0] EX_alu_result;
    logic [31:0] MEM_alu_result;
    logic [31:0] WB_alu_result;
    
    logic [31:0] MEM_rs1, MEM_rs2;
    logic [31:0] MEMDIN2;
    logic [4:0] HOLD_rd_addr;
    logic [31:0] HOLD_rfIn;
        
    logic [31:0] SRC_A;
    logic [31:0] SRC_B;
    logic [31:0] de_ex_rs1, de_ex_rs2;
   
    //pipeline registers
    instr_t if_de_inst, de_ex_inst, ex_mem_inst, mem_wb_inst;
            
//==== Instruction Fetch =================================================================================================================

     logic STALL;
     logic HOLD_FLUSH;
     assign STALL = hazard_cnt_stall;
     
     always_ff @(posedge CLK) begin
        HOLD_FLUSH <= FLUSH;
        if (!STALL)        
            next_pc <= pc;
          
     end
     
     assign pcWrite = !STALL; 	
     assign memRead1 = !STALL;	
     logic [31:0] pc_din;           
     
     logic [31:0] pc_plus_4;
     assign pc_plus_4 = pc + 4;  
     
     // PC MUX
     always_comb begin                          
        case (pc_sel)                           
            2'b00: pc_din = pc_plus_4;        
            2'b01: pc_din = jalr_pc;
            2'b10: pc_din = branch_pc;
            2'b11: pc_din = jump_pc;
            default pc_din = 32'hDEADDEAD;       
        endcase
    end
    
    PC PC(
        .CLK(CLK),
        .RST(RESET), 
        .PC_WRITE(pcWrite), 
        .PC_IN(pc_din),
        .PC_OUT(pc)
    );
    
        CacheFSM CacheFSM(
        .hit(hit),
        .miss(miss),
        .CLK(CLK),
        .RST(RESET),        //RESET not RST 
        .update(update),
        .pc_stall(pc_stall)     
    );
    
    Cache Cache(
        .PC(pc),
        .CLK(CLK),
        .update(update),
        .w0(w0),
        .w1(w1),
        .w2(w2),
        .w3(w3),
        .w4(w4),
        .w5(w5),
        .w6(w6),
        .w7(w7),
        .rd(IR),
        .hit(hit),
        .miss(miss)
    );
    
    imem imem(      
        .a(pc),
        .w0(w0),
        .w1(w1),
        .w2(w2),
        .w3(w3),
        .w4(w4),
        .w5(w5),
        .w6(w6),
        .w7(w7)
    );
     
     Memory OTTER_MEMORY(
    .MEM_CLK(CLK),
    .MEM_RDEN2(memRead2),
    .MEM_WE2(memWrite),
    .MEM_ADDR2(MEM_alu_result),
    .MEM_DIN2(MEM_rs2),
    .MEM_DOUT2(dout2)
);

//==== Instruction Decode ================================================================================================================

    assign if_de_inst.ir = IR;
    
    logic [6:0] opcode;
    assign if_de_inst.pc = next_pc;
    assign if_de_inst.rs1_addr=IR[19:15];
    assign if_de_inst.rs2_addr=IR[24:20];
    assign if_de_inst.rd_addr=IR[11:7];
    assign if_de_inst.opcode = opcode_t'(if_de_inst.ir[6:0]);

    
    REG_FILE regfile(
        .CLK (CLK),
        .EN (mem_wb_inst.regWrite),
        .ADR1 (if_de_inst.rs1_addr),
        .ADR2 (if_de_inst.rs2_addr),
        .WA (mem_wb_inst.rd_addr),
        .WD (rfIn),
        .RS1 (de_ex_rs1),
        .RS2 (de_ex_rs2)
    );
    
    ImmediateGenerator ImmedGen (
        .IR(if_de_inst.ir[31:7]),
        .U_TYPE(if_de_inst.U_immed),
        .I_TYPE(if_de_inst.I_immed),
        .S_TYPE(if_de_inst.S_immed),
        .B_TYPE(if_de_inst.B_type),
        .J_TYPE(if_de_inst.J_type)
    );
    
    // AluA_mux
    always_comb begin
        case (ex_mem_alu_src_a)
            1'b0: SRC_A = fwd_mux_A;
            1'b1: SRC_A = de_ex_inst.U_immed;
            default:
                SRC_A = 32'hDEADDEAD;
        endcase
    end

    // AluB_mux
    always_comb begin
        case (ex_mem_alu_src_b)
            2'b00: SRC_B = fwd_mux_B;
            2'b01: SRC_B = de_ex_inst.I_immed;
            2'b10: SRC_B = de_ex_inst.S_immed;
            2'b11: SRC_B = de_ex_inst.pc;
            default:
                SRC_B = 32'hDEADDEAD;
        endcase
    end

    CU_DCDR CU_DCDR (
        .IR( if_de_inst.ir),
        .BR_EQ( br_eq ),
        .BR_LT( br_lt ),
        .BR_LTU( br_ltu),
        .regWrite( if_de_inst.regWrite ),
        .memWrite( if_de_inst.memWrite ),
        .memRead2( if_de_inst.memRead2 ),
        .ALU_FUN( if_de_inst.alu_fun ),
        .ALU_SRCA(de_alu_src_a),                                                    
        .ALU_SRCB( de_alu_src_b ),        
        .RF_WR_SEL( if_de_inst.rf_wr_sel)
        //.PC_SOURCE(pc_sel)
    );
    
    BAG branch_addr_gen (
        .RS1(fwd_mux_A),
        .I_TYPE(de_ex_inst.I_immed),
        .J_TYPE(de_ex_inst.J_type),  
        .B_TYPE(de_ex_inst.B_type),
        .FROM_PC(de_ex_inst.pc),
        .JAL(jump_pc),
        .JALR(jalr_pc),
        .BRANCH(branch_pc)
    );
    
    logic de_ex_alu_src_a;
    assign de_ex_alu_src_a = de_alu_src_a;
    logic [1:0] de_ex_alu_src_b;
    assign de_ex_alu_src_b = de_alu_src_b;
    
    // DE/EX Pipeline Register 
     always_ff @(posedge CLK) begin
        de_ex_inst <= if_de_inst;
        if (HOLD_FLUSH || FLUSH || STALL) begin        
            de_ex_inst.regWrite <= 0;
            de_ex_inst.memWrite <= 0;
            de_ex_inst.ir <= 0;
        end
        ex_mem_alu_src_a <= de_ex_alu_src_a;
        ex_mem_alu_src_b <= de_ex_alu_src_b;        
        ex_mem_rs1 <= de_ex_rs1;
        ex_mem_rs2 <= de_ex_rs2;
     end
    
    logic [1:0] fsel1;
    logic [1:0] fsel2;
    
   
    assign if_de_inst.rs1_used=   if_de_inst.rs1_addr != 0 
                                && if_de_inst.opcode != LUI
                                && if_de_inst.opcode != AUIPC
                                && if_de_inst.opcode != JAL;
                                
    assign if_de_inst.rs2_used=   if_de_inst.rs2_addr != 0 
                                && if_de_inst.opcode != LUI
                                && if_de_inst.opcode != AUIPC
                                && if_de_inst.opcode != JAL
                                && if_de_inst.opcode != LOAD
                                && if_de_inst.opcode != OP_IMM
                                && if_de_inst.opcode != JALR;
                                
     assign if_de_inst.rd_used =  if_de_inst.rd_addr != 0
                                && if_de_inst.opcode != BRANCH
                                && if_de_inst.opcode != STORE;
                                     
	
//==== Execute =================================================================================================================
    logic [1:0] DEC_fsel1;
    logic [1:0] DEC_fsel2;
    logic [6:0] ex_opcode;
    assign ex_opcode = de_ex_inst.ir[6:0];
 
    Modified_BCG BCG (
        .RS1(fwd_mux_A),
        .RS2(fwd_mux_B),
        .ir(de_ex_inst.ir),
        
        .PC_SEL(pc_sel)
        
    );    

    HazardDetectionUnit fwd_hzrd_unit(
        .de_adr1(if_de_inst.rs1_addr),
        .de_adr2(if_de_inst.rs2_addr),
        .ex_opcode(ex_opcode), 
        .ex_adr1(de_ex_inst.rs1_addr),
        .ex_adr2(de_ex_inst.rs2_addr),
        .ex_rd(de_ex_inst.rd_addr),
        .mem_rd(ex_mem_inst.rd_addr),
        .wb_rd(mem_wb_inst.rd_addr),
        .pc_source(pc_sel),
        .mem_regwrite(ex_mem_inst.regWrite),
        .wb_regwrite(mem_wb_inst.regWrite),
        .de_rs1_used(if_de_inst.rs1_used),
        .de_rs2_used(if_de_inst.rs2_used),
        .ex_rs1_used(de_ex_inst.rs1_used),
        .ex_rs2_used(de_ex_inst.rs2_used),
        .fsel1(fsel1),
        .fsel2(fsel2),
        .STALL(hazard_cnt_stall),
        .FLUSH(FLUSH)
    );
   
    // AluA_fwd_mux
    always_comb begin
        case (fsel1)
            2'b00: fwd_mux_A = ex_mem_rs1;
            2'b01: fwd_mux_A = MEM_alu_result;
            2'b10: fwd_mux_A = rfIn;
            default:
                fwd_mux_A = 32'hDEADDEAD;
        endcase
    end
        
    // AluB_fwd_mux
    always_comb begin
        case(fsel2)
            2'b00: fwd_mux_B = ex_mem_rs2;
            2'b01: fwd_mux_B = MEM_alu_result;
            2'b10: fwd_mux_B = rfIn;
            default:
                fwd_mux_B = 32'hDEADDEAD;
        endcase
    end
    
    ALU alu (
        .SRC_A(SRC_A),
        .SRC_B(SRC_B),
        .ALU_FUN(de_ex_inst.alu_fun),
        .RESULT(EX_alu_result)
    );
    
    // EX/MEM Pipeline Register
    always_ff @(posedge CLK) begin
        ex_mem_inst <= de_ex_inst;
        MEM_alu_result <= EX_alu_result;
        
        MEM_rs1 <= fwd_mux_A;
        MEM_rs2 <= fwd_mux_B;
     end
//==== Memory =================================================================================================================
    assign IOBUS_ADDR = MEM_alu_result;
    assign IOBUS_OUT = MEM_rs2;
    assign IOBUS_WR = hit;
    
    always_comb begin 
        if (ex_mem_inst.opcode == STORE) begin
            MEMDIN2 = rfIn;
            if (HOLD_rd_addr == ex_mem_inst.rs2_addr) MEMDIN2 = HOLD_rfIn;
        end
        else MEMDIN2 = MEM_rs2;
    end
    
    // MEM/WB Pipeline Register
     always_ff @(posedge CLK) begin
        mem_wb_inst <= ex_mem_inst;
        WB_alu_result <= MEM_alu_result;
        HOLD_rfIn <= rfIn;
     end
     
//==== Write Back =================================================================================================================
     
    logic [31:0] CSR_REG = 32'b0;
     
    // regmux
    always_comb begin
        case (mem_wb_inst.rf_wr_sel) 
            2'b00:
                rfIn = mem_wb_inst.pc+4;
            2'b01:
                rfIn = CSR_REG;
            2'b10:
                rfIn = dout2;
            2'b11:
                rfIn = WB_alu_result;
            default:
                rfIn = 32'hDEADDEAD;
        endcase
    end
  
    always_ff @ (posedge CLK) begin
        HOLD_rd_addr <= mem_wb_inst.rd_addr;
    end
endmodule
