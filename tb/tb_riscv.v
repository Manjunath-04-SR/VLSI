// ============================================================
// Module : tb_riscv.v
// Purpose: Simulation Testbench for Low-Latency Pipelined
//          RISC-V 32-bit Processor
//
// Test coverage:
//   1. R-type:        ADD, SUB, AND, OR, XOR
//   2. I-type ALU:    ADDI
//   3. Store/Load:    SW, LW (load-use hazard + stall check)
//   4. Forwarding:    EX→EX (RAW after 1 cycle), MEM→EX (RAW after 2)
//   5. Branch:        BEQ taken, pipeline flush verification
//   6. Halt:          BEQ x0,x0,0  (self-loop)
//
// Expected register values at end of execution:
//   x1  = 10          (addi)
//   x2  = 20          (addi)
//   x3  = 30          (add)
//   x4  = -10 / 0xFFFFFFF6 (sub)
//   x5  = 0           (and: 10 & 20 = 0)
//   x6  = 30          (or)
//   x7  = 30          (xor: 10 ^ 20 = 30)
//   x8  = 30          (lw from addr 0, where sw stored x3=30)
//   x9  = 60          (add x9,x8,x3)
//   x10 = 0           (NEVER written; branch skipped addi x10,x0,99)
//   x11 = 77          (addi after branch lands here)
// ============================================================
`timescale 1ns / 1ps

module tb_riscv;

    // DUT signals
    reg  clk;
    reg  rst;

    // Instantiate DUT
    riscv_top DUT (
        .clk(clk),
        .rst(rst)
    );

    // ---- Clock generation: 10 ns period (100 MHz) ----
    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Task: read a register from the register file ----
    // DUT.RF.regs[] is directly accessible in simulation
    task read_reg;
        input [4:0] reg_num;
        output [31:0] val;
        begin
            if (reg_num == 0) val = 32'b0;
            else              val = DUT.RF.regs[reg_num];
        end
    endtask

    // ---- Task: read data memory word ----
    task read_dmem;
        input [9:0] byte_addr;
        output [31:0] val;
        begin
            val = {DUT.DMEM.mem[byte_addr+3],
                   DUT.DMEM.mem[byte_addr+2],
                   DUT.DMEM.mem[byte_addr+1],
                   DUT.DMEM.mem[byte_addr]};
        end
    endtask

    // ---- Monitoring: print pipeline state each cycle ----
    integer cycle_cnt;
    initial cycle_cnt = 0;
    always @(posedge clk) begin
        cycle_cnt = cycle_cnt + 1;
        $display("Cycle %0d | PC_IF=0x%08h | PC_ID=0x%08h | PC_EX=0x%08h | stall=%b | flush=%b",
                  cycle_cnt,
                  DUT.pc_if,
                  DUT.pc_id,
                  DUT.pc_ex,
                  DUT.stall,
                  DUT.flush_pipe);
    end

    // ---- Main stimulus ----
    integer i;
    reg [31:0] r_val;
    reg [31:0] dmem_val;

    initial begin
        // Waveform dump for Vivado simulation
        $dumpfile("riscv_sim.vcd");
        $dumpvars(0, tb_riscv);

        // ---- Reset ----
        rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;
        $display("\n=== RESET RELEASED — Simulation START ===\n");

        // ---- Run for 60 cycles (program finishes well within this) ----
        repeat(60) @(posedge clk);
        #1;

        // ====================================================
        // ---- Verification: check register file contents ----
        // ====================================================
        $display("\n========== REGISTER FILE CHECK ==========");
        read_reg(1,  r_val); $display("x1  = %0d  (expected 10)  %s", $signed(r_val), (r_val==32'd10)     ? "PASS":"FAIL");
        read_reg(2,  r_val); $display("x2  = %0d  (expected 20)  %s", $signed(r_val), (r_val==32'd20)     ? "PASS":"FAIL");
        read_reg(3,  r_val); $display("x3  = %0d  (expected 30)  %s", $signed(r_val), (r_val==32'd30)     ? "PASS":"FAIL");
        read_reg(4,  r_val); $display("x4  = %0d  (expected -10) %s", $signed(r_val), (r_val==32'hFFFFFFF6)?"PASS":"FAIL");
        read_reg(5,  r_val); $display("x5  = %0d  (expected 0)   %s", $signed(r_val), (r_val==32'd0)      ? "PASS":"FAIL");
        read_reg(6,  r_val); $display("x6  = %0d  (expected 30)  %s", $signed(r_val), (r_val==32'd30)     ? "PASS":"FAIL");
        read_reg(7,  r_val); $display("x7  = %0d  (expected 30)  %s", $signed(r_val), (r_val==32'd30)     ? "PASS":"FAIL");
        read_reg(8,  r_val); $display("x8  = %0d  (expected 30)  %s", $signed(r_val), (r_val==32'd30)     ? "PASS":"FAIL");
        read_reg(9,  r_val); $display("x9  = %0d  (expected 60)  %s", $signed(r_val), (r_val==32'd60)     ? "PASS":"FAIL");
        read_reg(10, r_val); $display("x10 = %0d  (expected 0)   %s", $signed(r_val), (r_val==32'd0)      ? "PASS":"FAIL");
        read_reg(11, r_val); $display("x11 = %0d  (expected 77)  %s", $signed(r_val), (r_val==32'd77)     ? "PASS":"FAIL");

        $display("\n========== DATA MEMORY CHECK ============");
        read_dmem(0, dmem_val);
        $display("dmem[0] = %0d  (expected 30)  %s", dmem_val, (dmem_val==32'd30) ? "PASS":"FAIL");

        $display("\n========== FORWARDING UNIT CHECK ========");
        $display("EX->EX forward test (x3=x1+x2): %s", (DUT.RF.regs[3]==32'd30)?"PASS":"FAIL");
        $display("MEM->EX forward test (x9=x8+x3): %s",(DUT.RF.regs[9]==32'd60)?"PASS":"FAIL");

        $display("\n========== BRANCH FLUSH CHECK ===========");
        $display("x10 should be 0 (addi x10,x0,99 was skipped): %s",
                 (DUT.RF.regs[10]==32'd0)?"PASS":"FAIL");

        $display("\n=== Simulation COMPLETE ===\n");
        $finish;
    end

    // ---- Timeout guard ----
    initial begin
        #2000;
        $display("TIMEOUT: simulation exceeded 2000 ns");
        $finish;
    end

endmodule
