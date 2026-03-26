// ============================================================
// Module : riscv_top.v
// Purpose: Top-level integration of the 5-stage pipelined
//          RISC-V 32-bit (RV32I) processor
//
// Pipeline stages:
//   IF  → IF/ID reg → ID → ID/EX reg → EX → EX/MEM reg
//       → MEM → MEM/WB reg → WB
//
// Hazard handling:
//   • Data hazards    : forwarding unit (EX→EX, MEM→EX)
//   • Load-use stall  : hazard detection unit (1-cycle stall)
//   • Control hazards : branch/jump resolved in EX, flush 2 stages
//
// Project: Low-Latency Pipelined RISC-V 32-bit Processor
// ============================================================
module riscv_top (
    input wire clk,
    input wire rst
);

// ========================================================
// ---- IF stage wires ----
// ========================================================
wire [31:0] pc_if;          // current PC
wire [31:0] pc_plus4_if;    // PC + 4 (default next PC)
wire [31:0] instr_if;       // fetched instruction

// ========================================================
// ---- IF/ID register outputs ----
// ========================================================
wire [31:0] pc_id;
wire [31:0] instr_id;

// ========================================================
// ---- ID stage wires ----
// ========================================================
wire [4:0]  rs1_id   = instr_id[19:15];
wire [4:0]  rs2_id   = instr_id[24:20];
wire [4:0]  rd_id    = instr_id[11:7];
wire [2:0]  funct3_id= instr_id[14:12];
wire [6:0]  funct7_id= instr_id[31:25];

wire [31:0] rdata1_id, rdata2_id;
wire [31:0] imm_id;

// Control signals from decoder
wire        regwrite_id, memread_id, memwrite_id;
wire [1:0]  wb_sel_id;
wire        alusrc_id, branch_id, jal_id, jalr_id, auipc_id, lui_id;
wire [1:0]  aluop_id;

// Hazard unit
wire        stall;              // freeze PC + IF/ID
wire        id_ex_flush;        // flush ID/EX on load-use stall OR branch/jump

// ========================================================
// ---- ID/EX register outputs ----
// ========================================================
wire [31:0] pc_ex, rdata1_ex, rdata2_ex, imm_ex;
wire [4:0]  rs1_ex, rs2_ex, rd_ex;
wire [2:0]  funct3_ex;
wire [6:0]  funct7_ex;
wire        regwrite_ex, memread_ex, memwrite_ex;
wire [1:0]  wb_sel_ex;
wire        alusrc_ex, branch_ex, jal_ex, jalr_ex, auipc_ex, lui_ex;
wire [1:0]  aluop_ex;

// ========================================================
// ---- EX stage wires ----
// ========================================================
wire [1:0]  forward_a, forward_b;
wire [31:0] rdata1_fwd, rdata2_fwd;    // after forwarding muxes
wire [31:0] alu_op_a, alu_op_b;
wire [3:0]  alu_ctrl_ex;
wire [31:0] alu_result_ex;
wire        alu_zero_ex;                // unused; branch uses comparator below

// Branch condition comparator (dedicated, uses forwarded values)
wire        branch_taken;
wire        jump_taken;
wire        flush_pipe;                 // flush IF/ID and ID/EX
wire [31:0] pc_plus4_ex;               // PC+4 of EX instruction (for JAL/JALR WB)
wire [31:0] jump_target;               // next PC on branch or jump

// ========================================================
// ---- EX/MEM register outputs ----
// ========================================================
wire [31:0] pc_plus4_mem, alu_result_mem, rdata2_mem;
wire [4:0]  rd_mem;
wire [2:0]  funct3_mem;
wire        regwrite_mem, memread_mem, memwrite_mem;
wire [1:0]  wb_sel_mem;

// ========================================================
// ---- MEM stage wires ----
// ========================================================
wire [31:0] mem_rdata_mem;

// ========================================================
// ---- MEM/WB register outputs ----
// ========================================================
wire [31:0] pc_plus4_wb, alu_result_wb, mem_rdata_wb;
wire [4:0]  rd_wb;
wire        regwrite_wb;
wire [1:0]  wb_sel_wb;

// ========================================================
// ---- WB stage ----
// ========================================================
wire [31:0] wb_data;    // final write-back data fed to regfile & forwarding


// ========================================================
// ========================  IF STAGE  ====================
// ========================================================

assign pc_plus4_if = pc_if + 32'd4;

// PC-next mux (priority: flush overrides stall overrides increment)
wire [31:0] pc_next;
assign pc_next = flush_pipe ? jump_target :
                 stall      ? pc_if       :
                              pc_plus4_if;

