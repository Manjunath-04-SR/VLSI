// ============================================================
// Module : hazard_unit.v
// Purpose: Load-Use Hazard Detection Unit
//          Detects when an instruction immediately following a
//          LOAD needs the loaded value (1-cycle stall required).
//          When stall is asserted:
//            - PC and IF/ID register are held (stall=1 fed back)
//            - ID/EX register is flushed to NOP bubble
// Project: Low-Latency Pipelined RISC-V 32-bit Processor
//
// Condition: if (ID/EX.MemRead == 1) AND
//                (ID/EX.rd == IF/ID.rs1  OR
//                 ID/EX.rd == IF/ID.rs2) → stall
// ============================================================
module hazard_unit (
    input  wire        id_ex_memread,  // MemRead control bit in ID/EX
    input  wire [4:0]  id_ex_rd,       // destination register in ID/EX
    input  wire [4:0]  if_id_rs1,      // source reg 1 of instruction in ID
    input  wire [4:0]  if_id_rs2,      // source reg 2 of instruction in ID
    output wire        stall           // assert to freeze PC and IF/ID
);
    assign stall = id_ex_memread &&
                   ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)) &&
                   (id_ex_rd != 5'b0);
endmodule
