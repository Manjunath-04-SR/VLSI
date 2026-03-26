// ============================================================
// Module : control_unit.v
// Purpose: Main decoder — generates all pipeline control signals
//          from the 7-bit opcode and funct3 field
// Project: Low-Latency Pipelined RISC-V 32-bit Processor
//
// aluop encoding:
//   2'b00 → ADD  (used by load, store, AUIPC, JAL target calc)
//   2'b01 → SUB  (unused; branch comparisons done in top via branch_unit)
//   2'b10 → R/I-type (decode from funct3/funct7 in alu_ctrl)
//   2'b11 → PASS-B (for LUI: result = imm)
//
// wb_sel encoding (write-back data source):
//   2'b00 → ALU result
//   2'b01 → Data memory read
//   2'b10 → PC + 4  (for JAL / JALR)
// ============================================================
module control_unit (
    input  wire [6:0] opcode,
    // outputs
    output reg        regwrite,
    output reg        memread,
    output reg        memwrite,
    output reg  [1:0] wb_sel,    // 00=ALU, 01=MEM, 10=PC+4
    output reg        alusrc,    // 0=reg, 1=imm
    output reg        branch,
    output reg        jal,
    output reg        jalr,
    output reg        auipc,
    output reg        lui,
    output reg  [1:0] aluop
);
    // RV32I opcode map
    localparam OP_R     = 7'b011_0011;  // R-type
    localparam OP_I_ALU = 7'b001_0011;  // I-type ALU (ADDI, ANDI …)
    localparam OP_LOAD  = 7'b000_0011;  // LW, LH, LB, LHU, LBU
    localparam OP_STORE = 7'b010_0011;  // SW, SH, SB
    localparam OP_BRANCH= 7'b110_0011;  // BEQ, BNE, BLT …
    localparam OP_JAL   = 7'b110_1111;  // JAL
    localparam OP_JALR  = 7'b110_0111;  // JALR
    localparam OP_LUI   = 7'b011_0111;  // LUI
    localparam OP_AUIPC = 7'b001_0111;  // AUIPC

    always @(*) begin
        // safe defaults (NOP-like)
        regwrite = 1'b0;
        memread  = 1'b0;
        memwrite = 1'b0;
        wb_sel   = 2'b00;
        alusrc   = 1'b0;
        branch   = 1'b0;
        jal      = 1'b0;
        jalr     = 1'b0;
        auipc    = 1'b0;
        lui      = 1'b0;
        aluop    = 2'b00;

        case (opcode)
            OP_R: begin
                regwrite = 1'b1;
                aluop    = 2'b10;
            end
            OP_I_ALU: begin
                regwrite = 1'b1;
                alusrc   = 1'b1;
                aluop    = 2'b10;
            end
            OP_LOAD: begin
                regwrite = 1'b1;
                memread  = 1'b1;
                alusrc   = 1'b1;
                wb_sel   = 2'b01;
                aluop    = 2'b00;
            end
            OP_STORE: begin
                memwrite = 1'b1;
                alusrc   = 1'b1;
                aluop    = 2'b00;
            end
            OP_BRANCH: begin
                branch   = 1'b1;
                aluop    = 2'b01;   // branch comparator uses forwarded regs directly
            end
            OP_JAL: begin
                regwrite = 1'b1;
                jal      = 1'b1;
                wb_sel   = 2'b10;   // write PC+4 to rd
                aluop    = 2'b00;   // ALU computes PC + imm (jump target, not used for WB)
            end
            OP_JALR: begin
                regwrite = 1'b1;
                jalr     = 1'b1;
                alusrc   = 1'b1;
                wb_sel   = 2'b10;   // write PC+4 to rd
                aluop    = 2'b00;
            end
            OP_LUI: begin
                regwrite = 1'b1;
                lui      = 1'b1;
                alusrc   = 1'b1;
                aluop    = 2'b11;   // PASS-B: result = imm
            end
            OP_AUIPC: begin
                regwrite = 1'b1;
                auipc    = 1'b1;
                alusrc   = 1'b1;
                aluop    = 2'b00;   // ADD: PC + imm
            end
            default: begin /* all-zero NOP */ end
        endcase
    end
endmodule