pc_reg PC (
    .clk    (clk),
    .rst    (rst),
    .stall  (stall),
    .pc_next(pc_next),
    .pc     (pc_if)
);

instr_mem IMEM (
    .addr  (pc_if),
    .instr (instr_if)
);

if_id_reg IF_ID (
    .clk      (clk),
    .rst      (rst),
    .flush    (flush_pipe),
    .stall    (stall),
    .pc_in    (pc_if),
    .instr_in (instr_if),
    .pc_out   (pc_id),
    .instr_out(instr_id)
);


// ========================================================
// ========================  ID STAGE  ====================
// ========================================================

control_unit CTRL (
    .opcode  (instr_id[6:0]),
    .regwrite(regwrite_id),
    .memread (memread_id),
    .memwrite(memwrite_id),
    .wb_sel  (wb_sel_id),
    .alusrc  (alusrc_id),
    .branch  (branch_id),
    .jal     (jal_id),
    .jalr    (jalr_id),
    .auipc   (auipc_id),
    .lui     (lui_id),
    .aluop   (aluop_id)
);

regfile RF (
    .clk      (clk),
    .regwrite (regwrite_wb),
    .rs1      (rs1_id),
    .rs2      (rs2_id),
    .rd       (rd_wb),
    .wdata    (wb_data),
    .rdata1   (rdata1_id),
    .rdata2   (rdata2_id)
);

imm_gen IGN (
    .instr(instr_id),
    .imm  (imm_id)
);

// Hazard detection: load-use stall
hazard_unit HDU (
    .id_ex_memread(memread_ex),
    .id_ex_rd     (rd_ex),
    .if_id_rs1    (rs1_id),
    .if_id_rs2    (rs2_id),
    .stall        (stall)
);

// ID/EX flush: load-use stall OR branch/jump resolved in EX
assign id_ex_flush = stall || flush_pipe;

id_ex_reg ID_EX (
    .clk        (clk),
    .rst        (rst),
    .flush      (id_ex_flush),
    .pc_in      (pc_id),
    .rdata1_in  (rdata1_id),
    .rdata2_in  (rdata2_id),
    .imm_in     (imm_id),
    .rs1_in     (rs1_id),
    .rs2_in     (rs2_id),
    .rd_in      (rd_id),
    .funct3_in  (funct3_id),
    .funct7_in  (funct7_id),
    .regwrite_in(regwrite_id),
    .memread_in (memread_id),
    .memwrite_in(memwrite_id),
    .wb_sel_in  (wb_sel_id),
    .alusrc_in  (alusrc_id),
    .branch_in  (branch_id),
    .jal_in     (jal_id),
    .jalr_in    (jalr_id),
    .auipc_in   (auipc_id),
    .lui_in     (lui_id),
    .aluop_in   (aluop_id),
    .pc_out     (pc_ex),
    .rdata1_out (rdata1_ex),
    .rdata2_out (rdata2_ex),
    .imm_out    (imm_ex),
    .rs1_out    (rs1_ex),
    .rs2_out    (rs2_ex),
    .rd_out     (rd_ex),
    .funct3_out (funct3_ex),
    .funct7_out (funct7_ex),
    .regwrite_out(regwrite_ex),
    .memread_out (memread_ex),
    .memwrite_out(memwrite_ex),
    .wb_sel_out  (wb_sel_ex),
    .alusrc_out  (alusrc_ex),
    .branch_out  (branch_ex),
    .jal_out     (jal_ex),
    .jalr_out    (jalr_ex),
    .auipc_out   (auipc_ex),
    .lui_out     (lui_ex),
    .aluop_out   (aluop_ex)
);


// ========================================================
// ========================  EX STAGE  ====================
// ========================================================

