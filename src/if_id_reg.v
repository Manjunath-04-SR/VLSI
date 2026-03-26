// ============================================================
// Module : if_id_reg.v
// Purpose: Pipeline register between IF and ID stages
//          Supports flush (branch/jump) and stall (load-use)
// Project: Low-Latency Pipelined RISC-V 32-bit Processor
// ============================================================
module if_id_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,   // insert NOP bubble on branch/jump taken
    input  wire        stall,   // hold current content on load-use stall
    // --- inputs from IF ---
    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in,
    // --- outputs to ID ---
    output reg  [31:0] pc_out,
    output reg  [31:0] instr_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc_out    <= 32'b0;
            instr_out <= 32'h0000_0013; // NOP
        end else if (!stall) begin
            pc_out    <= pc_in;
            instr_out <= instr_in;
        end
        // when stall=1 and no flush: hold values (do nothing)
    end
endmodule
