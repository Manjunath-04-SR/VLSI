// ============================================================
// Module : id_ex_reg.v
// Purpose: Pipeline register between ID and EX stages
//          Carries datapath values and all control signals
//          flush=1 inserts a NOP bubble (control signals cleared)
// Project: Low-Latency Pipelined RISC-V 32-bit Processor
// ============================================================
module id_ex_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,       // from hazard unit (load-use) or branch/jump

    // ---- data inputs ----
    input  wire [31:0] pc_in,
    input  wire [31:0] rdata1_in,
    input  wire [31:0] rdata2_in,
    input  wire [31:0] imm_in,
    input  wire [4:0]  rs1_in,
    input  wire [4:0]  rs2_in,
    input  wire [4:0]  rd_in,
    input  wire [2:0]  funct3_in,
    input  wire [6:0]  funct7_in,

    // ---- control inputs ----
    input  wire        regwrite_in,
    input  wire        memread_in,
    input  wire        memwrite_in,
    input  wire [1:0]  wb_sel_in,
    input  wire        alusrc_in,
    input  wire        branch_in,
    input  wire        jal_in,
    input  wire        jalr_in,
    input  wire        auipc_in,
    input  wire        lui_in,
    input  wire [1:0]  aluop_in,

    // ---- data outputs ----
    output reg  [31:0] pc_out,
    output reg  [31:0] rdata1_out,
    output reg  [31:0] rdata2_out,
    output reg  [31:0] imm_out,
    output reg  [4:0]  rs1_out,
    output reg  [4:0]  rs2_out,
    output reg  [4:0]  rd_out,
    output reg  [2:0]  funct3_out,
    output reg  [6:0]  funct7_out,

    // ---- control outputs ----
    output reg         regwrite_out,
    output reg         memread_out,
    output reg         memwrite_out,
    output reg  [1:0]  wb_sel_out,
    output reg         alusrc_out,
    output reg         branch_out,
    output reg         jal_out,
    output reg         jalr_out,
    output reg         auipc_out,
    output reg         lui_out,
    output reg  [1:0]  aluop_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            // data
            pc_out       <= 32'b0;
            rdata1_out   <= 32'b0;
            rdata2_out   <= 32'b0;
            imm_out      <= 32'b0;
            rs1_out      <= 5'b0;
            rs2_out      <= 5'b0;
            rd_out       <= 5'b0;
            funct3_out   <= 3'b0;
            funct7_out   <= 7'b0;
            // control (all cleared = NOP)
            regwrite_out <= 1'b0;
            memread_out  <= 1'b0;
            memwrite_out <= 1'b0;
            wb_sel_out   <= 2'b00;
            alusrc_out   <= 1'b0;
            branch_out   <= 1'b0;
            jal_out      <= 1'b0;
            jalr_out     <= 1'b0;
            auipc_out    <= 1'b0;
            lui_out      <= 1'b0;
            aluop_out    <= 2'b00;
        end else begin
            pc_out       <= pc_in;
            rdata1_out   <= rdata1_in;
            rdata2_out   <= rdata2_in;
            imm_out      <= imm_in;
            rs1_out      <= rs1_in;
            rs2_out      <= rs2_in;
            rd_out       <= rd_in;
            funct3_out   <= funct3_in;
            funct7_out   <= funct7_in;
            regwrite_out <= regwrite_in;
            memread_out  <= memread_in;
            memwrite_out <= memwrite_in;
            wb_sel_out   <= wb_sel_in;
            alusrc_out   <= alusrc_in;
            branch_out   <= branch_in;
            jal_out      <= jal_in;
            jalr_out     <= jalr_in;
            auipc_out    <= auipc_in;
            lui_out      <= lui_in;
            aluop_out    <= aluop_in;
        end
    end
endmodule