// --- WB data for MEM→EX forwarding ---
assign wb_data = (wb_sel_wb == 2'b01) ? mem_rdata_wb  :
                 (wb_sel_wb == 2'b10) ? pc_plus4_wb   :
                                        alu_result_wb;

forward_unit FU (
    .ex_mem_regwrite(regwrite_mem),
    .ex_mem_rd      (rd_mem),
    .mem_wb_regwrite(regwrite_wb),
    .mem_wb_rd      (rd_wb),
    .id_ex_rs1      (rs1_ex),
    .id_ex_rs2      (rs2_ex),
    .forward_a      (forward_a),
    .forward_b      (forward_b)
);

// Forwarding muxes for rs1 and rs2
assign rdata1_fwd = (forward_a == 2'b10) ? alu_result_mem :
                    (forward_a == 2'b01) ? wb_data        :
                                           rdata1_ex;

assign rdata2_fwd = (forward_b == 2'b10) ? alu_result_mem :
                    (forward_b == 2'b01) ? wb_data        :
                                           rdata2_ex;

// ALU operand A: normal rs1, or PC (for AUIPC / JAL target), or 0 (for LUI)
assign alu_op_a = auipc_ex             ? pc_ex      :
                  lui_ex               ? 32'b0      :
                  (jal_ex || jalr_ex)  ? pc_ex      :  // target = PC + imm
                                         rdata1_fwd;

// ALU operand B: register or immediate
assign alu_op_b = alusrc_ex ? imm_ex : rdata2_fwd;

alu_ctrl ALUCTL (
    .aluop   (aluop_ex),
    .funct3  (funct3_ex),
    .funct7  (funct7_ex),
    .alu_ctrl(alu_ctrl_ex)
);

alu ALU (
    .a       (alu_op_a),
    .b       (alu_op_b),
    .alu_ctrl(alu_ctrl_ex),
    .result  (alu_result_ex),
    .zero    (alu_zero_ex)
);

// --- Branch condition comparator (all RV32I branch types) ---
reg branch_cond;
always @(*) begin
    case (funct3_ex)
        3'b000: branch_cond = (rdata1_fwd == rdata2_fwd);                      // BEQ
        3'b001: branch_cond = (rdata1_fwd != rdata2_fwd);                      // BNE
        3'b100: branch_cond = ($signed(rdata1_fwd) <  $signed(rdata2_fwd));    // BLT
        3'b101: branch_cond = ($signed(rdata1_fwd) >= $signed(rdata2_fwd));    // BGE
        3'b110: branch_cond = (rdata1_fwd <  rdata2_fwd);                      // BLTU
        3'b111: branch_cond = (rdata1_fwd >= rdata2_fwd);                      // BGEU
        default: branch_cond = 1'b0;
    endcase
end

assign branch_taken = branch_ex && branch_cond;
assign jump_taken   = jal_ex   || jalr_ex;
assign flush_pipe   = branch_taken || jump_taken;

// --- Jump / branch target ---
wire [31:0] jal_target  = pc_ex + imm_ex;                          // JAL: PC + J-imm
wire [31:0] jalr_target = (rdata1_fwd + imm_ex) & 32'hFFFF_FFFE;  // JALR: (rs1+imm)&~1
wire [31:0] branch_target = pc_ex + imm_ex;                        // BXX: PC + B-imm

assign jump_target = jalr_ex      ? jalr_target   :
                     jal_ex       ? jal_target     :
                                    branch_target;

assign pc_plus4_ex = pc_ex + 32'd4;

// EX/MEM register
ex_mem_reg EX_MEM (
    .clk           (clk),
    .rst           (rst),
    .pc_plus4_in   (pc_plus4_ex),
    .alu_result_in (alu_result_ex),
    .rdata2_in     (rdata2_fwd),     // forwarded rs2 for store data
    .rd_in         (rd_ex),
    .funct3_in     (funct3_ex),
    .regwrite_in   (regwrite_ex),
    .memread_in    (memread_ex),
    .memwrite_in   (memwrite_ex),
    .wb_sel_in     (wb_sel_ex),
    .pc_plus4_out  (pc_plus4_mem),
    .alu_result_out(alu_result_mem),
    .rdata2_out    (rdata2_mem),
    .rd_out        (rd_mem),
    .funct3_out    (funct3_mem),
    .regwrite_out  (regwrite_mem),
    .memread_out   (memread_mem),
    .memwrite_out  (memwrite_mem),
    .wb_sel_out    (wb_sel_mem)
);


// ========================================================
// ======================== MEM STAGE =====================
// ========================================================

data_mem DMEM (
    .clk     (clk),
    .memread (memread_mem),
    .memwrite(memwrite_mem),
    .funct3  (funct3_mem),
    .addr    (alu_result_mem),
    .wdata   (rdata2_mem),
    .rdata   (mem_rdata_mem)
);

mem_wb_reg MEM_WB (
    .clk           (clk),
    .rst           (rst),
    .pc_plus4_in   (pc_plus4_mem),
    .alu_result_in (alu_result_mem),
    .mem_rdata_in  (mem_rdata_mem),
    .rd_in         (rd_mem),
    .regwrite_in   (regwrite_mem),
    .wb_sel_in     (wb_sel_mem),
    .pc_plus4_out  (pc_plus4_wb),
    .alu_result_out(alu_result_wb),
    .mem_rdata_out (mem_rdata_wb),
    .rd_out        (rd_wb),
    .regwrite_out  (regwrite_wb),
    .wb_sel_out    (wb_sel_wb)
);


// ========================================================
// ========================  WB STAGE  ====================
// ========================================================
// wb_data is already computed above (used by forwarding too)
// RF write is driven directly into regfile from WB stage signals

endmodule
