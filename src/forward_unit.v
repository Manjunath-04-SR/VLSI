// ============================================================
// Module : forward_unit.v
// Purpose: Data Forwarding Unit — resolves RAW hazards without stalls
//          by selecting the most recently computed value for ALU inputs
// Project: Low-Latency Pipelined RISC-V 32-bit Processor
//
// forward_a / forward_b encoding:
//   2'b00  → use register file output (no hazard)
//   2'b10  → forward from EX/MEM ALU result  (EX→EX forwarding)
//   2'b01  → forward from MEM/WB write data  (MEM→EX forwarding)
//
// Priority: EX/MEM takes priority over MEM/WB when both match.
// ============================================================
module forward_unit (
    // EX/MEM pipeline register info
    input  wire        ex_mem_regwrite,
    input  wire [4:0]  ex_mem_rd,
    // MEM/WB pipeline register info
    input  wire        mem_wb_regwrite,
    input  wire [4:0]  mem_wb_rd,
    // Current EX stage source registers
    input  wire [4:0]  id_ex_rs1,
    input  wire [4:0]  id_ex_rs2,
    // Forwarding select signals
    output reg  [1:0]  forward_a,
    output reg  [1:0]  forward_b
);
    // ---- Forward A (rs1) ----
    always @(*) begin
        if (ex_mem_regwrite && (ex_mem_rd != 5'b0) &&
            (ex_mem_rd == id_ex_rs1))
            forward_a = 2'b10;   // EX/MEM → EX (highest priority)
        else if (mem_wb_regwrite && (mem_wb_rd != 5'b0) &&
                 (mem_wb_rd == id_ex_rs1))
            forward_a = 2'b01;   // MEM/WB → EX
        else
            forward_a = 2'b00;   // register file
    end

    // ---- Forward B (rs2) ----
    always @(*) begin
        if (ex_mem_regwrite && (ex_mem_rd != 5'b0) &&
            (ex_mem_rd == id_ex_rs2))
            forward_b = 2'b10;   // EX/MEM → EX (highest priority)
        else if (mem_wb_regwrite && (mem_wb_rd != 5'b0) &&
                 (mem_wb_rd == id_ex_rs2))
            forward_b = 2'b01;   // MEM/WB → EX
        else
            forward_b = 2'b00;   // register file
    end
endmodule
