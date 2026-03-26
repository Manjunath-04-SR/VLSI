// ============================================================
// Module : ex_mem_reg.v
// Purpose: Pipeline register between EX and MEM stages
// Project: Low-Latency Pipelined RISC-V 32-bit Processor
// ============================================================
module ex_mem_reg (
    input  wire        clk,
    input  wire        rst,

    // ---- data inputs ----
    input  wire [31:0] pc_plus4_in,     // PC+4 (for JAL/JALR wb)
    input  wire [31:0] alu_result_in,
    input  wire [31:0] rdata2_in,       // forwarded rs2 value (for stores)
    input  wire [4:0]  rd_in,
    input  wire [2:0]  funct3_in,

    // ---- control inputs ----
    input  wire        regwrite_in,
    input  wire        memread_in,
    input  wire        memwrite_in,
    input  wire [1:0]  wb_sel_in,

    // ---- data outputs ----
    output reg  [31:0] pc_plus4_out,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] rdata2_out,
    output reg  [4:0]  rd_out,
    output reg  [2:0]  funct3_out,

    // ---- control outputs ----
    output reg         regwrite_out,
    output reg         memread_out,
    output reg         memwrite_out,
    output reg  [1:0]  wb_sel_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_plus4_out  <= 32'b0;
            alu_result_out<= 32'b0;
            rdata2_out    <= 32'b0;
            rd_out        <= 5'b0;
            funct3_out    <= 3'b0;
            regwrite_out  <= 1'b0;
            memread_out   <= 1'b0;
            memwrite_out  <= 1'b0;
            wb_sel_out    <= 2'b00;
        end else begin
            pc_plus4_out  <= pc_plus4_in;
            alu_result_out<= alu_result_in;
            rdata2_out    <= rdata2_in;
            rd_out        <= rd_in;
            funct3_out    <= funct3_in;
            regwrite_out  <= regwrite_in;
            memread_out   <= memread_in;
            memwrite_out  <= memwrite_in;
            wb_sel_out    <= wb_sel_in;
        end
    end
endmodule
