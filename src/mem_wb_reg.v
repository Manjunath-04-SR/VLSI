// ============================================================
// Module : mem_wb_reg.v
// Purpose: Pipeline register between MEM and WB stages
// Project: Low-Latency Pipelined RISC-V 32-bit Processor
// ============================================================
module mem_wb_reg (
    input  wire        clk,
    input  wire        rst,

    // ---- data inputs ----
    input  wire [31:0] pc_plus4_in,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] mem_rdata_in,
    input  wire [4:0]  rd_in,

    // ---- control inputs ----
    input  wire        regwrite_in,
    input  wire [1:0]  wb_sel_in,

    // ---- data outputs ----
    output reg  [31:0] pc_plus4_out,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] mem_rdata_out,
    output reg  [4:0]  rd_out,

    // ---- control outputs ----
    output reg         regwrite_out,
    output reg  [1:0]  wb_sel_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_plus4_out  <= 32'b0;
            alu_result_out<= 32'b0;
            mem_rdata_out <= 32'b0;
            rd_out        <= 5'b0;
            regwrite_out  <= 1'b0;
            wb_sel_out    <= 2'b00;
        end else begin
            pc_plus4_out  <= pc_plus4_in;
            alu_result_out<= alu_result_in;
            mem_rdata_out <= mem_rdata_in;
            rd_out        <= rd_in;
            regwrite_out  <= regwrite_in;
            wb_sel_out    <= wb_sel_in;
        end
    end
endmodule
