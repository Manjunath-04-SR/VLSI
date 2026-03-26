// ============================================================
// Module : pc_reg.v
// Purpose: Program Counter with stall support
// Project: Low-Latency Pipelined RISC-V 32-bit Processor
// ============================================================
module pc_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,       // hold PC when load-use stall
    input  wire [31:0] pc_next,
    output reg  [31:0] pc
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'h0000_0000;
        else if (!stall)
            pc <= pc_next;
    end
endmodule
