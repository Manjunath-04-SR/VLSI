// ============================================================
// Module : instr_mem.v
// Purpose: Read-Only Instruction Memory (256 words = 1 KB)
//          Pre-loaded with a test program for simulation
// Project: Low-Latency Pipelined RISC-V 32-bit Processor
//
// Test Program (RV32I):
//   0x00:  addi x1,  x0, 10       ; x1 = 10
//   0x04:  addi x2,  x0, 20       ; x2 = 20
//   0x08:  add  x3,  x1, x2       ; x3 = 30  (EX→EX forward)
//   0x0C:  sub  x4,  x1, x2       ; x4 = -10 (EX→EX forward)
//   0x10:  and  x5,  x1, x2       ; x5 = 0
//   0x14:  or   x6,  x1, x2       ; x6 = 30
//   0x18:  xor  x7,  x1, x2       ; x7 = 30
//   0x1C:  sw   x3,  0(x0)        ; mem[0] = 30
//   0x20:  lw   x8,  0(x0)        ; x8 = 30  (load-use hazard follows)
//   0x24:  nop                    ; inserted after load
//   0x28:  add  x9,  x8, x3       ; x9 = 60  (MEM→EX forward)
//   0x2C:  beq  x3,  x3, +8       ; always taken → skip next 2
//   0x30:  addi x10, x0, 99       ; SKIPPED (branch flush test)
//   0x34:  addi x11, x0, 77       ; x11 = 77 (lands here after branch)
//   0x38:  beq  x0,  x0, 0        ; halt (infinite loop)
// ============================================================
module instr_mem (
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] mem [0:255];

    initial begin
        // ---- initialise unused locations to NOP ----
        integer i;
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h0000_0013; // NOP

        // ---- test program ----
        mem[0]  = 32'h00A00093;   // addi x1,  x0, 10
        mem[1]  = 32'h01400113;   // addi x2,  x0, 20
        mem[2]  = 32'h002081B3;   // add  x3,  x1, x2
        mem[3]  = 32'h40208233;   // sub  x4,  x1, x2
        mem[4]  = 32'h0020F2B3;   // and  x5,  x1, x2
        mem[5]  = 32'h0020E333;   // or   x6,  x1, x2
        mem[6]  = 32'h0020C3B3;   // xor  x7,  x1, x2
        mem[7]  = 32'h00302023;   // sw   x3,  0(x0)
        mem[8]  = 32'h00002403;   // lw   x8,  0(x0)
        mem[9]  = 32'h00000013;   // nop
        mem[10] = 32'h003404B3;   // add  x9,  x8, x3
        mem[11] = 32'h00318463;   // beq  x3,  x3, +8  (offset=8 → addr 0x34)
        mem[12] = 32'h06300513;   // addi x10, x0, 99  (SKIPPED)
        mem[13] = 32'h04D00593;   // addi x11, x0, 77
        mem[14] = 32'h00000063;   // beq  x0,  x0, 0   (halt)
    end

    // Word-aligned read (PC is byte-addressed, memory is word-indexed)
    assign instr = mem[addr[9:2]];
endmodule
