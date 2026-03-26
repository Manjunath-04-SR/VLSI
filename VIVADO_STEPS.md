# Vivado Simulation — Step-by-Step Guide
## Project: Low-Latency Pipelined RISC-V 32-bit Processor

---

## STEP 1 — Create a New Vivado Project

1. Open **Xilinx Vivado** (any version ≥ 2019.1)
2. Click **"Create Project"** → Next
3. **Project name**: `riscv_pipeline`
4. **Project location**: `C:\Users\2479309\Desktop\MP`
5. **Project type**: select **RTL Project** → check **"Do not specify sources at this time"** → Next
6. **Default Part**: choose any Artix-7 board, e.g.:
   - Board: `Artix-7` → Part: `xc7a35tcpg236-1` (for simulation only, part doesn't matter)
7. Click **Finish**

---

## STEP 2 — Add Source Files

1. In the **Sources** panel → click **"+"** (Add Sources)
2. Select **"Add or create design sources"** → Next
3. Click **"Add Files"** → navigate to `C:\Users\2479309\Desktop\MP\src\`
4. Select ALL `.v` files:
   - `pc_reg.v`
   - `instr_mem.v`
   - `if_id_reg.v`
   - `control_unit.v`
   - `regfile.v`
   - `imm_gen.v`
   - `hazard_unit.v`
   - `id_ex_reg.v`
   - `alu_ctrl.v`
   - `alu.v`
   - `forward_unit.v`
   - `ex_mem_reg.v`
   - `data_mem.v`
   - `mem_wb_reg.v`
   - `riscv_top.v`
5. Click **Finish**

---

## STEP 3 — Add Simulation Testbench

1. In the **Sources** panel → click **"+"**
2. Select **"Add or create simulation sources"** → Next
3. Click **"Add Files"** → navigate to `C:\Users\2479309\Desktop\MP\tb\`
4. Select `tb_riscv.v` → Finish
5. In the Sources panel, expand **"Simulation Sources"** and confirm `tb_riscv` appears
6. Right-click `tb_riscv` → **"Set as Top"** (for simulation)

---

## STEP 4 — Set the Design Top Module

1. In **Sources** panel under **"Design Sources"**
2. Right-click `riscv_top` → **"Set as Top"**
3. Vivado will show `riscv_top (riscv_top.v)` as the top module

---

## STEP 5 — Run Elaboration (Syntax Check)

1. In the **Flow Navigator** (left panel) → under **RTL Analysis** → click **"Open Elaborated Design"**
2. Vivado will elaborate all source files and check for syntax errors
3. If errors appear:
   - Check the **Tcl Console** at the bottom for error messages
   - Most common errors: missing semicolons, undefined module names, wrong port names
4. If elaboration succeeds → you will see the **Schematic** view
5. Review the block diagram to verify all pipeline stages are connected

---

## STEP 6 — Run Behavioral Simulation

1. In **Flow Navigator** → click **"Run Simulation"** → **"Run Behavioral Simulation"**
2. Vivado opens the **Simulation GUI**
3. In the **Tcl Console** at the bottom, you can also run:
   ```tcl
   launch_simulation
   run 600ns
   ```

---

## STEP 7 — Add Signals to Waveform Window

After simulation opens:

### Add Top-Level Signals:
1. In the **Scope** panel (left) → expand `tb_riscv` → click `DUT` (riscv_top)
2. In **Objects** panel (right) → right-click signals → **"Add to Wave Window"**
3. Add these key signals:
   - `clk`, `rst`
   - `pc_if` — current Program Counter
   - `instr_if` — fetched instruction
   - `stall` — load-use stall
   - `flush_pipe` — branch/jump flush
   - `branch_taken`, `jump_taken`
   - `forward_a`, `forward_b` — forwarding select

### Add Pipeline Register Signals:
Navigate into each sub-module and add:
- **IF/ID**: `pc_out`, `instr_out`
- **ID/EX**: `pc_out`, `rdata1_out`, `rdata2_out`, `rd_out`, `regwrite_out`
- **EX stage**: `alu_op_a`, `alu_op_b`, `alu_result_ex`, `rdata1_fwd`, `rdata2_fwd`
- **EX/MEM**: `alu_result_out`, `rd_out`, `regwrite_out`
- **MEM/WB**: `alu_result_out`, `mem_rdata_out`, `rd_out`, `regwrite_out`

### Add Register File Contents:
1. Expand `DUT` → `RF`
2. Add `regs` array to waveform → set radix to **Decimal** or **Hex**

---

## STEP 8 — Run and Analyze Waveform

1. Click **"Restart"** button (or type `restart` in Tcl console)
2. Click **"Run All"** (or press **F3**) — simulation runs until `$finish`
3. In the Tcl Console, you will see the PASS/FAIL report printed by the testbench

### Expected Tcl Console Output:
```
=== RESET RELEASED — Simulation START ===

Cycle 1 | PC_IF=0x00000000 | ...
...

========== REGISTER FILE CHECK ==========
x1  = 10   (expected 10)  PASS
x2  = 20   (expected 20)  PASS
x3  = 30   (expected 30)  PASS
x4  = -10  (expected -10) PASS
x5  = 0    (expected 0)   PASS
x6  = 30   (expected 30)  PASS
x7  = 30   (expected 30)  PASS
x8  = 30   (expected 30)  PASS
x9  = 60   (expected 60)  PASS
x10 = 0    (expected 0)   PASS  ← branch flush verified
x11 = 77   (expected 77)  PASS

========== DATA MEMORY CHECK ============
dmem[0] = 30  (expected 30)  PASS

========== FORWARDING UNIT CHECK ========
EX->EX forward test (x3=x1+x2): PASS
MEM->EX forward test (x9=x8+x3): PASS

========== BRANCH FLUSH CHECK ===========
x10 should be 0 (addi x10,x0,99 was skipped): PASS

=== Simulation COMPLETE ===
```

---

## STEP 9 — Waveform Analysis (What to Look For)

### 9.1 Normal Pipeline Flow (no hazard)
- Every cycle: PC advances by 4
- Instructions flow through IF→ID→EX→MEM→WB
- One new instruction retires every cycle (steady state)

### 9.2 Load-Use Stall (after LW instruction)
- After `lw x8, 0(x0)`: the `stall` signal goes HIGH for 1 cycle
- PC_IF holds its value (same PC for 2 cycles)
- IF/ID register holds (same instruction for 2 cycles)
- ID/EX register gets flushed to NOP (bubble inserted)

### 9.3 EX→EX Forwarding
- `add x3, x1, x2` executes 1 cycle after `addi x1,x0,10` and `addi x2,x0,20`
- `forward_a = 2'b10` or `forward_b = 2'b10` asserts
- `rdata1_fwd` and `rdata2_fwd` show the forwarded values (10 and 20)

### 9.4 Branch Flush
- At `beq x3, x3, +8`: `branch_taken = 1`, `flush_pipe = 1`
- Next cycle: IF/ID shows NOP, ID/EX shows NOP (2-stage flush)
- PC jumps to 0x34 (skipping 0x30, the addi x10,x0,99 instruction)
- x10 remains 0 — confirms flush worked correctly

---

## STEP 10 — Take Screenshots for Report

Save screenshots of:
1. **Full waveform** (all 60 cycles)
2. **Zoomed: load-use stall** (cycles around LW instruction)
3. **Zoomed: forwarding** (cycles where forward_a/b ≠ 00)
4. **Zoomed: branch flush** (cycle where branch_taken=1)
5. **Tcl console** showing all PASS results
6. **Schematic** from elaboration (shows all 15 modules connected)

---

## STEP 11 — Save the Simulation State

1. In waveform window → **File → Save Waveform Configuration** → save as `riscv_sim.wcfg`
2. This lets you reload the same waveform view later

---

## COMMON ERRORS AND FIXES

| Error | Fix |
|-------|-----|
| `Module not found` | Ensure all 15 .v files are added as Design Sources |
| `Multiple drivers` | Check that signals are driven from only one place |
| `X/Z values in simulation` | Check reset is applied for at least 2 cycles |
| `Simulation hangs` | The halt loop (beq x0,x0,0) is working — press Stop |
| Waveforms all red | Check clk and rst connections in testbench |

---

## File Summary

```
C:\Users\2479309\Desktop\MP\
├── src\                          ← Design Sources (add all to Vivado)
│   ├── riscv_top.v               ← TOP MODULE (5-stage integration)
│   ├── pc_reg.v                  ← Stage 1: Program Counter
│   ├── instr_mem.v               ← Stage 1: Instruction Memory (ROM)
│   ├── if_id_reg.v               ← Pipeline Register: IF/ID
│   ├── control_unit.v            ← Stage 2: Main Decoder
│   ├── regfile.v                 ← Stage 2: 32×32 Register File
│   ├── imm_gen.v                 ← Stage 2: Immediate Generator
│   ├── hazard_unit.v             ← Hazard Detection (load-use stall)
│   ├── id_ex_reg.v               ← Pipeline Register: ID/EX
│   ├── alu_ctrl.v                ← Stage 3: ALU Control
│   ├── alu.v                     ← Stage 3: 32-bit ALU
│   ├── forward_unit.v            ← Stage 3: Data Forwarding Unit
│   ├── ex_mem_reg.v              ← Pipeline Register: EX/MEM
│   ├── data_mem.v                ← Stage 4: Data Memory
│   └── mem_wb_reg.v              ← Pipeline Register: MEM/WB
│
└── tb\
    └── tb_riscv.v                ← Simulation Testbench
```
